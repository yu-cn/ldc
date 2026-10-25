#!/usr/bin/env bash
# audit-machine.sh — 清单准入对账（只读，exit 恒 0；这是对账报告不是断言——核销语义在 verify）
# 两个方向（主人 2026-10-26 批准实装，定位讨论「LDC 是否在干包管理」遗留第 3 项）：
#   ① 自装未声明：apt-mark showmanual − 全部 .pkg 并集 − 特殊安装面 → 清单准入候选
#     （每台机器都要的就吸收进对应 .pkg；仅本机要的属机器自留，ADR-0003 判据）
#   ② 已声明未装：全部 .pkg 并集 − 已装 → root 交接待办 / 可选包组未装（install-packages.sh <组> 可补）
# 声明面含可选包组（audit 看全声明面）；desktop-apps 仅桌面栈机器计入（与 verify 同口径）
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"

# 特殊安装面：apt 装但不走 .pkg 清单的声明项（install-packages.sh 专项段：gh 官方源、Docker 官方脚本）
# ——它们有 verify 断言管，不算「自装未声明」
special='gh docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin'

declared=$(mktemp); prio=$(mktemp); cand=$(mktemp); raw=$(mktemp)
trap 'rm -f "$declared" "$prio" "$cand" "$raw"' EXIT

# 声明面（pkg 组名）：
for m in "$ROOT"/configs/*.pkg; do
    b="${m##*/}"; g="${b%.pkg}"
    if [ "$g" = desktop-apps ] && ! desktop_stack_present; then continue; fi
    while IFS= read -r pkg; do printf '%s %s\n' "$pkg" "$g"; done < <(pkg_list "$b")
done | sort > "$declared"
# 已装包的优先级表（噪声滤网用）：apt 系把 required/important 视为系统底座，
# 自装工具几乎都在 standard/optional——底座项不进「自装未声明」（经验滤网，误滤可走清单吸收）
dpkg-query -W -f='${Package}\t${Priority}\n' 2>/dev/null | sort > "$prio"

phase 'audit · 自装未声明（清单准入候选）'
comm -23 \
    <(apt-mark showmanual 2>/dev/null | sort -u) \
    <({ awk '{print $1}' "$declared"; for p in $special; do printf '%s\n' "$p"; done; } | sort -u) > "$raw"
while IFS= read -r pkg; do
    [ -n "$pkg" ] || continue
    p=$(awk -F'\t' -v k="$pkg" '$1==k {print $2; exit}' "$prio")
    { [ "$p" = required ] || [ "$p" = important ]; } && continue
    printf '%s\n' "$pkg"
done < "$raw" > "$cand"
cand_n=$(wc -l < "$cand")
if [ "$cand_n" -eq 0 ]; then
    step '自装未声明' OK '零项——机器自装面全部被声明面覆盖'
else
    step '自装未声明' INFO "$cand_n 项准入候选——吸收进 .pkg 或确认机器自留："
    sed 's/^/  /' "$cand"
fi

phase 'audit · 已声明未装'
miss_n=0
while IFS= read -r line; do
    pkg=${line%% *}; g=${line##* }
    [ -n "$pkg" ] || continue
    dpkg -s "$pkg" >/dev/null 2>&1 && continue
    if [ "$miss_n" -eq 0 ]; then
        step '已声明未装' INFO '收敛待办——root 交接或 sudo bash scripts/install-packages.sh <组>：'
    fi
    miss_n=$((miss_n + 1))
    printf '  %s（%s）\n' "$pkg" "$g"
done < <(awk '!seen[$1]++' "$declared")
[ "$miss_n" -eq 0 ] && step '已声明未装' OK '零项——声明面全部核销'

exit 0
