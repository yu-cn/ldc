#!/usr/bin/env bash
# apply-desktop.sh — GNOME 桌面域（ADR-0005：按需启用）：按 configs/desktop.gsettings 逐条应用
# 无图形会话（SSH / 无桌面机器）时优雅 SKIP 并提示重跑时机
# 退出码：0 = 已应用或全部一致；2 = 无会话 SKIP（bootstrap 记为待办）；1 = 有失败
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"

manifest="$ROOT/configs/desktop.gsettings"
[ -f "$manifest" ] || { log "ERROR: 缺 $manifest"; exit 1; }
entries=$(grep -vE '^[[:space:]]*(#|$)' "$manifest")
[ -n "$entries" ] || { log "ERROR: $manifest 无有效条目"; exit 1; }

# 会话探测（效果级证据，见 common.sh desktop_session_reachable）
if ! desktop_session_reachable; then
    step '桌面域' SKIP '无图形会话（gsettings 不可达）——登录 GNOME 桌面后重跑 bootstrap 应用'
    exit 2
fi

fail=0
applied=0
while read -r schema key value; do
    [ -z "${schema:-}" ] && continue
    current=$(gsettings get "$schema" "$key" 2>/dev/null) || { step "$schema $key" FAIL '读取失败'; fail=$((fail + 1)); continue; }
    if [ "$current" = "$value" ]; then
        step "$schema $key" OK '一致'
    elif gsettings set "$schema" "$key" "$value"; then
        step "$schema $key" CHANGED "$current → $value"
        applied=$((applied + 1))
    else
        step "$schema $key" FAIL "设置 $value 失败"
        fail=$((fail + 1))
    fi
done <<<"$entries"

if [ "$fail" -gt 0 ]; then
    step '桌面域' FAIL "$fail 项失败"
    exit 1
fi
step '桌面域' OK "全部一致/已应用（本轮应用 $applied 项）"
exit 0
