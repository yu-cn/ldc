#!/usr/bin/env bash
# shellcheck disable=SC2088  # 标签文案中的 ~/ 是显示约定不参与展开；真实路径展开一律用 $HOME
# install-dotfiles.sh — dotfiles 层：符号链接 + .bak 备份 + .bashrc.local 机器自留地迁移
#   + gitidentity 占位 + ~/.ldc 指针 + pre-commit 钩子接线
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
    # link <仓库源文件> <落点>：已是正确符号链接 → 幂等跳过；旧实体文件 → 备份 .bak 后链接
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

phase 'dotfiles · .bashrc.local 迁移（仅首次接管时）'
if [ -f "$HOME/.bashrc" ] && [ ! -L "$HOME/.bashrc" ]; then
    # 整文件备份（保最早原件：已存在 .bak 则不动）
    if [ ! -e "$HOME/.bashrc.bak" ]; then
        cp "$HOME/.bashrc" "$HOME/.bashrc.bak"
        step '.bashrc.bak' CHANGED '原 bashrc 整文件已备份（未迁移的差异请自行搬运）'
    else
        step '.bashrc.bak' SKIP '已存在（保最早原件）'
    fi
    if [ -e "$HOME/.bashrc.local" ]; then
        step '.bashrc.local' SKIP '已存在，不覆盖（机主维护）'
    else
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
    fi
elif [ -L "$HOME/.bashrc" ]; then
    step '.bashrc.local' SKIP 'bashrc 已是符号链接（非首次接管，或外来管理器——WDC WSL 委托迁移场景，见 ADR-0007）'
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

phase 'dotfiles · 符号链接'
link "$ROOT/dotfiles/linux/bashrc"           "$HOME/.bashrc"
link "$ROOT/dotfiles/linux/gitconfig"        "$HOME/.gitconfig"
mkdir -p "$HOME/.config"
link "$ROOT/dotfiles/shared/starship.toml"   "$HOME/.config/starship.toml"
# ldc CLI 薄入口（对齐 wdc 的 profile 转发习惯；Linux 用符号链接更通用——非交互 shell 也可用，
# 任意目录裸命令 `ldc sync`）。仓库迁移后重跑 bootstrap 会自动重指
mkdir -p "$HOME/.local/bin"
link "$ROOT/ldc"                             "$HOME/.local/bin/ldc"
# VSCode 配置（ADR-0008 桌面应用域；headless 机器不经 Remote 用到本机 VSCode，不链接）。
# 注意：VSCode 会写穿 settings.json（改设置时直落模板）——防写穿断言 + triage 分流；
# 首次启动须关闭 Settings Sync（账号级开关，云端会与仓库 dotfiles 打架，WDC 同款教训）
if desktop_stack_present; then
    link "$ROOT/dotfiles/linux/vscode-settings.json"   "$HOME/.config/Code/User/settings.json"
    link "$ROOT/dotfiles/linux/vscode-keybindings.json" "$HOME/.config/Code/User/keybindings.json"
else
    step 'vscode 配置链接' SKIP '非桌面机器形态（ADR-0008）'
fi

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
# gitconfig 自留地（ADR-0003，与 .bashrc.local 同构）：gh auth setup-git 等写穿模板符号链接的
# 机器段迁来这里；模板经 [include] 引用，文件缺失时 git 静默忽略
if [ ! -e "$HOME/.gitconfig.local" ]; then
    {
        echo '# ~/.gitconfig.local — 机器自留地（ADR-0003，与 .bashrc.local 同构）：LDC 不管理、不入仓库'
        echo '# gh auth setup-git 写穿模板符号链接的凭据段迁到这里；此后由机主维护。'
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
