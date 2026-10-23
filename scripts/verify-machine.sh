#!/usr/bin/env bash
# shellcheck disable=SC2088  # 标签文案中的 ~/ 是显示约定不参与展开；真实路径展开一律用 $HOME
# verify-machine.sh — 机器状态断言（只读，不改变任何状态）；任一 FAIL → exit 1
# 五组断言（对齐 WDC verify-machine.ps1 风格）：
#   ① dotfiles 符号链接 + 模板与 HEAD 一致（防写穿；无 commit 时降级 INFO）+ hooksPath
#   ② gitidentity 存在且非占位（未填 = FAIL 是设计内护栏；LDC_SMOKE=1 容器冒烟降为存在性检查）
#   ③ 包清单核销（dpkg -s 逐项；即 root 阶段完成度）
#   ④ 语言栈（uv 在位、vp = 钉子、node 可用——不断言 node 归属，ADR-0003 nvm 共存）
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

phase '1/5 · dotfiles 符号链接与接线'
assert_that '~/.bashrc → 仓库模板' '重跑 bash bootstrap.sh（dotfiles 阶段）' \
    '[ "$(readlink "$HOME/.bashrc")" = "$ROOT/dotfiles/linux/bashrc" ]'
assert_that '~/.gitconfig → 仓库模板' '重跑 bash bootstrap.sh（dotfiles 阶段）' \
    '[ "$(readlink "$HOME/.gitconfig")" = "$ROOT/dotfiles/linux/gitconfig" ]'
assert_that '~/.config/starship.toml → 仓库模板' '重跑 bash bootstrap.sh（dotfiles 阶段）' \
    '[ "$(readlink "$HOME/.config/starship.toml")" = "$ROOT/dotfiles/shared/starship.toml" ]'
# dotfiles 落点是符号链接，机器侧工具写穿会直接污染仓库——验收须与 HEAD 一致；无 commit 时降级 INFO
if git -C "$ROOT" rev-parse --verify HEAD >/dev/null 2>&1; then
    assert_that 'dotfiles 与 HEAD 一致（防写穿）' '写穿漂移——bash scripts/triage-dotfiles-drift.sh 逐文件分流' \
        '[ -z "$(git -C "$ROOT" status --porcelain -- dotfiles)" ]'
else
    step 'dotfiles 与 HEAD 一致（防写穿）' INFO '仓库尚无 commit——跳过比对（首次 commit 后生效）'
fi
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
fi

phase '4/5 · 语言栈与架构'
assert_that '架构受支持（amd64/arm64）' 'LDC 仅支持 amd64/arm64（ADR-0006）' 'ldc_arch >/dev/null'
assert_that 'uv 就位' '重跑 bootstrap（user 工具阶段）' '[ -x "$HOME/.local/bin/uv" ] || command -v uv'
VP_PIN="$(pin_of vp-version)" || exit 1
vp_bin="$(vp_bin_path || true)"
if [ -n "$vp_bin" ] && version_matches "$("$vp_bin" --version 2>/dev/null)" "$VP_PIN"; then
    step "vp = 钉子（$VP_PIN）" OK
else
    step "vp = 钉子（$VP_PIN）" FAIL '重跑 bootstrap（user 工具阶段）'
    FAILS=$((FAILS + 1))
fi
assert_that 'node 可用' 'node 由 vp 或机器自留地（如 nvm）提供——重跑 bootstrap' \
    'command -v node || ls "$HOME"/.nvm/versions/node/*/bin/node >/dev/null 2>&1 || [ -x "$HOME/.local/share/vite-plus/fallback-bin/node" ]'

phase '5/5 · 桌面域'
if ! have gsettings; then
    step '桌面域' SKIP '无 gsettings（headless 机器，桌面域未启用）'
else
    assert_that 'JetBrainsMono NF 字体目录' '重跑 bootstrap（user 工具阶段）' \
        '[ -n "$(ls -A "$HOME/.local/share/fonts/JetBrainsMono-NF" 2>/dev/null)" ]'
    if ! desktop_session_reachable; then
        step 'gsettings 读值比对' SKIP '无图形会话——登录 GNOME 桌面后重跑 bootstrap'
    elif [ "$QUICK" -eq 1 ]; then
        step 'gsettings 读值比对' SKIP '--quick 跳过（会话在位）'
    else
        while read -r schema key value; do
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
