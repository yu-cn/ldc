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

# 桌面栈门禁（与安装/断言面同口径，ADR-0008）：WSLg/headless/容器不是桌面机器，整域跳过；
# 会话探测（效果级证据，见 common.sh desktop_session_reachable）只对真桌面机器有意义
if ! desktop_stack_present; then
    step '桌面域' SKIP '非桌面机器形态（headless/WSL/容器）'
    exit 2
fi
if ! desktop_session_reachable; then
    step '桌面域' SKIP '无图形会话（gsettings 不可达）——登录 GNOME 桌面后重跑 bootstrap 应用'
    exit 2
fi

fail=0
applied=0
skipped_schema=0
# schema 存在性清单（ADR-0005 补记）：发行版组件集不同（如 Debian 无 Ubuntu Dock），
# schema 不存在的行 SKIP 而非 FAIL——清单声明的是「有此组件则应为此值」
all_schemas=$({ gsettings list-schemas; gsettings list-relocatable-schemas; } | sort -u)
while read -r schema key value; do
    [ -z "${schema:-}" ] && continue
    if ! grep -qx "$schema" <<<"$all_schemas"; then
        step "$schema $key" SKIP '此发行版无此 schema（组件未装）'
        skipped_schema=$((skipped_schema + 1))
        continue
    fi
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
step '桌面域' OK "全部一致/已应用（本轮应用 $applied 项，$skipped_schema 项因发行版无此组件跳过）"
exit 0
