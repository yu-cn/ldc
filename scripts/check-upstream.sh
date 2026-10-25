#!/usr/bin/env bash
# check-upstream.sh — 上游吸收机制的事实收集器（ADR-0014；对齐 wdc scripts/check-upstream.ps1 修复后形态）
# 做什么：拉取上游 wsl-comfort 的 apt 清单真源（comfort-shell-bootstrap.sh 顶部 COMFORT_APT_* 数组，
#         按数组名结构化提取——不做全文件正则，wdc 9d1dc3b 的噪声坑不重踩），
#         与 docs/upstream-baseline.json 基线对比，输出「上游新增 / 我方已有等价物」。
#         只陈述事实，不改任何配置；移植决策归环境主人，吸收后在 docs/upstream-ledger.md 记一笔。
# 引擎包目录（winget/Windows 侧）不在本脚本对标面——那归 wdc 对标（ADR-0014）。
# 用法：
#   bash scripts/check-upstream.sh                  # 对比基线出报告
#   bash scripts/check-upstream.sh -UpdateBaseline  # 确认无遗漏后固化当前上游状态为新基线
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"

REPO=microsoft/WindowsDeveloperConfig
RAW="https://raw.githubusercontent.com/$REPO/main"
BASELINE="$ROOT/docs/upstream-baseline.json"
UPDATE=0
[ "${1:-}" = "-UpdateBaseline" ] && UPDATE=1

for dep in curl jq; do
    if ! have "$dep"; then
        step "$dep" FAIL "前置依赖缺失：sudo apt install -y $dep"
        exit 1
    fi
done

# --- 1) 上游 HEAD ---
head_sha=$(curl -fsS "https://api.github.com/repos/$REPO/commits/main" | jq -r '.sha') \
    || { step '上游 HEAD' FAIL 'GitHub API 不可达'; exit 1; }
step '上游 HEAD' INFO "${head_sha:0:10}"

# --- 2) wsl-comfort apt 数组真源（结构化提取） ---
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
if ! curl -fsS "$RAW/src/wsl-comfort/comfort-shell-bootstrap.sh" -o "$tmp"; then
    step '上游清单' FAIL 'raw.githubusercontent 不可达'
    exit 1
fi
upstream=$(awk '
    # REQUIRED 是多行数组（闭括号独占一行）；OPTIONAL 是单行数组——两种形态分开截取，
    # sed 范围式提取对单行数组会把范围吸到文件尾（2026-10-25 实录 1023 个包的教训）
    /^readonly COMFORT_APT_REQUIRED=\(/,/^\)/ {
        sub(/^readonly COMFORT_APT_REQUIRED=\(/, ""); sub(/\).*/, ""); sub(/#.*/, ""); print
    }
    /^readonly COMFORT_APT_OPTIONAL=\(/ {
        sub(/^readonly COMFORT_APT_OPTIONAL=\(/, ""); sub(/\).*/, ""); sub(/#.*/, ""); print
    }' "$tmp" | tr ' ' '\n' | sed '/^$/d' | sort -u)
count=$(printf '%s\n' "$upstream" | grep -c . || true)
step '上游 apt 清单' INFO "COMFORT_APT_REQUIRED + OPTIONAL：$count 个包"

# --- 3) 我方声明（configs/*.pkg 全部清单：通用核心 + 可选包组，ADR-0010） ---
ours=$(cat "$ROOT"/configs/*.pkg 2>/dev/null | sed -e 's/#.*//' | awk 'NF' | sort -u)

# --- 4) 与基线对比 / 或写基线 ---
if [ "$UPDATE" -eq 1 ] || [ ! -f "$BASELINE" ]; then
    jq -n --arg head "$head_sha" --arg date "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --argjson apt "$(printf '%s\n' "$upstream" | jq -R '.' | jq -s '.')" \
        '{head: $head, date: $date, apt: $apt}' > "$BASELINE"
    step '基线' CHANGED "已固化 $count 个包到 docs/upstream-baseline.json"
    [ "$UPDATE" -eq 1 ] && exit 0
fi

base_apt=$(jq -r '.apt[]' "$BASELINE" 2>/dev/null | sort -u)
if [ -z "$base_apt" ]; then
    step '基线' FAIL "基线不可读或缺 apt 维度——删 $BASELINE 重跑以重建"
    exit 1
fi

phase '上游差异报告（基线 -> 现在）'
new_ids=$(comm -23 <(printf '%s\n' "$upstream") <(printf '%s\n' "$base_apt"))
gone_ids=$(comm -13 <(printf '%s\n' "$upstream") <(printf '%s\n' "$base_apt"))
if [ -z "$new_ids" ] && [ -z "$gone_ids" ]; then
    step '包差异' OK '无变化（上游与基线一致）'
else
    while IFS= read -r p; do
        [ -z "$p" ] && continue
        if printf '%s\n' "$ours" | grep -qx "$p"; then
            step "新增 $p" INFO '我们已有等价声明'
        else
            step "新增 $p" INFO '我们尚无——评估是否值得吸收'
        fi
    done <<<"$new_ids"
    while IFS= read -r p; do
        [ -z "$p" ] && continue
        step "移除 $p" INFO '上游已删（若我们从未吸收则无影响）'
    done <<<"$gone_ids"
fi
phase '吸收提醒'
step '下一步' INFO '若决定移植某项：改 configs/ 后在 docs/upstream-ledger.md 记一笔（日期+条目+上游链接），再跑本脚本 -UpdateBaseline 固化新基线'
exit 0
