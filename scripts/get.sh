#!/usr/bin/env bash
# get.sh — 远程一键引导（运行时仓库尚不存在，故不依赖本仓库任何脚本；对齐 WDC scripts/get.ps1）
# 用法（新机器一条命令）：
#   curl -fsSL https://raw.githubusercontent.com/yu-cn/ldc/main/scripts/get.sh | bash
# 职责：缺 git/curl 则 apt 安装（sudo；需密码就地询问）→ 定位或 clone 仓库 → bash bootstrap.sh
# fork 用户：本文件写死上游地址——fork 后走 README 的手动 clone 路径，或把地址改成你的仓库
set -uo pipefail

REPO_URL="https://github.com/yu-cn/ldc.git"
DEFAULT_DIR="$HOME/ldc"

log() { printf '[get] %s\n' "$*"; }

apt_install() {
    if [ "$(id -u)" -eq 0 ]; then
        apt-get update -qq && apt-get install -y -qq git curl
    elif command -v sudo >/dev/null 2>&1; then
        sudo apt-get update -qq && sudo apt-get install -y -qq git curl
    else
        log "ERROR: 无 root 且无 sudo——请手动安装后重跑：sudo apt install -y git curl"
        return 1
    fi
}

if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
    log "缺 git/curl —— apt 安装（sudo 需密码会就地询问）…"
    apt_install || exit 1
    log "依赖就位"
fi

# 仓库定位：~/.ldc 指针有效则复用（已有机器重跑 = 收敛语义）；缺省 clone 到 ~/ldc
repo=""
if [ -f "$HOME/.ldc" ]; then
    candidate=$(head -n 1 "$HOME/.ldc" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    if [ -n "$candidate" ] && [ -d "$candidate/.git" ]; then
        repo="$candidate"
    fi
fi
if [ -z "$repo" ]; then
    if [ -d "$DEFAULT_DIR" ] && [ ! -d "$DEFAULT_DIR/.git" ]; then
        log "ERROR: $DEFAULT_DIR 已存在但不是 git 仓库——不代删，人工处置后重跑"
        exit 1
    fi
    if [ ! -d "$DEFAULT_DIR" ]; then
        log "clone 仓库 → $DEFAULT_DIR"
        git clone "$REPO_URL" "$DEFAULT_DIR" || { log "ERROR: clone 失败——检查网络后重跑"; exit 1; }
    fi
    repo="$DEFAULT_DIR"
fi

log "仓库就位：$repo —— 转发 bootstrap（root 交接语义在其内）"
bash "$repo/bootstrap.sh"
exit $?
