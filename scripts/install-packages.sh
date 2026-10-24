#!/usr/bin/env bash
# install-packages.sh — root 阶段：apt 包清单核销 + fd/bat 兼容链接 + gh 官方源 + Docker（ADR-0004）
# 必须可独立 sudo 运行：cd <repo> && sudo bash scripts/install-packages.sh
# 幂等：已装全部跳过；逐包失败不中断，结尾汇总非零退。容器 root 直跑同样成立（CI 冒烟路径）
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"

if [ "$(id -u)" -ne 0 ]; then
    log "ERROR: 本脚本需 root 运行——交接命令：$(root_handoff_cmd)"
    exit 1
fi
export DEBIAN_FRONTEND=noninteractive
fail=0

add_vendor_repo() {
    # add_vendor_repo <keyring名> <密钥URL> <源文件名> <源行> [direct] [源URL标记] —— 厂商 apt 源（幂等）
    # direct=密钥已是二进制 keyring 直接落盘；默认对 ASCII armored 密钥走 gpg --dearmor。
    # 源URL标记=判重标记：厂商可能自管源（如 Chrome postinst 写 deb822 .sources 并清掉我们的 .list），
    # 或机器上已有其它形态的同厂商源——标记命中任一源文件即视为已配置，避免双源（WDC 已知坑12 同款）
    # 失败即清理半成品，防空 keyring 破坏下次幂等判断
    local keyring="/etc/apt/keyrings/$1" keyurl=$2 list="/etc/apt/sources.list.d/$3" line=$4 mode=${5:-} marker=${6:-}
    [ -f "$keyring" ] && [ -f "$list" ] && return 0
    # 标记用 ERE，可写交替分支（如 vscode 的新旧两条路径）；务必窄化到具体套件路径，
    # packages.microsoft.com 等厂商域名下还有 dotnet 等其它仓库，宽标记会误判
    if [ -n "$marker" ] && grep -rqE "$marker" /etc/apt/sources.list.d/ 2>/dev/null; then
        return 0
    fi
    install -m 0755 -d /etc/apt/keyrings
    if [ "$mode" = direct ]; then
        curl -fsSL "$keyurl" -o "$keyring" || { rm -f "$keyring"; return 1; }
    else
        curl -fsSL "$keyurl" | gpg --dearmor > "$keyring" || { rm -f "$keyring"; return 1; }
    fi
    chmod go+r "$keyring" && printf '%s\n' "$line" > "$list"
}

phase 'root · apt 索引更新'
if apt-get update -qq; then
    step 'apt-get update' OK
else
    step 'apt-get update' FAIL '索引更新失败（网络/源问题）——修复后重跑（幂等）'
    exit 1
fi

phase 'root · 包清单核销（base-linux + cli-tools）'
while read -r pkg; do
    pkg_install "$pkg" || fail=$((fail + 1))
done < <(pkg_list base-linux.pkg && pkg_list cli-tools.pkg)

phase 'root · Debian 命名兼容链接（fd/bat）'
# Debian 系 fd-find/bat 的二进制名是 fdfind/batcat——不补链接则模板别名断链
compat_link fdfind fd || fail=$((fail + 1))
compat_link batcat bat || fail=$((fail + 1))

phase 'root · gh（apt 官方源）'
if have gh; then
    step gh SKIP '已装'
else
    if add_vendor_repo githubcli-archive-keyring.gpg \
        https://cli.github.com/packages/githubcli-archive-keyring.gpg github-cli.list \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" direct \
        'cli\.github\.com/packages' \
       && apt-get update -qq && apt-get install -y -qq gh >/dev/null; then
        step gh OK '官方 apt 源安装'
    else
        step gh FAIL '官方源配置/安装失败'
        fail=$((fail + 1))
    fi
fi

phase 'root · 桌面应用域（VSCode / Chrome；ADR-0008）'
if ! have gsettings; then
    step 'desktop-apps' SKIP '无桌面栈（headless/WSL/容器）'
else
    arch=$(dpkg --print-architecture)
    ok_repo=1
    # 清理旧版手动源残留：packages.microsoft.com/repos/code 是 repos/vscode 的前身路径，
    # 手动装过 code 的机器两源并存（WDC 已知坑12 同款）——收敛到声明源
    if [ -f /etc/apt/sources.list.d/vscode.sources ] \
       && grep -q 'repos/code' /etc/apt/sources.list.d/vscode.sources 2>/dev/null; then
        rm -f /etc/apt/sources.list.d/vscode.sources
        step 'vscode 源' CHANGED '已清除旧版手动源（repos/code → 声明源 repos/vscode）'
    fi
    if add_vendor_repo microsoft.gpg https://packages.microsoft.com/keys/microsoft.asc vscode.list \
        "deb [arch=$arch signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main" \
        '' 'packages\.microsoft\.com/repos/(vscode|code)' ; then
        step 'vscode 源' OK 'packages.microsoft.com（keyring）'
    else
        step 'vscode 源' FAIL '密钥/源配置失败'
        ok_repo=0; fail=$((fail + 1))
    fi
    if add_vendor_repo google.gpg https://dl.google.com/linux/linux_signing_key.pub google-chrome.list \
        "deb [arch=$arch signed-by=/etc/apt/keyrings/google.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
        '' 'dl\.google\.com/linux/chrome' ; then
        step 'chrome 源' OK 'dl.google.com（keyring，或厂商自管源已在位）'
    else
        step 'chrome 源' FAIL '密钥/源配置失败'
        ok_repo=0; fail=$((fail + 1))
    fi
    if [ "$ok_repo" -eq 1 ]; then
        apt-get update -qq || true
        while read -r pkg; do
            pkg_install "$pkg" || fail=$((fail + 1))
        done < <(pkg_list desktop-apps.pkg)
    fi
fi

phase 'root · Docker'
if [ "${LDC_SKIP_DOCKER:-0}" = "1" ]; then
    step docker SKIP 'LDC_SKIP_DOCKER=1'
elif have docker; then
    step docker SKIP '已装'
else
    if curl -fsSL https://get.docker.com | sh >/dev/null; then
        step docker OK '官方脚本安装'
    else
        step docker FAIL 'get.docker.com 安装失败'
        fail=$((fail + 1))
    fi
fi
# docker 组免 sudo：幂等；有 SUDO_USER 才做（容器 root 直跑无 SUDO_USER，跳过不碍）
if [ -n "${SUDO_USER:-}" ] && [ "${LDC_SKIP_DOCKER:-0}" != "1" ]; then
    if getent group docker | grep -qw "$SUDO_USER"; then
        step 'docker 组' SKIP "$SUDO_USER 已在组"
    elif usermod -aG docker "$SUDO_USER"; then
        step 'docker 组' CHANGED "$SUDO_USER 已入组（重新登录生效）"
    else
        step 'docker 组' FAIL
        fail=$((fail + 1))
    fi
fi

phase 'root · 汇总'
if [ "$fail" -eq 0 ]; then
    step 'root 阶段' OK '全部就位'
    exit 0
fi
step 'root 阶段' FAIL "$fail 项失败——修复后重跑（幂等，已装项会跳过）"
exit 1
