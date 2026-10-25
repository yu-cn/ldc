#!/usr/bin/env bash
# shellcheck disable=SC2088  # 标签文案中的 ~/ 是显示约定不参与展开；真实路径展开一律用 $HOME
# verify-machine.sh — 机器状态断言（只读，不改变任何状态）；任一 FAIL → exit 1
# 五组断言（对齐 WDC verify-machine.ps1 风格）：
#   ① dotfiles 落点与模板一致（ADR-0015 内容断言，断效果不断实现；落点映射见 common.sh dotfiles_map）+ hooksPath
#   ② gitidentity 存在且非占位（未填 = FAIL 是设计内护栏；LDC_SMOKE=1 容器冒烟降为存在性检查）
#   ③ 包清单核销（dpkg -s 逐项；即 root 阶段完成度）
#   ④ 语言栈与工具钉子（uv 在位、vp/starship/lazygit = 钉子、node 可用、env.sh 事实文件在位）
#   ⑤ 桌面域（gsettings 读值比对；无会话 SKIP）
# 用法：bash scripts/verify-machine.sh [--quick]   --quick 跳过 gsettings 读值比对（秒级）
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"

QUICK=0
[ "${1:-}" = "--quick" ] && QUICK=1
FAILS=0

assert_that() {
    # assert_that <名称> <失败提示> <检测命令串（eval 执行；$ROOT/$HOME 等在求值时展开）>
    local name=$1 hint=$2
    shift 2
    if eval "$*" >/dev/null 2>&1; then
        step "$name" OK
    else
        step "$name" FAIL "$hint"
        FAILS=$((FAILS + 1))
    fi
}

# assert_pin <名称> <钉子文件> <二进制>——断言与 install-user-tools 的收敛语义同宽：漂移→重跑 bootstrap 即收敛
assert_pin() {
    local name=$1 pinfile=$2 bin=$3 pin
    pin="$(pin_of "$pinfile")" || exit 1
    if [ -x "$bin" ] && version_matches "$("$bin" --version 2>/dev/null)" "$pin"; then
        step "$name = 钉子（$pin）" OK
    else
        step "$name = 钉子（$pin）" FAIL '重跑 bootstrap（user 工具阶段）'
        FAILS=$((FAILS + 1))
    fi
}

phase '1/5 · dotfiles 落点与接线（ADR-0015 内容断言）'
assert_dotfiles() {
    # assert_dotfiles <显示名> <模板绝对路径> <落点绝对路径> <mode>——落点状态经 dotfiles_entry_state 判定
    local name=$1 src=$2 dst=$3 mode=$4 state
    state=$(dotfiles_entry_state "$src" "$dst" "$mode")
    if [ "$state" = ok ]; then
        step "$name" OK
    else
        step "$name" FAIL '落点与模板不一致——机器侧改动先 ldc triage 分流，再重跑 bash bootstrap.sh（dotfiles 阶段）'
        FAILS=$((FAILS + 1))
    fi
}
while IFS='|' read -r name tmpl target _gate mode; do
    assert_dotfiles "$name" "$ROOT/$tmpl" "$HOME/$target" "$mode"
done < <(dotfiles_map_entries)
assert_that 'pre-commit 钩子已接线' 'git config core.hooksPath .githooks（或重跑 bootstrap）' \
    '[ "$(git -C "$ROOT" config core.hooksPath)" = ".githooks" ]'

phase '2/5 · 身份断言'
if [ "${LDC_SMOKE:-0}" = "1" ]; then
    assert_that '~/.gitidentity 存在（SMOKE 降级）' '重跑 bootstrap 生成占位' \
        '[ -e "$HOME/.gitidentity" ]'
else
    assert_that 'git 身份经 include 生效（非占位）' '编辑 ~/.gitidentity 填本机 name/email（未填 = FAIL 是设计内护栏）' \
        '[ -n "$(git config --global --includes --get user.name)" ] && [ -n "$(git config --global --includes --get user.email)" ]'
fi

phase '3/5 · 包清单核销（root 阶段完成度）'
while read -r pkg; do
    assert_that "apt: $pkg" "root 阶段待交接：$(root_handoff_cmd)" \
        "dpkg -s $pkg"
done < <(pkg_list base-linux.pkg && pkg_list cli-tools.pkg)
assert_that 'gh 在位' 'root 阶段安装（官方 apt 源）' 'command -v gh'
if [ "${LDC_SKIP_DOCKER:-0}" = "1" ]; then
    step 'docker 在位' SKIP 'LDC_SKIP_DOCKER=1'
else
    assert_that 'docker 在位' 'root 阶段安装（get.docker.com）' 'command -v docker'
    assert_that 'docker daemon 声明键在位（日志轮转 + live-restore）' \
        'root 阶段受保护合并：sudo bash scripts/install-packages.sh' \
        'have docker && docker_daemon_declared_ok'
fi
if ! desktop_stack_present; then
    step '桌面应用域' SKIP '非桌面机器形态（headless/WSL/容器）——ADR-0008'
else
    while read -r pkg; do
        assert_that "apt(桌面应用): $pkg" "root 阶段待交接：$(root_handoff_cmd)" "dpkg -s $pkg"
    done < <(pkg_list desktop-apps.pkg)
fi

phase '4/5 · 语言栈与架构'
assert_that '架构受支持（amd64/arm64）' 'LDC 仅支持 amd64/arm64（ADR-0006）' 'ldc_arch >/dev/null'
assert_that 'uv 就位' '重跑 bootstrap（user 工具阶段）' '[ -x "$HOME/.local/bin/uv" ] || command -v uv'
assert_pin vp vp-version "$(vp_bin_path || true)"
assert_pin starship starship-version "$HOME/.local/bin/starship"
assert_pin lazygit lazygit-version "$HOME/.local/bin/lazygit"
assert_that 'node 可用' 'node 由 vp 或机器自留地（如 nvm）提供——重跑 bootstrap' 'node_available'
assert_that '~/.config/ldc/env.sh 在位（工具布局事实，ADR-0015）' '重跑 bash bootstrap.sh（user 工具阶段）' \
    '[ -f "$HOME/.config/ldc/env.sh" ]'

phase '5/5 · 桌面域'
if ! desktop_stack_present; then
    step '桌面域' SKIP '非桌面机器形态（headless/WSL/容器）——ADR-0005'
else
    assert_that 'JetBrainsMono NF 字体目录' '重跑 bootstrap（user 工具阶段）' \
        '[ -n "$(ls -A "$HOME/.local/share/fonts/JetBrainsMono-NF" 2>/dev/null)" ]'
    # VSCode 配置落点已由 phase 1 的 dotfiles_map 内容断言覆盖（ADR-0015）；这里只管扩展
    # （自装扩展不在清单不核销——ADR-0003）
    if have code; then
        assert_that 'VSCode 扩展清单在位' '重跑 bootstrap（user 工具阶段）' \
            '[ -z "$(comm -23 <(pkg_list vscode-extensions.txt | sort) <(code --list-extensions 2>/dev/null | sort))" ]'
    else
        step 'VSCode 扩展清单' FAIL 'code 未装（root 阶段待交接）'
        FAILS=$((FAILS + 1))
    fi
    if ! desktop_session_reachable; then
        step 'gsettings 读值比对' SKIP '无图形会话——登录 GNOME 桌面后重跑 bootstrap'
    elif [ "$QUICK" -eq 1 ]; then
        step 'gsettings 读值比对' SKIP '--quick 跳过（会话在位）'
    else
        # schema 存在性降级与 apply-desktop 同口径：发行版无此组件（如 Debian 无 Ubuntu Dock）SKIP
        verify_schemas=$({ gsettings list-schemas; gsettings list-relocatable-schemas; } | sort -u)
        while read -r schema key value; do
            if ! grep -qx "$schema" <<<"$verify_schemas"; then
                step "gsettings: $schema $key" SKIP '此发行版无此 schema（组件未装）'
                continue
            fi
            assert_that "gsettings: $schema $key = $value" '' \
                "[ \"\$(gsettings get $schema $key)\" = \"$value\" ]"
        done < <(grep -vE '^[[:space:]]*(#|$)' "$ROOT/configs/desktop.gsettings")
    fi
fi

phase '汇总'
if [ "$FAILS" -eq 0 ]; then
    step '机器断言' OK '全部通过——与声明一致'
    exit 0
fi
step '机器断言' FAIL "$FAILS 项未通过"
exit 1
