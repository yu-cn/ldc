#!/usr/bin/env bash
# triage-dotfiles-drift.sh — dotfiles 写穿漂移分流（交互式）
# 写穿 = 机器侧工具经符号链接改了仓库内模板（WDC 侧 gh auth login 实锤的同款问题）。
# 逐文件给出处置入口（ADR-0003 判据：每台机器都该有的进模板，机器噪声还原）：
#   吸收(a) = git add 暂存（进模板，稍后 commit） / 还原(r) = 丢弃机器改动 / 跳过(d) = 留待下次
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"

if ! git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
    log 'ERROR: 仓库尚未 git init——无 HEAD 可比对'
    exit 1
fi
if ! git -C "$ROOT" rev-parse --verify HEAD >/dev/null 2>&1; then
    step 'dotfiles 漂移' INFO '仓库尚无 commit——无 HEAD 可比对（首次 commit 后生效）'
    exit 0
fi

mapfile -t drift < <(git -C "$ROOT" status --porcelain -- dotfiles)
if [ "${#drift[@]}" -eq 0 ]; then
    step 'dotfiles 漂移' OK '与 HEAD 一致'
    exit 0
fi
step 'dotfiles 漂移' FAIL "${#drift[@]} 项写穿"

if [ ! -t 0 ]; then
    log '非交互上下文——请人工处置：git add <file>（吸收）或 git checkout -- <file>（还原）'
    exit 1
fi

for line in "${drift[@]}"; do
    f=${line:3}
    echo
    echo "── $f ──"
    git -C "$ROOT" diff -- "$f" | head -n 40
    read -r -p "吸收进模板(a) / 还原为机器噪声(r) / 跳过(d)？ " ans
    case $ans in
        a) git -C "$ROOT" add -- "$f" && step "$f" CHANGED '已暂存（吸收）——稍后 commit' ;;
        r) git -C "$ROOT" checkout -- "$f" && step "$f" CHANGED '已还原（机器噪声丢弃）' ;;
        *) step "$f" INFO '跳过（留待下次）' ;;
    esac
done
