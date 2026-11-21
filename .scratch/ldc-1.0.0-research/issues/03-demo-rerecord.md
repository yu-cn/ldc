# 03 demo 重录——三段 `ldc` / `ldc plan` / `ldc exit` 预演

Status: ready-for-agent
Type: task

## 定夺

grilling R1 Q5c + R2 Q3：重录，三段对齐 WDC 终版叙事（快照 / plan / exit 预演），verify 段出镜让位——断言已有 CI badge 与 README 边界段背书，exit 上 demo 才是 1.0.0 完整退出承诺面的宣告。

## 内容

1. `docs/demo.cast` 重录：三段 `ldc`（快照）/ `ldc plan`（干跑预演）/ `ldc exit`（预演口径——非 tty 自动降级预演，零变更安全，录制环境天然落在预演档）
2. agg 转 `docs/demo.gif`（README 嵌播位 caption 同步三段口径）
3. 帧级自检：中文清晰、无腰斩、提示符与配色观感与现版一致（对齐 WDC f53fe1f 终版的验证纪律）

## 验收

- [ ] demo.cast / demo.gif 落地，README caption 与三段实际内容一致
- [ ] 预演段确认零变更（录制后 `bash scripts/verify-machine.sh --quick` 仍全绿）

## Comments

- 2026-11-22 开票（grilling 收口批）。上一版 9124d93（2026-11-01，vp→mise 换轨后三段 `ldc`/`ldc plan`/`ldc verify --quick`）
