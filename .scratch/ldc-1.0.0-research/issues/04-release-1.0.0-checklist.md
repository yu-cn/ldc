# 04 v1.0.0 发布 checklist（门槛制——不达标不发；发布动作待主人 explicit 指令）

Status: open（等待工单 02/03 收口 + 主人汇合点定夺）
Type: task

## 门槛

- [ ] 工单 02/03 收口（内容批 + demo）
- [ ] fresh-container 四架构 dispatch 复跑绿（已绿是 e8fb90f 时点 run 44930860595；发布时点按新 HEAD 再实证）
- [ ] 本机终验：`ldc sync` → `bash scripts/verify-machine.sh --quick` 全绿（实机口径：单机本机 WSL Ubuntu；如报第二台实机补双机半场）
- [ ] （可选，主人窗口）本机全环回归：`ldc exit --yes` → bootstrap → verify 全绿——存量机降级路径终极实证（对应 WDC LETH 回归环；CI 已覆盖 fresh 半场）
- [ ] 文档一致终查：README / docs/undo-table.md / docs/upgrade-v1.md / ADR-0022/0023/0024 / cli-parity
- [ ] CHANGELOG 收节 v1.0.0（Unreleased → 版本节；compare 链续 v1.0.0...HEAD）
- [ ] release notes 效果优先：承诺面句置顶 / 存量机影响正面回答（链 docs/upgrade-v1.md）/ 叙事骨架五件展开 / 已知事项含 `LDC_TAG=v0.14.0` 钉版回退姿势
- [ ] 归档卫生：本批工单全归档

## 汇合点（两案备态——开跑前主人定夺；WDC 侧 checklist 门槛⑧已按 A 案铺路）

- **A 同号同日**：对齐 WDC 执行序——其③=本仓 CHANGELOG 收节 commit（WSL 内，LDC 会话做）→ ④ 双仓 tag v1.0.0 → ⑤ 双仓 release 同会话收口
- **B 随后独立发**：本仓自行 tag / release；WDC 侧门槛⑧由其会话改

## 发布执行序（主人指令后同会话）

① 门槛全勾 → ②（A 案）与 WDC 会话对表时点 /（B 案）径行 → ③ CHANGELOG 收节 commit → ④ tag v1.0.0 → ⑤ release（--latest，效果优先 notes）→ ⑥ 工单归档

## Comments

- 2026-11-22 开票（grilling 收口批；门槛结构对齐 WDC 04 同款）
