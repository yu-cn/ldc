#!/usr/bin/env bash
# install-user-tools.sh — user 阶段工具（全部用户级、免 sudo）：
#   vp 退役迁移（一次性豁免，ADR-0016）/ uv / mise（钉 configs/*-version，管 Node 等语言）
#   / starship / lazygit（钉 configs/lazygit-version）
#   / JetBrainsMono NF 字体（钉 configs/nerd-fonts-version；仅 gsettings 机器装）
# 四件 tar.gz 钉子安装共用 common.sh 的 pinned_tarball_install（下载→sha256→解压→install
# 同构面的单一来源；各工具资产命名例外注释保留在调用点）
# nvm 共存政策（ADR-0003）：不卸 nvm、不碰其块——它是机器自留地；本机 node 归属以 .bashrc.local 后加载胜出
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"
fail=0
mkdir -p "$HOME/.local/bin"
# tmp 登记 + 退出/中断清理（common.sh ldc_tmp_*）：钉子下载与字体解压的临时目录，中断也不在 /tmp 留残
trap ldc_tmp_cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

phase 'user 工具 · uv（管 Python，钉子安装）'
UV_VERSION="$(pin_of uv-version)" || exit 1
# uv 资产命名例外（rust triple）：amd64→x86_64-unknown-linux-gnu，arm64→aarch64-unknown-linux-gnu
arch=$(ldc_arch 2>/dev/null) || arch=''
case $arch in
    amd64) uv_asset=x86_64-unknown-linux-gnu ;;
    arm64) uv_asset=aarch64-unknown-linux-gnu ;;
    *) step uv FAIL '架构不受支持（amd64/arm64，ADR-0006）'; fail=$((fail + 1)) ;;
esac
if [ -n "${uv_asset:-}" ]; then
    pinned_tarball_install uv uv-version "$HOME/.local/bin/uv" \
        "https://github.com/astral-sh/uv/releases/download/${UV_VERSION}/uv-${uv_asset}.tar.gz" \
        "uv-${uv_asset}/uv:$HOME/.local/bin/uv" \
        "uv-${uv_asset}/uvx:$HOME/.local/bin/uvx" \
        || fail=$((fail + 1))
fi
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

phase 'user 工具 · vp 退役迁移（ADR-0016 一次性豁免）'
# 「只装不删」红线的显式例外：vp→mise 属迁移冲突——vp env on 的 shims 不撤会与 mise PATH 打架，
# 非自留地（自留地不碰不变）。官方未提供卸载命令（安装器无 uninstall 面、CLI 无 self 子命令），
# 按安装器写入面反向清除：安装目录 + ~/.profile 标记行（env.sh 事实文件由本脚本末段重写、自然去 vp）。
vp_cleaned=0
for d in "$HOME/.vite-plus" "$HOME/.local/share/vite-plus" "$HOME/.cache/vite-plus"; do
    [ -e "$d" ] && { rm -rf "$d"; vp_cleaned=1; }
done
if [ -f "$HOME/.profile" ] && grep -q 'Vite+ bin' "$HOME/.profile"; then
    # 精确删安装器写入的标记行与其紧随的 source 行，其余内容一概不碰
    sed -i '/# Vite+ bin (https:\/\/viteplus.dev)/{N;d}' "$HOME/.profile"
    vp_cleaned=1
fi
if [ "$vp_cleaned" -eq 1 ]; then
    step vp CHANGED '已退役清除（→ mise，ADR-0016 迁移豁免）'
else
    step vp SKIP '不在位（新机或已清）'
fi

phase 'user 工具 · mise（管 Node 等语言）'
MISE_VERSION="$(pin_of mise-version)" || exit 1
mise_bin="$HOME/.local/bin/mise"   # 下方 node@lts 段同用
# mise 资产命名例外：amd64→x64（GitHub release 段名；arm64 同名无例外）
arch=$(ldc_arch 2>/dev/null) || arch=''
case $arch in
    amd64) mise_arch=x64 ;;
    arm64) mise_arch=arm64 ;;
    *) step mise FAIL '架构不受支持（amd64/arm64，ADR-0006）'; fail=$((fail + 1)) ;;
esac
if [ -n "${mise_arch:-}" ]; then
    pinned_tarball_install mise mise-version "$HOME/.local/bin/mise" \
        "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/mise-v${MISE_VERSION}-linux-${mise_arch}.tar.gz" \
        "mise/bin/mise:$HOME/.local/bin/mise" \
        || fail=$((fail + 1))
fi
# 默认环境 node@lts（对齐原 vp env default lts 语义——每次收敛重发即随最新 LTS，零维护）；
# ensure 型步骤报 OK 不报 CHANGED（对齐 vp env install 旧例）：幂等重跑零 [CHANGED] 基线由本体安装行承担
if [ -x "$mise_bin" ]; then
    mise_out=$(mktemp)
    if "$mise_bin" use -g node@lts >"$mise_out" 2>&1; then
        step 'mise 默认 node（lts）' OK '已确保就位（shims：~/.local/share/mise/shims）'
    elif ! ldconfig -p 2>/dev/null | grep -q 'libatomic\.so'; then
        # node（mise 核心 backend，x64 官方构建）链接 libatomic——root 未交接的机器（handoff 首跑/最小容器）
        # 装不上系统库，属交接前合法中间态而非失败：base-linux 的 libatomic1 随 root 阶段落位，
        # 交接完成后重跑 bootstrap 即装（冒烟 handoff 腿 run 41209239555 实录）
        step 'mise 默认 node（lts）' INFO '待 root 阶段（libatomic 缺）——root 交接完成后重跑 bootstrap 即装'
    else
        # FAIL 带错误尾证（冒烟实录：吞输出致 amd64 瞬态无诊断面）
        step 'mise 默认 node（lts）' FAIL "$(tail -n 3 "$mise_out" | tr '\n' ' ')"
        fail=$((fail + 1))
    fi
    rm -f "$mise_out"
fi

phase 'user 工具 · starship'
SS_VERSION="$(pin_of starship-version)" || exit 1
# 资产命名例外（rust triple）：amd64→x86_64-unknown-linux-gnu，arm64→aarch64-unknown-linux-musl
#（starship 对 aarch64 只发 musl 静态包，glibc 系统直接可用）
arch=$(ldc_arch 2>/dev/null) || arch=''
case $arch in
    amd64) ss_asset=x86_64-unknown-linux-gnu ;;
    arm64) ss_asset=aarch64-unknown-linux-musl ;;
    *) step starship FAIL '架构不受支持（amd64/arm64，ADR-0006）'; fail=$((fail + 1)) ;;
esac
if [ -n "${ss_asset:-}" ]; then
    pinned_tarball_install starship starship-version "$HOME/.local/bin/starship" \
        "https://github.com/starship/starship/releases/download/v${SS_VERSION}/starship-${ss_asset}.tar.gz" \
        "starship:$HOME/.local/bin/starship" \
        || fail=$((fail + 1))
fi

phase 'user 工具 · lazygit'
LG_VERSION="$(pin_of lazygit-version)" || exit 1
# lazygit 资产命名例外：x86_64 资产叫 linux_x86_64 而非 linux_amd64（arm64 同名无例外）
arch=$(ldc_arch 2>/dev/null) || arch=''
case $arch in
    amd64) lg_arch=x86_64 ;;
    arm64) lg_arch=arm64 ;;
    *) step lazygit FAIL '架构不受支持（amd64/arm64，ADR-0006）'; fail=$((fail + 1)) ;;
esac
if [ -n "${lg_arch:-}" ]; then
    pinned_tarball_install lazygit lazygit-version "$HOME/.local/bin/lazygit" \
        "https://github.com/jesseduffield/lazygit/releases/download/v${LG_VERSION}/lazygit_${LG_VERSION}_linux_${lg_arch}.tar.gz" \
        "lazygit:$HOME/.local/bin/lazygit" \
        || fail=$((fail + 1))
fi

phase 'user 工具 · JetBrainsMono NF 字体'
if ! desktop_stack_present; then
    step '字体' SKIP '非桌面机器形态（headless/WSL/容器）'
else
    NF_VERSION="$(pin_of nerd-fonts-version)" || exit 1
    fontdir="$HOME/.local/share/fonts/JetBrainsMono-NF"
    stamp="$fontdir/.ldc-version"
    # 版本戳记：钉子升级即重装（字体包无自报版本，戳记是唯一判据）
    if [ -d "$fontdir" ] && [ -f "$stamp" ] && [ "$(cat "$stamp" 2>/dev/null)" = "$NF_VERSION" ]; then
        step '字体' SKIP "= 钉子 $NF_VERSION（$fontdir）"
    else
        url="https://github.com/ryanoasis/nerd-fonts/releases/download/v${NF_VERSION}/JetBrainsMono.zip"
        mkdir -p "$fontdir"
        tmp=$(mktemp -d)
        ldc_tmp_register "$tmp"
        # 校验 sha256（钉子文件无 arch 行，字体包不分架构，ADR-0011）再解压
        if curl -fsSL -o "$tmp/JetBrainsMono.zip" "$url"; then
            got=$(sha256sum "$tmp/JetBrainsMono.zip" | awk '{print $1}')
            want="$(pin_sha256 nerd-fonts-version || true)"
            if [ -n "$want" ] && [ "$got" != "$want" ]; then
                step '字体 校验和' FAIL "不符（预期 $want / 实得 $got）——疑似供应链异常，拒绝安装（ADR-0011）"
                fail=$((fail + 1))
            elif unzip -oq "$tmp/JetBrainsMono.zip" -d "$fontdir"; then
                [ -z "$want" ] && step '字体 校验和' INFO '钉子未含 sha256 行——未校验（按 ADR-0011 补钉）'
                printf '%s\n' "$NF_VERSION" > "$stamp"
                step '字体' CHANGED "v$NF_VERSION → $fontdir"
            else
                step '字体' FAIL '解压失败'
                fail=$((fail + 1))
            fi
        else
            step '字体' FAIL "下载失败（$url）"
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
if ! desktop_stack_present; then
    step 'VSCode 扩展' SKIP '非桌面机器形态（headless/WSL/容器）'
elif ! have code; then
    step 'VSCode 扩展' INFO 'code 未装——root 阶段交接完成后重跑 bootstrap'
else
    # 幂等安装 fast-path：先读在装清单做差集（与 verify/plan 的 comm 口径同源），只对缺失件走
    # marketplace——已装件零网络往返；机器自装扩展不在清单不核销（ADR-0003）
    ext_missing=$(comm -23 <(pkg_list vscode-extensions.txt | sort) <(code --list-extensions 2>/dev/null | sort))
    ext_total=$(pkg_list vscode-extensions.txt | grep -c . || true)
    if [ -z "$ext_missing" ]; then
        step 'VSCode 扩展' OK "$ext_total/$ext_total 就位"
    else
        ext_fail='' ext_installed=0
        for ext in $ext_missing; do
            if code --install-extension "$ext" >/dev/null 2>&1; then
                ext_installed=$((ext_installed + 1))
            else
                ext_fail="$ext_fail $ext"
            fi
        done
        if [ -z "$ext_fail" ]; then
            step 'VSCode 扩展' OK "补装 $ext_installed 件（$ext_total/$ext_total 就位）"
        else
            step 'VSCode 扩展' FAIL "失败：$ext_fail"
            fail=$((fail + 1))
        fi
    fi
fi

phase 'user 工具 · 机器事实文件 env.sh（ADR-0015）'
# bashrc 模板只 source 这一个文件：fzf 键位示例路径在安装期探测落盘——mise/uv 布局固定，
# 直接在 bashrc 模板声明（与 uv 同款），不走 env.sh。每次收敛重写（事实随工具升级而变）。
env_file="$HOME/.config/ldc/env.sh"
fzf_kb=/usr/share/doc/fzf/examples/key-bindings.bash
fzf_cm=/usr/share/doc/fzf/examples/completion.bash
mkdir -p "$HOME/.config/ldc"
{
    echo '# ~/.config/ldc/env.sh — 工具布局事实（install-user-tools 每次收敛重写；ADR-0015）'
    echo '# bashrc 模板统一 source 本文件；机器私有偏好放 ~/.bashrc.local（后加载可覆盖）。'
    if [ -f "$fzf_kb" ] || [ -f "$fzf_cm" ]; then
        echo ''
        echo '# fzf 键位绑定与补全（发行版包示例路径，存在才 source）'
        if [ -f "$fzf_kb" ]; then printf '[ -f %s ] && . %s\n' "$fzf_kb" "$fzf_kb"; fi
        if [ -f "$fzf_cm" ]; then printf '[ -f %s ] && . %s\n' "$fzf_cm" "$fzf_cm"; fi
    fi
} > "$env_file"
step 'env.sh' OK "$env_file（fzf 布局事实已落盘）"

phase 'user 工具 · 汇总'
if [ "$fail" -eq 0 ]; then
    step 'user 工具' OK '全部就位'
    exit 0
fi
step 'user 工具' FAIL "$fail 项失败——修复后重跑（幂等）"
exit 1
