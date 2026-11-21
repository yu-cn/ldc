#!/usr/bin/env bash
# exit-ldc.sh — LDC 退出执行体（ADR-0024；ldc exit 的执行体——对齐 WDC ADR-0010 同构语义）
# 两档：T2 完整退出（默认）= 声明面全退、数据面不动；T1（--keep-tools）= 只删 LDC 机器状态。
# 安全：默认打印全计划；非交互（非 tty）且无 --yes 自动降级为预演零变更——执行加 --yes。
# 红线（对齐 WDC）：共享资源不卸（libatomic1/fontconfig/curl/wget 等公共库与工具、NF 字体——
#   卸之伤及无关软件）；语言数据面不动（mise/uv 的 runtime/venv/cache、Docker 卷与镜像）；
#   可选包组（desktop-apps/media-doc）指名装的自管不在退出面；Docker 引擎打印指引不代跑。
set -uo pipefail
SELF="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$SELF/lib/common.sh"

DRY=1; KEEP_TOOLS=0
for a in "$@"; do
    case "$a" in
        --yes) DRY=0 ;;
        --keep-tools) KEEP_TOOLS=1 ;;
    esac
done

# 交互确认（有 tty 且未 --yes）；非 tty 且未 --yes = 预演
if [ "$DRY" -eq 0 ]; then :
elif [ -t 0 ]; then
    phase 'ldc exit · 退出计划（确认前先看全计划）'
    step '确认' INFO '档位与动作见下方计划；确认退出输入 yes，其他任意键取消'
    printf '确认退出？'
    read -r ans
    [ "$ans" = "yes" ] || { step '退出' OK '已取消——未做任何变更'; exit 0; }
    DRY=0
fi

# --- 计划与公共数据 ------------------------------------------------------------
CORE_PKGS=$(grep -h -v '^\s*#' "$SELF/../configs/base-linux.pkg" "$SELF/../configs/cli-tools.pkg" | grep . || true)
# 共享资源豁免（对齐 WDC VCRedist/字体原则：公共库与通用工具卸之伤及无关软件）
EXEMPT='libatomic1 fontconfig curl wget'
UNINST=""
for p in $CORE_PKGS; do
    case " $EXEMPT " in *" $p "*) continue ;; esac
    dpkg -s "$p" >/dev/null 2>&1 && UNINST="$UNINST $p"
done
BINARIES="$HOME/.local/bin/uv $HOME/.local/bin/uvx $HOME/.local/bin/mise $HOME/.local/bin/starship"

phase "ldc exit · $([ "$KEEP_TOOLS" -eq 1 ] && echo 'T1 状态退出（--keep-tools）' || echo 'T2 完整退出（默认）')$([ "$DRY" -eq 1 ] && echo ' · 预演（--yes 执行）')"
if [ "$KEEP_TOOLS" -eq 0 ]; then
    step 'apt 核心域卸载' INFO "${UNINST:-无在装}；豁免：$EXEMPT（共享资源）——需 root（免密 sudo 直跑，否则打印交接命令）"
    step 'gh apt 源文件' INFO '/etc/apt/sources.list.d/github-cli.list（root）'
    step '二进制卸载' INFO "uv/uvx/mise/starship（$HOME/.local/bin；mise 数据 $HOME/.local/share/mise 不动——数据面）"
    step 'dotfiles 落点处置' INFO '有 .bak 还原原文件（ADR-0015 同款）、无则删；ldc 链接删除（放最后——本命令正用它）'
    step '不碰' INFO '可选包组（desktop-apps/media-doc 自管）· Docker 引擎与卷/镜像（指引不代跑）· mise/uv 数据面 · NF 字体（共享）'
fi
step '状态删除' INFO "$HOME/.local/state/ldc/（渲染账本+收敛账本）+ $HOME/.ldc 指针 + $HOME/.local/bin/ldc 链接"
[ "$DRY" -eq 1 ] && { step '预演' OK '以上为计划预演，未做任何变更（CI/脚本执行加 --yes）'; exit 0; }

# --- 执行 ----------------------------------------------------------------------
FAILS=0
if [ "$KEEP_TOOLS" -eq 0 ]; then
    phase '退出 1/4 · apt 核心域卸载（root）'
    if [ -n "$UNINST" ]; then
        if [ "$(id -u)" -eq 0 ]; then
            apt-get remove -y --purge $UNINST >/dev/null 2>&1 && step 'apt remove' OK "已卸载：$UNINST" || { step 'apt remove' FAIL '见上'; FAILS=$((FAILS+1)); }
        elif sudo -n true >/dev/null 2>&1; then
            sudo -n apt-get remove -y --purge $UNINST >/dev/null 2>&1 && step 'apt remove' OK "已卸载：$UNINST" || { step 'apt remove' FAIL '见上'; FAILS=$((FAILS+1)); }
        else
            step 'apt remove' INFO "sudo 需密码——交接命令（root 跑完重跑本命令收尾）：sudo apt-get remove -y --purge$UNINST"
        fi
        GH_SRC=/etc/apt/sources.list.d/github-cli.list
        if [ -f "$GH_SRC" ]; then
            if [ "$(id -u)" -eq 0 ]; then rm -f "$GH_SRC"; step 'gh apt 源' OK '已删'
            elif sudo -n true >/dev/null 2>&1; then sudo -n rm -f "$GH_SRC"; step 'gh apt 源' OK '已删'
            else step 'gh apt 源' INFO "交接：sudo rm -f $GH_SRC"; fi
        fi
    else
        step 'apt 核心域' OK '无在装声明包'
    fi

    phase '退出 2/4 · 二进制卸载（user 级）'
    for b in $BINARIES; do
        [ -e "$b" ] && { rm -f "$b"; step "$(basename "$b")" OK '已删'; } || step "$(basename "$b")" OK '不在'
    done

    phase '退出 3/4 · dotfiles 落点处置'
    while IFS='|' read -r name _ target gate mode; do
        [ "$gate" = "always" ] || continue
        [ "$mode" = "link" ] && continue   # ldc 自身链接放最后
        t="$HOME/$target"
        if [ -f "$t" ] || [ -L "$t" ]; then
            if [ -f "$t.bak" ]; then
                mv -f "$t.bak" "$t" && rm -f "$t".bak.* && step "$name" OK '已还原 .bak 原文件（备份链清）'
            else
                rm -f "$t" && step "$name" OK '已删除（LDC 创建）'
            fi
        else
            step "$name" OK '本就不在'
        fi
    done < <(dotfiles_map_entries)
    step 'Docker 引擎' INFO '不代跑——指引：sudo apt-get remove docker-ce docker-ce-cli（卷/镜像数据保留于 /var/lib/docker）'
fi

phase '退出 4/4 · 状态删除'
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ldc"
[ -d "$STATE_DIR" ] && { rm -rf "$STATE_DIR"; step '状态目录' OK "已删 $STATE_DIR（渲染账本+收敛账本）"; } || step '状态目录' OK '本就不在'
[ -f "$HOME/.ldc" ] && { rm -f "$HOME/.ldc"; step "$HOME/.ldc 指针" OK '已删'; } || step "$HOME/.ldc 指针" OK '本就不在'
# ldc 自身符号链接最后删（本命令正经它调用）
[ -L "$HOME/.local/bin/ldc" ] && rm -f "$HOME/.local/bin/ldc"
step 'ldc 链接' OK '已删（仓库目录自行处置）'

phase '退出汇总'
if [ "$FAILS" -eq 0 ]; then
    step 'ldc exit' OK "完成——机器状态已清，$([ "$KEEP_TOOLS" -eq 1 ] && echo '环境原样' || echo '声明面已退')；仓库 clone 自行处置"
    exit 0
else
    step 'ldc exit' FAIL "有 $FAILS 项失败——重跑幂等收尾"
    exit 1
fi
