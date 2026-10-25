#!/usr/bin/env bash
# shellcheck disable=SC2088  # 标签文案中的 ~/ 是显示约定不参与展开；真实路径展开一律用 $HOME
# plan-machine.sh — 干跑预演（只读，零变更）：按 bootstrap 的安装面与声明逐项比对，
#   投影「重跑收敛会做什么」。与 verify-machine.sh 互补：verify 断言「现在对不对」，
#   plan 投影「跑一遍会发生什么」——sudo 前先看一眼再决定跑不跑。
# 状态口径：OK=已就位（重跑将跳过）· PLAN=将变更 · SKIP=不适用 · INFO=需机主手工（bootstrap 不代劳）
# 退出码：0 = 预演完成（有无待办都算成功——这是投影不是断言）；1 = 预检失败（bootstrap 将在此中止）
# 用法：bash scripts/plan-machine.sh   （ldc plan 同义）
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"

ok_count=0 plan_count=0 skip_count=0
pstep() {
    # pstep <标签> <状态> [详情] —— step 透传 + 计数（FAIL 不计：投影中的异常项单独可见）
    step "$@"
    case $2 in
        OK)   ok_count=$((ok_count + 1)) ;;
        PLAN) plan_count=$((plan_count + 1)) ;;
        SKIP) skip_count=$((skip_count + 1)) ;;
    esac
}

render_plan() {
    # render_plan <显示名> <模板绝对路径> <落点绝对路径> <mode> —— install-dotfiles render()/link() 的只读投影
    local name=$1 src=$2 dst=$3 mode=$4 state
    state=$(dotfiles_entry_state "$src" "$dst" "$mode")
    case $state in
        ok)     pstep "$name" OK '已与模板一致' ;;
        absent) pstep "$name" PLAN '将渲染 ← 模板' ;;
        drift)
            if [ "$mode" = render ] && [ -L "$dst" ]; then
                pstep "$name" PLAN "将迁移：符号链接（→ $(readlink "$dst" 2>/dev/null || echo '死链')）改渲染拷贝（ADR-0015）"
            elif [ "$mode" = render ]; then
                pstep "$name" PLAN '将重渲染（当前落点内容先备份 .bak.N；机器侧改动可先 ldc triage 吸收进模板）'
            else
                pstep "$name" PLAN '将重指符号链接 → 仓库 CLI'
            fi ;;
    esac
}

phase '1/6 · 预检'
if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    case "${ID:-}" in
        ubuntu|debian) pstep '操作系统' OK "${PRETTY_NAME:-${ID:-}}（$(uname -m)）" ;;
        *) pstep '操作系统' FAIL "仅支持 ubuntu/debian，当前 ID=${ID:-未知}——bootstrap 将在此中止"; exit 1 ;;
    esac
else
    pstep '操作系统' FAIL '缺 /etc/os-release——bootstrap 将在此中止'; exit 1
fi
if arch_asset=$(ldc_arch); then
    pstep '架构' OK "$(uname -m) → ${arch_asset} 资产"
else
    pstep '架构' FAIL '受支持架构仅 amd64/arm64（ADR-0006）——bootstrap 将在此中止'; exit 1
fi

phase '2/6 · root · apt 包清单与 gh'
while read -r pkg; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        pstep "apt: $pkg" OK '已就位'
    else
        pstep "apt: $pkg" PLAN '将安装'
    fi
done < <(pkg_list base-linux.pkg && pkg_list cli-tools.pkg)
# fd/bat 兼容链接（install-packages.sh 同款判据：目标已可直呼或源命令缺失则无事可做）
for pair in fdfind:fd batcat:bat; do
    src=${pair%%:*} name=${pair##*:}
    if have "$name" || ! have "$src"; then
        pstep "兼容链接 $name" SKIP '已可直呼/无需兼容'
    else
        pstep "兼容链接 $name" PLAN "$src → /usr/local/bin/$name"
    fi
done
if have gh; then
    pstep gh OK '已就位'
else
    pstep gh PLAN '将配置官方 apt 源并安装'
fi
# 可选包组提示（ADR-0010：不在通用循环，投影为信息项而非 PLAN）
opt=''
for m in "$ROOT"/configs/*.pkg; do
    b=${m##*/}
    case $b in base-linux.pkg|cli-tools.pkg|desktop-apps.pkg) continue ;; esac
    opt+="${b%.pkg} "
done
[ -n "$opt" ] && pstep '可选包组' INFO "可用（显式指名安装）：${opt% }——sudo bash scripts/install-packages.sh <名>（ADR-0010）"

phase '3/6 · root · 桌面应用域与 Docker'
if ! desktop_stack_present; then
    pstep 'desktop-apps' SKIP '非桌面机器形态（headless/WSL/容器）'
else
    while read -r pkg; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            pstep "apt(桌面应用): $pkg" OK '已就位'
        else
            pstep "apt(桌面应用): $pkg" PLAN '将安装'
        fi
    done < <(pkg_list desktop-apps.pkg)
fi
if [ "${LDC_SKIP_DOCKER:-0}" = "1" ]; then
    pstep docker SKIP 'LDC_SKIP_DOCKER=1'
elif have docker; then
    pstep docker OK '已就位'
    target_user=${SUDO_USER:-$(id -un)}
    if getent group docker 2>/dev/null | grep -qw "$target_user"; then
        pstep 'docker 组' SKIP "$target_user 已在组"
    else
        pstep 'docker 组' PLAN "$target_user 将入组（重新登录生效）"
    fi
    if [ ! -f /etc/docker/daemon.json ]; then
        pstep 'daemon.json' PLAN '将按声明创建（日志轮转 + live-restore）'
    elif docker_daemon_declared_ok; then
        pstep 'daemon.json' OK '声明键全部在位'
    else
        pstep 'daemon.json' PLAN '将受保护合并声明键（机器自有键保留，原件备份 .bak；绝不自动重启 docker）'
    fi
else
    pstep docker PLAN '将经 get.docker.com 官方脚本安装'
    pstep 'docker 组' PLAN '将把调用用户加入 docker 组（重新登录生效）'
fi

phase '4/6 · user 工具（uv / vp / starship / lazygit / 字体 / 扩展）'
uv_bin="$HOME/.local/bin/uv"
if [ -x "$uv_bin" ]; then
    pstep uv OK "已装（$("$uv_bin" --version 2>/dev/null | head -n1)）"
else
    pstep uv PLAN '将官方安装器安装'
fi
VP_VERSION="$(pin_of vp-version)" || exit 1
vp_bin="$(vp_bin_path || true)"
if [ -z "$vp_bin" ]; then
    pstep vp PLAN "将安装钉子 $VP_VERSION（官方安装器）"
elif version_matches "$("$vp_bin" --version 2>/dev/null)" "$VP_VERSION"; then
    pstep vp OK "= 钉子 $VP_VERSION"
else
    pstep vp PLAN "将收敛到钉子 $VP_VERSION"
fi
if node_available; then
    pstep node OK '可用'
else
    pstep node PLAN '将经 vp env 安装 LTS'
fi
SS_VERSION="$(pin_of starship-version)" || exit 1
ss_bin="$HOME/.local/bin/starship"
if [ -x "$ss_bin" ] && version_matches "$("$ss_bin" --version 2>/dev/null || true)" "$SS_VERSION"; then
    pstep starship OK "= 钉子 $SS_VERSION"
else
    pstep starship PLAN "将安装/升级到钉子 $SS_VERSION"
fi
LG_VERSION="$(pin_of lazygit-version)" || exit 1
lg_bin="$HOME/.local/bin/lazygit"
if [ -x "$lg_bin" ] && version_matches "$("$lg_bin" --version 2>/dev/null || true)" "$LG_VERSION"; then
    pstep lazygit OK "= 钉子 $LG_VERSION"
else
    pstep lazygit PLAN "将安装/升级到钉子 $LG_VERSION"
fi
if ! desktop_stack_present; then
    pstep '字体' SKIP '非桌面机器形态（headless/WSL/容器）'
else
    NF_VERSION="$(pin_of nerd-fonts-version)" || exit 1
    fontdir="$HOME/.local/share/fonts/JetBrainsMono-NF"
    if [ -d "$fontdir" ] && [ -f "$fontdir/.ldc-version" ] \
       && [ "$(cat "$fontdir/.ldc-version" 2>/dev/null)" = "$NF_VERSION" ]; then
        pstep '字体' OK "= 钉子 $NF_VERSION"
    else
        pstep '字体' PLAN "将安装 v$NF_VERSION"
    fi
fi
if ! desktop_stack_present; then
    pstep 'VSCode 扩展' SKIP '非桌面机器形态（headless/WSL/容器）'
elif ! have code; then
    pstep 'VSCode 扩展' INFO 'code 未装——root 阶段交接完成后重跑 bootstrap'
else
    ext_missing=$(comm -23 <(pkg_list vscode-extensions.txt | sort) <(code --list-extensions 2>/dev/null | sort))
    if [ -z "$ext_missing" ]; then
        pstep 'VSCode 扩展' OK '清单全部就位'
    else
        pstep 'VSCode 扩展' PLAN "将安装 $(printf '%s\n' "$ext_missing" | wc -l) 个：$(printf '%s ' $ext_missing)"
    fi
fi

phase '5/6 · dotfiles 与身份'
while IFS='|' read -r name tmpl target _gate mode; do
    render_plan "$name" "$ROOT/$tmpl" "$HOME/$target" "$mode"
done < <(dotfiles_map_entries)
desktop_stack_present || pstep 'VSCode 配置渲染' SKIP '非桌面机器形态（ADR-0008）'
if [ -e "$HOME/.bashrc.local" ]; then
    pstep '.bashrc.local' OK '自留地在位（机主维护）'
else
    pstep '.bashrc.local' PLAN '将创建空自留地（首次接管时自动迁移标记块/nvm 块）'
fi
if [ -e "$HOME/.gitconfig.local" ]; then
    pstep '.gitconfig.local' OK '自留地在位（机主维护）'
else
    pstep '.gitconfig.local' PLAN '将创建空自留地'
fi
if [ ! -e "$HOME/.gitidentity" ]; then
    pstep '.gitidentity' PLAN '将生成占位——生成后需手填 name/email（未填则 git 拒绝提交）'
elif git_identity_ok; then
    pstep '.gitidentity' OK '身份已生效'
else
    pstep '.gitidentity' INFO '占位未填——需手填（bootstrap 不代填；未填则 git 拒绝提交）'
fi
if [ "$(head -n1 "$HOME/.ldc" 2>/dev/null)" = "$ROOT" ]; then
    pstep '~/.ldc 指针' OK "$ROOT"
else
    pstep '~/.ldc 指针' PLAN "将写入 $ROOT"
fi
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    if [ "$(git -C "$ROOT" config core.hooksPath)" = ".githooks" ]; then
        pstep 'hooksPath' SKIP '已接线 .githooks'
    else
        pstep 'hooksPath' PLAN '将接线 .githooks'
    fi
else
    pstep 'hooksPath' INFO '尚未 git init——init 后重跑 bootstrap 自动接线'
fi

phase '6/6 · 桌面域（gsettings）'
if ! desktop_stack_present; then
    pstep '桌面域' SKIP '非桌面机器形态（headless/WSL/容器）——ADR-0005'
elif ! desktop_session_reachable; then
    pstep '桌面域' SKIP '无图形会话——登录 GNOME 桌面后重跑 bootstrap 应用'
else
    all_schemas=$({ gsettings list-schemas; gsettings list-relocatable-schemas; } | sort -u)
    while read -r schema key value; do
        [ -z "${schema:-}" ] && continue
        if ! grep -qx "$schema" <<<"$all_schemas"; then
            pstep "$schema $key" SKIP '此发行版无此 schema（组件未装）'
            continue
        fi
        current=$(gsettings get "$schema" "$key" 2>/dev/null) \
            || { pstep "$schema $key" FAIL '读取失败'; continue; }
        if [ "$current" = "$value" ]; then
            pstep "$schema $key" OK '一致'
        else
            pstep "$schema $key" PLAN "将设置：$current → $value"
        fi
    done < <(grep -vE '^[[:space:]]*(#|$)' "$ROOT/configs/desktop.gsettings")
fi

phase 'plan · 汇总'
pstep '预演' OK "完成——已就位 $ok_count · 将变更 $plan_count · 跳过 $skip_count（本次未做任何变更；重跑 bash bootstrap.sh 或 ldc sync 应用）"
exit 0
