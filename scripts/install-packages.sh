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
    # add_vendor_repo <keyring名> <密钥URL> <源文件名> <源行> [direct] —— 厂商 apt 源（keyring 方式，幂等）
    # direct=密钥已是二进制 keyring 直接落盘；默认对 ASCII armored 密钥走 gpg --dearmor。
    # 失败即清理半成品，防空 keyring 破坏下次幂等判断
    local keyring="/etc/apt/keyrings/$1" keyurl=$2 list="/etc/apt/sources.list.d/$3" line=$4 mode=${5:-dearmor}
    [ -f "$keyring" ] && [ -f "$list" ] && return 0
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
    if add_vendor_repo microsoft.gpg https://packages.microsoft.com/keys/microsoft.asc vscode.list \
        "deb [arch=$arch signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/vscode stable main"; then
        step 'vscode 源' OK 'packages.microsoft.com（keyring）'
    else
        step 'vscode 源' FAIL '密钥/源配置失败'
        ok_repo=0; fail=$((fail + 1))
    fi
    if add_vendor_repo google.gpg https://dl.google.com/linux/linux_signing_key.pub google-chrome.list \
        "deb [arch=$arch signed-by=/etc/apt/keyrings/google.gpg] https://dl.google.com/linux/chrome/deb/ stable main"; then
        step 'chrome 源' OK 'dl.google.com（keyring）'
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
