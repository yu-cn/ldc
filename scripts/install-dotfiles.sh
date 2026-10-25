#!/usr/bin/env bash
# shellcheck disable=SC2088  # 标签文案中的 ~/ 是显示约定不参与展开；真实路径展开一律用 $HOME
# install-dotfiles.sh — dotfiles 层：模板渲染拷贝（ADR-0015）+ .bak 轮转备份 + .bashrc.local 机器自留地迁移
#   + gitidentity 占位 + ~/.ldc 指针 + pre-commit 钩子接线
# 渲染模型（ADR-0015）：落点 = 模板渲染拷贝，机器与仓库的运行时耦合归零（仓库缺席只影响 ldc CLI）。
#   落点与模板同内容 → 幂等跳过；不同 → 覆盖前备份 .bak（已存在则 .bak.N 递增，绝不静默丢弃机器侧内容）；
#   符号链接残形（v0.5 旧安装形态 / 外来链接）直接替换不备份——链接本体可再造，指向内容不受影响。
#   例外：~/.local/bin/ldc 保持符号链接（CLI 入口跟随仓库）。
# .bashrc.local 机制（ADR-0003 核心）：首次接管 ~/.bashrc 时——整文件备份 .bashrc.bak；
#   抽取全部标记块（# >>> ... >>> .. # <<< ... <<<）与 nvm 块（export NVM_DIR= 起三行）迁入
#   .bashrc.local（已存在则不覆盖只提示）；其余差异留在 .bak 由机主自行搬运。
#   模板 bashrc 最末尾 source .bashrc.local → 机器段后加载、别名可覆盖模板。
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"
fail=0

link() {
    # link <仓库源文件> <落点>：已是正确符号链接 → 幂等跳过；旧实体文件 → 备份 .bak 后链接（仅 CLI 入口用）
    local src=$1 dst=$2 name
    name=$(basename "$dst")
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        step "$name 链接" SKIP '已就位'
        return 0
    fi
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        if [ ! -e "$dst.bak" ]; then
            mv "$dst" "$dst.bak"
            step "$name" CHANGED "旧文件已备份为 $name.bak"
        else
            rm -f "$dst"
            step "$name" CHANGED "旧文件移除（$name.bak 已存在，保最早原件）"
        fi
    fi
    if ln -sfn "$src" "$dst"; then
        step "$name 链接" OK "→ $src"
    else
        step "$name 链接" FAIL
        fail=$((fail + 1))
    fi
}

render() {
    # render <仓库模板> <落点> <显示名>（ADR-0015 渲染拷贝）：同内容幂等跳过；
    # 不同内容先轮转备份 .bak/.bak.N 再渲染；符号链接残形直接替换（见文件头注释）
    local src=$1 dst=$2 name=$3 bak n
    if [ ! -f "$src" ]; then
        step "$name" FAIL "模板缺失：${src#"$ROOT"/}"
        fail=$((fail + 1))
        return 0
    fi
    mkdir -p "$(dirname "$dst")"
    if [ ! -L "$dst" ] && [ -f "$dst" ] && cmp -s "$dst" "$src"; then
        step "$name" SKIP '已与模板一致'
        return 0
    fi
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        bak="$dst.bak"; n=1
        while [ -e "$bak" ]; do bak="$dst.bak.$n"; n=$((n + 1)); done
        if cp -p "$dst" "$bak"; then
            step "$name" CHANGED "落点与模板不一致——旧内容已备份 $(basename "$bak")（可 ldc triage 吸收）"
        else
            step "$name" FAIL "备份失败（$bak）——放弃渲染以防丢失机器侧内容"
            fail=$((fail + 1))
            return 0
        fi
    elif [ -L "$dst" ]; then
        old_target=$(readlink "$dst")
        rm -f "$dst"
        step "$name" CHANGED "符号链接已替换为渲染拷贝（原指向 ${old_target:-死链}，ADR-0015 迁移）"
    fi
    if install -m 0644 "$src" "$dst"; then
        step "$name" OK "已渲染 ← ${src#"$ROOT"/}"
    else
        step "$name" FAIL "渲染失败 ← ${src#"$ROOT"/}"
        fail=$((fail + 1))
    fi
}

phase 'dotfiles · .bashrc.local 迁移（仅首次接管时——自留地存在即视为已完成）'
# ADR-0015：渲染拷贝后 ~/.bashrc 是实体文件，旧判据「非符号链接」会把自家渲染物误当原始文件
# 重跑迁移（CI 冒烟实录：容器第二遍 CHANGED）。首接管的真正标记是自留地不存在——
# 兜底块保证任何一跑后 .bashrc.local 必在，故「自留地缺失」⟺ 从未接管过。
if [ -e "$HOME/.bashrc.local" ]; then
    step '.bashrc.local' SKIP '已存在——迁移已完成（机主维护，ADR-0003）'
elif [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ]; then
    # 整文件备份（保最早原件：已存在 .bak 则不动）
    if [ ! -e "$HOME/.bashrc.bak" ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
        step '.bashrc.bak' CHANGED '原 bashrc 整文件已备份（未迁移的差异请自行搬运）'
    else
        step '.bashrc.bak' SKIP '已存在（保最早原件）'
    fi
    # 标记块/nvm 块抽取走 common.sh 的 bashrc_local_extract（validate 自测共用）
    extracted=$(bashrc_local_extract "$HOME/.bashrc")
    {
        echo '# ~/.bashrc.local — 机器自留地（ADR-0003）：LDC 不管理、不入仓库'
        echo '# 由 bootstrap 首次接管 ~/.bashrc 时自动迁移（标记块 + nvm 块）；此后由机主自行维护。'
        echo '# 本文件在模板 bashrc 最末尾加载——别名/环境可覆盖模板。'
        [ -n "$extracted" ] && printf '\n%s\n' "$extracted"
    } > "$HOME/.bashrc.local"
    if [ -n "$extracted" ]; then
        step '.bashrc.local' CHANGED '已从原 bashrc 迁移标记块/nvm 块'
    else
        step '.bashrc.local' CHANGED '已创建（原 bashrc 无标记块/nvm 块，空自留地）'
    fi
elif [ -L "$HOME/.bashrc" ]; then
    step '.bashrc.local' SKIP 'bashrc 已是符号链接（外来管理器——WDC WSL 委托迁移场景，见 ADR-0007）'
fi
# 兜底：任何路径都保证 .bashrc.local 存在——模板末尾会 source 它；外来符号链接接管时
# 原管理器（如 WDC）没建过自留地，新机器也可能根本没有 ~/.bashrc
if [ ! -e "$HOME/.bashrc.local" ]; then
    {
        echo '# ~/.bashrc.local — 机器自留地（ADR-0003）：LDC 不管理、不入仓库'
        echo '# 本机私有别名/环境放这里，在模板 bashrc 最末尾加载、可覆盖模板。'
    } > "$HOME/.bashrc.local"
    step '.bashrc.local' CHANGED '已创建（空自留地）'
fi

phase 'dotfiles · 落点渲染（映射单一来源 dotfiles_map，ADR-0015）'
while IFS='|' read -r name tmpl target _gate mode; do
    case $mode in
        render) render "$ROOT/$tmpl" "$HOME/$target" "$name" ;;
        link)   link "$ROOT/$tmpl" "$HOME/$target" ;;
    esac
done < <(dotfiles_map_entries)
desktop_stack_present || step 'VSCode 配置渲染' SKIP '非桌面机器形态（ADR-0008）'

phase 'dotfiles · 机器数据文件（gitidentity 占位 / gitconfig.local）'
if [ ! -e "$HOME/.gitidentity" ]; then
    cat > "$HOME/.gitidentity" <<'EOF'
# ~/.gitidentity — 本机 git 身份（机器数据，不入仓库；ADR-0003）
# 填法：去掉下两行行首的注释并填入本机的 name/email。
# 未填写时 git 拒绝提交——这是防错护栏：身份因机而异，仓库永不代填。
[user]
#    name = 你的名字
#    email = you@example.com
EOF
    step '.gitidentity' CHANGED '占位已生成——填入本机 name/email 后 git 才能提交'
else
    step '.gitidentity' SKIP '已存在'
fi
# gitconfig 自留地（ADR-0003，与 .bashrc.local 同构）：gh auth setup-git 等机器工具直改落点渲染物的
# 机器段迁来这里；模板经 [include] 引用，文件缺失时 git 静默忽略
if [ ! -e "$HOME/.gitconfig.local" ]; then
    {
        echo '# ~/.gitconfig.local — 机器自留地（ADR-0003，与 .bashrc.local 同构）：LDC 不管理、不入仓库'
        echo '# gh auth setup-git 直改落点的凭据段迁到这里；此后由机主维护（triage 分流入口）。'
    } > "$HOME/.gitconfig.local"
    step '.gitconfig.local' CHANGED '已创建（空自留地）'
else
    step '.gitconfig.local' SKIP '已存在'
fi

phase 'dotfiles · ~/.ldc 指针与钩子接线'
printf '%s\n' "$ROOT" > "$HOME/.ldc"
step '~/.ldc 指针' OK "$ROOT"
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    if [ "$(git -C "$ROOT" config core.hooksPath)" = ".githooks" ]; then
        step 'hooksPath' SKIP '已接线 .githooks'
    elif git -C "$ROOT" config core.hooksPath .githooks; then
        step 'hooksPath' CHANGED '→ .githooks'
    else
        step 'hooksPath' FAIL
        fail=$((fail + 1))
    fi
else
    step 'hooksPath' INFO '尚未 git init——init 后重跑 bootstrap 自动接线'
fi

phase 'dotfiles · 汇总'
if [ "$fail" -eq 0 ]; then
    step 'dotfiles 阶段' OK
    exit 0
fi
step 'dotfiles 阶段' FAIL "$fail 项失败"
exit 1
