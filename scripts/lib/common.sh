# shellcheck shell=bash
# common.sh — bootstrap 各阶段共用的报告与工具函数（被 source，不直接执行）
# 输出口径与 WDC lib/common.ps1 对齐：phase 分阶段标题、step 逐项 [状态] 标签 - 详情

# 颜色：输出到终端时着色；重定向/tee 时自动素净（日志文件干净）
if [ -t 1 ]; then
    C_OK=$'\e[32m'; C_SKIP=$'\e[90m'; C_FAIL=$'\e[31m'
    C_CHANGED=$'\e[33m'; C_PHASE=$'\e[1;36m'; C_PLAN=$'\e[35m'; C_OFF=$'\e[0m'
else
    C_OK=''; C_SKIP=''; C_FAIL=''; C_CHANGED=''; C_PHASE=''; C_PLAN=''; C_OFF=''
fi

log()   { printf '[ldc] %s\n' "$*"; }

phase() { printf '\n%s=== %s ===%s\n' "$C_PHASE" "$*" "$C_OFF"; }

step() {
    # step <标签> <状态> [详情]；状态 ∈ OK/SKIP/FAIL/CHANGED/PENDING/INFO/PLAN
    # PLAN = 干跑预演的「将变更」（plan-machine.sh 专用——只投影，不改任何状态）
    local label=$1 state=$2 detail=${3:-} color
    case $state in
        OK)      color=$C_OK ;;
        SKIP)    color=$C_SKIP ;;
        FAIL)    color=$C_FAIL ;;
        CHANGED) color=$C_CHANGED ;;
        PLAN)    color=$C_PLAN ;;
        *)       color='' ;;
    esac
    local line="[$state] $label"
    [ -n "$detail" ] && line="$line - $detail"
    printf '%s%s%s\n' "$color" "$line" "$C_OFF"
}

have() { command -v "$1" >/dev/null 2>&1; }

is_wsl() {
    # WSL 形态判定（内核版本串含 microsoft——微软官方标记；/proc 只读文件，不依赖环境变量）。
    # WSLg 会话让 gsettings 可达（ADR-0008 补记），「有 gsettings」从此不等价「桌面机器」——
    # 桌面域门禁一律走 desktop_stack_present，勿裸用 have gsettings
    grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null
}

desktop_stack_present() {
    # 桌面栈门禁单一来源（ADR-0005/0008）：gsettings 在位 且 非 WSL。
    # WSLg 不是桌面机器——Linux GUI 软件与字体由 Windows 侧承载；headless/CI 容器同样为假
    have gsettings && ! is_wsl
}

ldc_repo() {
    # 仓库根：common.sh 恒位于 <repo>/scripts/lib/ 下，从自身位置推导（不受调用方 cwd 影响）
    printf '%s\n' "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
}

pin_of() {
    # pin_of <configs 文件名> —— 版本钉子唯一来源（升级只改 configs/ 下这一个文件）
    local f val
    f="$(ldc_repo)/configs/$1"
    if [ ! -f "$f" ]; then log "ERROR: 缺失 $f"; return 1; fi
    val=$(head -n1 "$f" | tr -d '[:space:]')
    if [ -z "$val" ]; then log "ERROR: $f 首行为空"; return 1; fi
    printf '%s\n' "$val"
}

pin_sha256() {
    # pin_sha256 <钉子文件名> [arch] —— 下载资产校验和（ADR-0011 供应链钉）：
    # 钉子文件 sha256 行格式 `sha256 <hex>`（arch 无关资产）或 `sha256 <arch> <hex>`（分架构资产）；
    # 传 arch 取对应行，未传取无 arch 行。无该行返回 1（调用方决定降级口径）。
    local f val
    f="$(ldc_repo)/configs/$1"
    if [ ! -f "$f" ]; then log "ERROR: 缺失 $f"; return 1; fi
    if [ -n "${2:-}" ]; then
        val=$(grep -E "^sha256 $2 [0-9a-f]{64}$" "$f" | head -n1 | awk '{print $3}')
    else
        val=$(grep -E "^sha256 [0-9a-f]{64}$" "$f" | head -n1 | awk '{print $2}')
    fi
    [ -n "$val" ] && printf '%s\n' "$val"
}

pkg_list() {
    # pkg_list <清单名> —— 输出包名逐行（去注释与空行）
    local f
    f="$(ldc_repo)/configs/$1"
    if [ ! -f "$f" ]; then log "ERROR: 缺失 $f"; return 1; fi
    grep -vE '^[[:space:]]*(#|$)' "$f"
}

pkg_install() {
    # pkg_install <包名>… —— 包安装薄抽象（决策表：apt 先行，多发行版日后增量加）
    # 幂等：dpkg 已装跳过；失败逐包报告不抛异常（调用方收集），任一失败返回 1。需 root。
    local pkg rc=0 ver
    if ! have apt-get; then
        log 'ERROR: 未找到 apt-get——LDC v1 仅支持 Ubuntu/Debian（apt 系）'
        return 1
    fi
    for pkg in "$@"; do
        if dpkg -s "$pkg" >/dev/null 2>&1; then
            ver=$(dpkg-query -W -f='${Version}' "$pkg" 2>/dev/null)
            step "$pkg" SKIP "已装 $ver"
        elif apt-get install -y -qq "$pkg" >/dev/null 2>&1; then
            step "$pkg" OK 'apt 安装'
        else
            step "$pkg" FAIL 'apt 安装失败'
            rc=1
        fi
    done
    return $rc
}

compat_link() {
    # compat_link <源命令> <链接名> —— Debian 命名兼容（fdfind→fd、batcat→bat）：
    # 目标名已可直呼则跳过；源命令不存在（包未装）也跳过；否则幂等补 /usr/local/bin 链接
    local src=$1 name=$2 link="/usr/local/bin/$2"
    if have "$name"; then
        step "兼容链接 $name" SKIP '已可直呼'
    elif ! have "$src"; then
        step "兼容链接 $name" SKIP "无 $src 命令（无需兼容链接）"
    elif ln -sf "$(command -v "$src")" "$link"; then
        step "兼容链接 $name" CHANGED "$src → $link"
    else
        step "兼容链接 $name" FAIL
        return 1
    fi
    return 0
}

sudo_probe() {
    # sudo 形态探测：root（已提权/容器）/ nopasswd（免密可自动）/ interactive（需密码须交接）/ none
    if [ "$(id -u)" -eq 0 ]; then printf 'root\n'
    elif ! have sudo; then printf 'none\n'
    elif sudo -n true 2>/dev/null; then printf 'nopasswd\n'
    else printf 'interactive\n'; fi
}

vp_bin_path() {
    # vp 二进制显式路径探测（非登录 shell 的 PATH 看不到它；两种官方布局都认——对齐 WDC 工单12）
    local d
    for d in "$HOME/.vite-plus/bin/vp" "$HOME/.local/share/vite-plus/bin/vp"; do
        if [ -x "$d" ]; then printf '%s\n' "$d"; return 0; fi
    done
    return 1
}

vp_env_script() {
    # vp env 脚本路径探测（安装器布局随版本变动，逐个尝试——对齐 WDC 工单12）：
    # 首个在位者输出路径并返回 0；全缺返回 1。install-user-tools 据此写机器事实文件 env.sh（ADR-0015）
    local d
    for d in "$HOME/.config/vite-plus/env" "$HOME/.local/share/vite-plus/env.sh" \
             "$HOME/.local/share/vite-plus/env" "$HOME/.vite-plus/env"; do
        [ -f "$d" ] && { printf '%s\n' "$d"; return 0; }
    done
    return 1
}

node_available() {
    # node 可用性（效果级，ADR-0003 nvm/vp 共存）：PATH 直见，或经 vp env 脚本激活后可见
    # （布局探测单一来源 vp_env_script），或 nvm 目录在位
    command -v node >/dev/null 2>&1 && return 0
    local e
    if e=$(vp_env_script); then
        # shellcheck disable=SC1090
        . "$e" >/dev/null 2>&1 || true
        command -v node >/dev/null 2>&1 && return 0
    fi
    ls "$HOME"/.nvm/versions/node/*/bin/node >/dev/null 2>&1
}

version_matches() {
    # version_matches <命令输出> <期望版本> —— 语义化包含匹配，且避免 1.3.0 误配 11.3.0
    printf '%s' "$1" | grep -qE "(^|[^0-9.])$2([^0-9.]|$)"
}

bashrc_local_extract() {
    # bashrc_local_extract <bashrc 文件> —— 抽取机器自留地段（ADR-0003 迁移机制）：
    # 全部标记块（# >>> ... >>> .. # <<< ... <<<，含端点）与 nvm 块（export NVM_DIR= 起三行），
    # 段间补空行。install-dotfiles 与 validate 自测共用（单一来源）
    awk '
        BEGIN { first = 1 }
        function seg() { if (!first) print ""; first = 0 }
        /^#[[:space:]]*>>>/ { seg(); inblk = 1; print; next }
        /^#[[:space:]]*<<</ { if (inblk) { print; inblk = 0 }; next }
        inblk { print; next }
        /^export NVM_DIR=/ { seg(); nvm = 3 }
        nvm > 0 { print; nvm--; next }
    ' "$1"
}

# --- dotfiles 渲染模型（ADR-0015）：落点映射与状态判定（安装/断言/预演/分流/快照五方共读） ---

dotfiles_map() {
    # 落点映射单一来源：显示名|仓库模板相对路径|机器落点（$HOME 起）|生效门|模式
    # 门=always 恒适用 / desktop 仅桌面栈机器（ADR-0008）；模式=render 渲染拷贝 / link 符号链接（仅 CLI 入口）
    # 新增 dotfile 只改这里，安装面与断言面自动同步（对齐 WDC dotfiles-map.ps1）
    cat <<'MAP'
~/.bashrc|dotfiles/linux/bashrc|.bashrc|always|render
~/.gitconfig|dotfiles/linux/gitconfig|.gitconfig|always|render
~/.config/starship.toml|dotfiles/shared/starship.toml|.config/starship.toml|always|render
~/.local/bin/ldc|ldc|.local/bin/ldc|always|link
VSCode settings.json|dotfiles/linux/vscode-settings.json|.config/Code/User/settings.json|desktop|render
VSCode keybindings.json|dotfiles/linux/vscode-keybindings.json|.config/Code/User/keybindings.json|desktop|render
MAP
}

dotfiles_map_entries() {
    # 按机器形态过滤后的落点映射（调用方逐行 IFS='|' read -r 名 模板 落点 门 模式）
    local name tmpl target gate mode
    while IFS='|' read -r name tmpl target gate mode; do
        case $gate in
            always) printf '%s|%s|%s|%s|%s\n' "$name" "$tmpl" "$target" "$gate" "$mode" ;;
            desktop) desktop_stack_present && printf '%s|%s|%s|%s|%s\n' "$name" "$tmpl" "$target" "$gate" "$mode" ;;
        esac
    done < <(dotfiles_map)
}

dotfiles_entry_state() {
    # dotfiles_entry_state <模板绝对路径> <落点绝对路径> <mode> —— 落点状态：ok|absent|drift
    # render：实体文件与模板 cmp 一致=ok / 缺失=absent / 符号链接残形（旧安装形态、外来链接）=drift / 内容不符=drift
    # link：指向模板的符号链接=ok / 其余已存在=drift / 缺失=absent
    local src=$1 dst=$2 mode=$3
    if [ "$mode" = link ]; then
        if [ -L "$dst" ]; then
            [ "$(readlink "$dst")" = "$src" ] && printf 'ok\n' || printf 'drift\n'
            return 0
        fi
        [ -e "$dst" ] && printf 'drift\n' || printf 'absent\n'
        return 0
    fi
    [ -L "$dst" ] && { printf 'drift\n'; return 0; }
    [ -f "$dst" ] || { printf 'absent\n'; return 0; }
    cmp -s "$dst" "$src" && printf 'ok\n' || printf 'drift\n'
    return 0
}

content_hash() {
    # content_hash <文件> —— sha256 十六进制（渲染账本与方向判定的内容指纹）
    sha256sum "$1" 2>/dev/null | awk '{print $1}'
}

render_state_file() {
    # 渲染账本（ADR-0015 补注：漂移方向判定）——sha256sum 兼容格式「<hash>␣␣<落点绝对路径>」
    # 记录上次渲染时各落点的内容指纹。账本可丢：缺失/损坏时方向判定退化为 unknown（等同
    # ADR-0015 首版行为），下次渲染自愈重建。
    printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/ldc/rendered.sha256"
}

render_state_get() {
    # render_state_get <落点绝对路径> —— 上次渲染时的内容 hash（无记录返回 1）
    local f dst=$1
    f=$(render_state_file)
    [ -f "$f" ] || return 1
    # 路径自第 67 字符起（64 位 hash + 2 空格）；精确匹配避免前缀串扰
    awk -v d="$dst" 'substr($0, 67) == d { print substr($0, 1, 64); found = 1; exit }
                     END { exit !found }' "$f"
}

render_state_set() {
    # render_state_set <落点绝对路径> <hash> —— 单行更新（有则覆写无则追加；tmp+mv 原子落盘）
    local f dst=$1 hash=$2 tmp
    f=$(render_state_file)
    mkdir -p "$(dirname "$f")"
    tmp=$(mktemp "$(dirname "$f")/.rendered.XXXXXX")
    { [ -f "$f" ] && awk -v d="$dst" 'substr($0, 67) != d' "$f"; printf '%s  %s\n' "$hash" "$dst"; } > "$tmp"
    mv "$tmp" "$f"
}

drift_direction() {
    # drift_direction <模板绝对路径> <落点绝对路径> —— 漂移方向（ADR-0015 补注）：
    #   template-update 模板更新（落点自上次渲染未动——纯模板更新，重渲染无机器侧内容可失）
    #   machine         机器侧改动（模板自上次渲染未动）
    #   both            双向漂移（吸收会盖掉模板更新——需人工判读 diff 再定）
    #   unknown         无账本记录（账本丢失 / 首版升级机器）
    local src=$1 dst=$2 rec
    rec=$(render_state_get "$dst") || { printf 'unknown\n'; return 0; }
    if [ "$(content_hash "$dst")" = "$rec" ]; then printf 'template-update\n'; return 0; fi
    if [ "$(content_hash "$src")" = "$rec" ]; then printf 'machine\n'; else printf 'both\n'; fi
    return 0
}

git_identity_ok() {
    # 身份经 include 链生效（效果级，与 verify 断言同口径）；只判非空不取值——身份内容不进日志
    [ -n "$(git config --global --includes --get user.name 2>/dev/null)" ] && \
    [ -n "$(git config --global --includes --get user.email 2>/dev/null)" ]
}

root_stage_complete() {
    # root 阶段完成度（只读，供 ldc status / 汇总）：两清单全装 + gh 在位 + docker 在位
    # + 桌面应用清单（仅桌面栈机器 desktop_stack_present——安装面与断言面同口径，ADR-0008/0009）
    local pkg missing=0
    while read -r pkg; do
        dpkg -s "$pkg" >/dev/null 2>&1 || missing=$((missing + 1))
    done < <(pkg_list base-linux.pkg; pkg_list cli-tools.pkg)
    have gh || missing=$((missing + 1))
    if [ "${LDC_SKIP_DOCKER:-0}" != "1" ]; then
        have docker || missing=$((missing + 1))
        # daemon 声明键同属 root 阶段安装面（ADR-0009；docker 在位才要求）
        if have docker && ! docker_daemon_declared_ok; then
            missing=$((missing + 1))
        fi
    fi
    if desktop_stack_present; then
        while read -r pkg; do
            dpkg -s "$pkg" >/dev/null 2>&1 || missing=$((missing + 1))
        done < <(pkg_list desktop-apps.pkg)
    fi
    [ "$missing" -eq 0 ]
}

root_handoff_cmd() {
    # root 阶段交接命令（ADR-0004）单一来源：bootstrap/verify/install-packages 报错口径一致
    local repo=${1:-}
    [ -n "$repo" ] || repo=$(ldc_repo)
    printf 'cd %s && sudo bash scripts/install-packages.sh' "$repo"
}

desktop_session_reachable() {
    # D-Bus 会话探测（效果级证据，ADR-0005）：清单首条 key 读得到 = 有图形会话；否则 SSH/无桌面
    local first schema key
    first=$(grep -vE '^[[:space:]]*(#|$)' "$(ldc_repo)/configs/desktop.gsettings" 2>/dev/null | head -n1)
    [ -n "$first" ] || return 1
    read -r schema key _ <<<"$first"
    gsettings get "$schema" "$key" >/dev/null 2>&1
}

ldc_arch() {
    # uname -m → GitHub release 资产名用的架构段（amd64/arm64，ADR-0006 双架构一等公民）；
    # 全仓库唯一的架构判断点——新增二进制下载一律经此取资产段。不支持的架构返回 1。
    # 可选参数：传入 uname -m 形态的值供 validate 离线自测（缺省取本机实际架构）。
    local m=${1:-$(uname -m)}
    case $m in
        x86_64)         printf 'amd64\n' ;;
        aarch64|arm64)  printf 'arm64\n' ;;
        *) log "ERROR: 不支持的架构 $m（受支持：amd64/arm64，见 ADR-0006）"; return 1 ;;
    esac
}

run_stage() {
    # run_stage <标签> <脚本> [参数…] —— 转发输出、判退出码、按 step 口径报告；返回脚本退出码
    local label=$1 script=$2 rc=0
    shift 2
    bash "$script" "$@" || rc=$?
    if [ "$rc" -eq 0 ]; then step "$label" OK
    else step "$label" FAIL "退出码 $rc"; fi
    return "$rc"
}

latest_bootstrap_log() {
    # 最近一次 bootstrap 日志路径（无则返回 1）
    local latest
    latest=$(ls -1t "$(ldc_repo)/logs"/bootstrap-*.log 2>/dev/null | head -n1)
    [ -n "$latest" ] || return 1
    printf '%s\n' "$latest"
}

docker_daemon_declared_ok() {
    # daemon.json 是否已含全部声明键（ADR-0009 受保护合并的断言口径）：
    # target * declared == target ⟺ 声明的所有叶键在 target 中已同值（递归子集）
    local declared f=/etc/docker/daemon.json
    declared="$(ldc_repo)/configs/docker-daemon.json"
    [ -f "$f" ] || return 1
    jq -s -e '.[0] * .[1] == .[0]' "$f" "$declared" >/dev/null 2>&1
}
