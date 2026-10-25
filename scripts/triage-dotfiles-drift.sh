#!/usr/bin/env bash
# shellcheck disable=SC2088  # 标签文案中的 ~/ 是显示约定不参与展开；真实路径展开一律用 $HOME
# triage-dotfiles-drift.sh — dotfiles 落点漂移分流（交互式；ADR-0015 渲染模型）
# 漂移 = 落点渲染物 ≠ 仓库模板（机器侧工具直改落点：VSCode / gh auth setup-git 等，仓库不受污染）。
# 逐文件给出处置入口（ADR-0003 判据：每台机器都该有的进模板，机器噪声还原）：
#   吸收(a) = 落点内容回写模板并显式路径暂存（稍后 commit；「禁 git add -A」红线不变）
#   还原(r) = 丢弃机器改动，自模板重渲染
#   跳过(d) = 留待下次
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"

drift_n=0
while IFS='|' read -r name tmpl target _gate mode; do
    [ "$(dotfiles_entry_state "$ROOT/$tmpl" "$HOME/$target" "$mode")" = drift ] && drift_n=$((drift_n + 1))
done < <(dotfiles_map_entries)

if [ "$drift_n" -eq 0 ]; then
    step 'dotfiles 漂移' OK '全部落点与模板一致'
    exit 0
fi
step 'dotfiles 漂移' FAIL "$drift_n 项落点与模板不一致"

if [ ! -t 0 ]; then
    log '非交互上下文——请人工处置（逐项）：吸收 = cp <落点> <模板> 后 git add <模板路径>；还原 = 重跑 bash bootstrap.sh（dotfiles 阶段）'
    exit 1
fi

while IFS='|' read -r name tmpl target _gate mode; do
    src="$ROOT/$tmpl"
    dst="$HOME/$target"
    [ "$(dotfiles_entry_state "$src" "$dst" "$mode")" = drift ] || continue
    echo
    echo "── $name（模板 $tmpl ↔ 落点 ~/$target）──"
    if [ "$mode" = link ]; then
        echo "预期符号链接 → $src"
        echo "实际：$(readlink "$dst" 2>/dev/null || { [ -e "$dst" ] && echo "实体文件（非链接）" || echo '缺失'; })"
    else
        diff -u --label "模板($tmpl)" --label "落点(~/$target)" "$src" "$dst" 2>&1 | head -n 40
    fi
    read -r -p "吸收进模板(a) / 还原为模板重渲染(r) / 跳过(d)？ " ans
    case $ans in
        a)
            if [ "$mode" = link ]; then
                step "$name" INFO '符号链接无内容可吸收——请用还原(r) 重链'
                continue
            fi
            if cp "$dst" "$src"; then
                if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 \
                   && git -C "$ROOT" add -- "$tmpl"; then
                    step "$name" CHANGED '已回写模板并显式暂存（吸收）——commit 用显式路径，勿 git add -A'
                else
                    step "$name" CHANGED '已回写模板（吸收）——仓库未 git init，未暂存'
                fi
            else
                step "$name" FAIL '回写模板失败'
            fi
            ;;
        r)
            if [ "$mode" = link ]; then
                if ln -sfn "$src" "$dst"; then
                    step "$name" CHANGED '已重链（还原）'
                else
                    step "$name" FAIL '重链失败'
                fi
            else
                if rm -f "$dst" && install -m 0644 "$src" "$dst"; then
                    step "$name" CHANGED '已自模板重渲染（还原——机器改动已丢弃）'
                else
                    step "$name" FAIL '重渲染失败'
                fi
            fi
            ;;
        *) step "$name" INFO '跳过（留待下次）' ;;
    esac
done < <(dotfiles_map_entries)
