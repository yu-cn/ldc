#!/usr/bin/env bash
# install-packages.sh — root 阶段：apt 包清单核销 + fd/bat 兼容链接 + gh 官方源 + Docker（官方 apt 源，ADR-0019；ADR-0004）
# 必须可独立 sudo 运行：cd <repo> && sudo bash scripts/install-packages.sh
# 可选包组（ADR-0010）：附加参数显式指名——sudo bash scripts/install-packages.sh media-doc
#   （清单即菜单 configs/<名>.pkg；装没装由 dpkg 记账，不进 verify/root 完成度）
# 工单12（承接 WDC 工单41 移交）：root 阶段另含机器形态三件——默认 shell=bash（chsh）、
#   wsl.conf systemd（is_wsl 门控）、docker 组免 sudo（root_target_user 判定操作对象）
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
# chsh / docker 组的操作对象（sudo 语境优先，委托方 root 直调经 LDC_USER 显式传入——ADR-0007）
target_user=$(root_target_user)

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
# 24h 内已更新则跳过（工单12 顺手项，本地 mtime 判定）：重复索引更新是纯耗时；
# 新增厂商源的索引更新由 add_vendor_repo 调用点自行补（不受本跳过影响），
# 新机/清过缓存的机器 lists 无近期 Packages 索引、照常更新
if [ -n "$(find /var/lib/apt/lists -maxdepth 1 -name '*Packages*' -mmin -1440 -print -quit 2>/dev/null)" ]; then
    step 'apt-get update' SKIP '索引 24h 内已更新（本地判定）'
elif apt-get update -qq; then
    step 'apt-get update' OK
else
    step 'apt-get update' FAIL '索引更新失败（网络/源问题）——修复后重跑（幂等）'
    exit 1
fi

phase 'root · 包清单核销（base-linux + cli-tools）'
while read -r pkg; do
    pkg_install "$pkg" || fail=$((fail + 1))
done < <(pkg_list base-linux.pkg && pkg_list cli-tools.pkg)

# 可选包组（ADR-0010）：仅显式指名时安装——选择在调用时，激活态即 dpkg 状态
if [ $# -gt 0 ]; then
    phase 'root · 可选包组（显式指名）'
    for name in "$@"; do
        if [ ! -f "$ROOT/configs/$name.pkg" ]; then
            available=''
            for m in "$ROOT"/configs/*.pkg; do available+=" ${m##*/}"; done
            step "可选包组 $name" FAIL "configs/$name.pkg 不存在——可用：${available//.pkg/}"
            fail=$((fail + 1))
            continue
        fi
        while read -r pkg; do
            pkg_install "$pkg" || fail=$((fail + 1))
        done < <(pkg_list "$name.pkg")
    done
fi

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
if ! desktop_stack_present; then
    step 'desktop-apps' SKIP '非桌面机器形态（headless/WSL/容器）'
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

phase 'root · 机器形态（默认 shell / wsl.conf systemd——工单12 自 WDC setup-ubuntu.sh 移交）'
# 默认 shell = bash（幂等）：本仓 dotfiles 以 bash 为壳，默认 shell 与声明一致；
# 无目标用户（容器 root 冒烟）跳过
if [ -z "$target_user" ]; then
    step '默认 shell' SKIP '无目标用户（容器 root 冒烟）'
else
    cur_shell=$(getent passwd "$target_user" | cut -d: -f7)
    if [ "$cur_shell" = "/bin/bash" ]; then
        step '默认 shell' SKIP "$target_user 已是 bash"
    elif chsh -s /bin/bash "$target_user"; then
        step '默认 shell' CHANGED "$target_user → /bin/bash（重新登录生效）"
    else
        step '默认 shell' FAIL "chsh 失败（当前 $cur_shell）"
        fail=$((fail + 1))
    fi
fi
# wsl.conf systemd：WSL 形态才相关（Docker 守护进程依赖）；写入后需 wsl --shutdown 重启
# 发行版生效——本会话内 systemd 仍是未生效中间态，docker 域由 docker_skipped 自跳、
# 重启后重跑 bootstrap 补装（幂等）。语义与原 WDC setup-ubuntu.sh 实现一致（移交不改行为）
if is_wsl; then
    if grep -q '^systemd=true' /etc/wsl.conf 2>/dev/null; then
        step 'wsl.conf systemd' SKIP '已启用'
    else
        printf '\n[boot]\nsystemd=true\n' >> /etc/wsl.conf
        step 'wsl.conf systemd' CHANGED '已写入——wsl --shutdown 后下次进入生效'
    fi
else
    step 'wsl.conf systemd' SKIP '非 WSL 形态'
fi

phase 'root · Docker（download.docker.com 官方 apt 源，ADR-0019）'
if docker_skipped; then
    step docker SKIP '外部 LDC_SKIP_DOCKER 或 systemd 未生效中间态——生效后重跑补装'
elif have docker; then
    step docker SKIP '已装'
else
    # 与 gh/VSCode/Chrome 同款 add_vendor_repo 配方（ADR-0019）：keyring + 源 + 一次 apt 事务——
    # get.docker.com 管道脚本退役；marker 判重兼容其既有安装（同源同 keyring，含 deb822 形态，
    # 幂等直入安装段）。distro/codename 直取 os-release（预检已限死 ubuntu/debian）；Ubuntu
    # interim 发行版 docker 源偶有数日滞后，届时本步 FAIL 带指引，不静默降级
    # shellcheck disable=SC1091
    . /etc/os-release
    arch=$(dpkg --print-architecture)
    if add_vendor_repo docker.gpg "https://download.docker.com/linux/${ID}/gpg" docker.list \
        "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
        '' 'download\.docker\.com/linux/(ubuntu|debian)' \
       && apt-get update -qq \
       && apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null; then
        step docker OK '官方 apt 源安装（docker-ce + buildx / compose 插件）'
    else
        step docker FAIL '官方源配置/安装失败（ADR-0019——codename 是否被 docker 源支持查 docs.docker.com）'
        fail=$((fail + 1))
    fi
fi
# docker 组免 sudo：幂等；无目标用户（容器 root 直跑）跳过不碍
if [ -n "$target_user" ] && ! docker_skipped; then
    if getent group docker | grep -qw "$target_user"; then
        step 'docker 组' SKIP "$target_user 已在组"
    elif usermod -aG docker "$target_user"; then
        step 'docker 组' CHANGED "$target_user 已入组（重新登录生效）"
    else
        step 'docker 组' FAIL
        fail=$((fail + 1))
    fi
fi

phase 'root · Docker daemon 配置（受保护合并，ADR-0009）'
# 通用核心键（日志轮转 + live-restore）经 jq 递归合并进 daemon.json：声明叶键胜出、
# 机器自有键（镜像加速/data-root/NVIDIA 等）原样保留；绝不自动重启 docker（重启杀在跑容器）——
# live-restore 生效后的重启本就不再杀容器，重启时机留给机主
if docker_skipped; then
    step 'daemon 配置' SKIP '外部 LDC_SKIP_DOCKER 或 systemd 未生效中间态'
elif ! have docker; then
    step 'daemon 配置' SKIP 'docker 不在位'
else
    declared="$ROOT/configs/docker-daemon.json"
    target=/etc/docker/daemon.json
    if [ ! -f "$target" ]; then
        mkdir -p /etc/docker
        if install -m 0644 "$declared" "$target"; then
            step 'daemon.json' CHANGED '已按声明创建（下次 systemctl restart docker 生效；本次重启 live-restore 尚未生效，留意在跑容器）'
        else
            step 'daemon.json' FAIL '创建失败'
            fail=$((fail + 1))
        fi
    elif ! jq empty "$target" >/dev/null 2>&1; then
        step 'daemon.json' FAIL '现有文件为非法 JSON，跳过合并（人工处置）'
        fail=$((fail + 1))
    elif docker_daemon_declared_ok; then
        step 'daemon.json' SKIP '声明键全部在位'
    else
        merged=$(jq -s '.[0] * .[1]' "$target" "$declared") || fail=$((fail + 1))
        if [ "$fail" -eq 0 ] \
           && { [ ! -e "$target.bak" ] && cp "$target" "$target.bak"; true; } \
           && printf '%s\n' "$merged" > "$target.tmp" \
           && mv "$target.tmp" "$target" \
           && chmod 0644 "$target" \
           && docker_daemon_declared_ok; then
            step 'daemon.json' CHANGED '已合并声明键（机器自有键保留，原件备份 .bak；下次 systemctl restart docker 生效）'
        elif [ "$fail" -eq 0 ]; then
            step 'daemon.json' FAIL '合并失败'
            fail=$((fail + 1))
        fi
    fi
fi

phase 'root · 汇总'
if [ "$fail" -eq 0 ]; then
    step 'root 阶段' OK '全部就位'
    exit 0
fi
step 'root 阶段' FAIL "$fail 项失败——修复后重跑（幂等，已装项会跳过）"
exit 1
