#!/usr/bin/env bash
# install-user-tools.sh — user 阶段工具（全部用户级、免 sudo）：
#   uv（跳过已装）/ vp（钉 configs/vp-version）/ starship / lazygit（钉 configs/lazygit-version）
#   / JetBrainsMono NF 字体（钉 configs/nerd-fonts-version；仅 gsettings 机器装）
# nvm 共存政策（ADR-0003）：不卸 nvm、不碰其块——它是机器自留地；本机 node 归属以 .bashrc.local 后加载胜出
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"
fail=0

phase 'user 工具 · uv（管 Python）'
if [ -x "$HOME/.local/bin/uv" ]; then
    step uv SKIP "已装（$("$HOME/.local/bin/uv" --version 2>/dev/null | head -n1)）"
elif curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null; then
    step uv OK '官方安装器'
else
    step uv FAIL '安装器执行失败'
    fail=$((fail + 1))
fi
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

phase 'user 工具 · vp（管 Node）'
VP_VERSION="$(pin_of vp-version)" || exit 1
vp_bin="$(vp_bin_path || true)"
if [ -z "$vp_bin" ]; then
    # 官方给的是 |sh，但其安装脚本含 bash 语法——Ubuntu 的 sh=dash 会 Bad substitution，必须 |bash
    export VP_VERSION
    if curl -fsSL https://vite.plus/sh | bash >/dev/null; then
        vp_bin="$(vp_bin_path || true)"
        [ -n "$vp_bin" ] && step vp OK "已装 $VP_VERSION（官方安装器，钉子）" || { step vp FAIL '安装器执行后仍未找到二进制'; fail=$((fail + 1)); }
    else
        step vp FAIL '安装器执行失败'
        fail=$((fail + 1))
    fi
elif version_matches "$("$vp_bin" --version 2>/dev/null)" "$VP_VERSION"; then
    step vp SKIP "= 钉子 $VP_VERSION"
else
    # 版本漂移：重跑钉子安装器收敛（幂等收敛到声明状态）
    export VP_VERSION
    if curl -fsSL https://vite.plus/sh | bash >/dev/null; then
        step vp CHANGED "收敛到钉子 $VP_VERSION"
    else
        step vp FAIL "收敛到 $VP_VERSION 失败"
        fail=$((fail + 1))
    fi
fi
# node 运行时三步（与 WDC 两侧同款；已装 LTS 时为快速幂等）
vp_bin="$(vp_bin_path || true)"
if [ -n "$vp_bin" ]; then
    if "$vp_bin" env default lts >/dev/null 2>&1 \
       && "$vp_bin" env install lts >/dev/null 2>&1 \
       && "$vp_bin" env on >/dev/null 2>&1; then
        step 'vp env（lts）' OK 'default/install lts + on'
    else
        step 'vp env（lts）' FAIL
        fail=$((fail + 1))
    fi
fi

phase 'user 工具 · starship'
if have starship || [ -x "$HOME/.local/bin/starship" ]; then
    step starship SKIP '已装'
elif curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin" >/dev/null; then
    # -b 指定用户级目录（官方默认 /usr/local/bin 需 sudo；user 阶段保持免提权）
    step starship OK '官方安装器 → ~/.local/bin'
else
    step starship FAIL '安装器执行失败'
    fail=$((fail + 1))
fi

phase 'user 工具 · lazygit'
LG_VERSION="$(pin_of lazygit-version)" || exit 1
lg_bin="$HOME/.local/bin/lazygit"
lg_current="$("$lg_bin" --version 2>/dev/null || true)"
if [ -x "$lg_bin" ] && version_matches "$lg_current" "$LG_VERSION"; then
    step lazygit SKIP "= 钉子 $LG_VERSION"
else
    arch="$(ldc_arch)" || fail=$((fail + 1))
    if [ -n "${arch:-}" ]; then
        # lazygit 资产命名例外：x86_64 资产叫 linux_x86_64 而非 linux_amd64（arm64 同名无例外）
        lg_arch=$arch
        [ "$lg_arch" = amd64 ] && lg_arch=x86_64
        url="https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_linux_${lg_arch}.tar.gz"
        tmp=$(mktemp -d)
        if curl -fsSL "$url" | tar -xzf - -C "$tmp" 2>/dev/null && install -m 0755 "$tmp/lazygit" "$lg_bin"; then
            if [ -n "$lg_current" ]; then step lazygit CHANGED "升级 → $LG_VERSION（$lg_bin）"
            else step lazygit OK "$LG_VERSION → $lg_bin"; fi
        else
            step lazygit FAIL "下载/安装失败（$url）"
            fail=$((fail + 1))
        fi
        rm -rf "$tmp"
    fi
fi

phase 'user 工具 · JetBrainsMono NF 字体'
if ! have gsettings; then
    step '字体' SKIP '无 gsettings（headless 域不装桌面字体）'
else
    NF_VERSION="$(pin_of nerd-fonts-version)" || exit 1
    fontdir="$HOME/.local/share/fonts/JetBrainsMono-NF"
    if [ -d "$fontdir" ] && [ -n "$(ls -A "$fontdir" 2>/dev/null)" ]; then
        step '字体' SKIP "已装（$fontdir）"
    else
        url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NF_VERSION}/JetBrainsMono.zip"
        mkdir -p "$fontdir"
        tmp=$(mktemp -d)
        if curl -fsSL -o "$tmp/JetBrainsMono.zip" "$url" && unzip -oq "$tmp/JetBrainsMono.zip" -d "$fontdir"; then
            step '字体' CHANGED "v$NF_VERSION → $fontdir"
        else
            step '字体' FAIL "下载/解压失败（$url）"
            fail=$((fail + 1))
        fi
        rm -rf "$tmp"
    fi
    if have fc-cache; then
        fc-cache -f >/dev/null 2>&1 && step 'fc-cache' OK || { step 'fc-cache' FAIL; fail=$((fail + 1)); }
    else
        step 'fc-cache' INFO 'fc-cache 暂不可用（root 阶段后补）——字体已就位，任一会话 fc-cache -f 即生效'
    fi
fi

phase 'user 工具 · VSCode 扩展（ADR-0008）'
if ! have gsettings; then
    step 'VSCode 扩展' SKIP '无桌面栈（headless/WSL/容器）'
elif ! have code; then
    step 'VSCode 扩展' INFO 'code 未装——root 阶段交接完成后重跑 bootstrap'
else
    # 幂等安装：--install-extension 对已装扩展快速通过；机器自装扩展不在清单不核销（ADR-0003）
    ext_total=0
    ext_ok=0
    ext_missing=''
    while read -r ext; do
        ext_total=$((ext_total + 1))
        if code --install-extension "$ext" >/dev/null 2>&1; then
            ext_ok=$((ext_ok + 1))
        else
            ext_missing="$ext_missing $ext"
        fi
    done < <(pkg_list vscode-extensions.txt)
    if [ -z "$ext_missing" ]; then
        step 'VSCode 扩展' OK "$ext_ok/$ext_total 就位"
    else
        step 'VSCode 扩展' FAIL "失败：$ext_missing"
        fail=$((fail + 1))
    fi
fi

phase 'user 工具 · 汇总'
if [ "$fail" -eq 0 ]; then
    step 'user 工具' OK '全部就位'
    exit 0
fi
step 'user 工具' FAIL "$fail 项失败——修复后重跑（幂等）"
exit 1
