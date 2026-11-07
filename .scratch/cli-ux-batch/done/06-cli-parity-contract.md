# 工单06：docs/cli-parity.md 契约（主作者位本仓）+ guard 挂载 + validate 断言

Status: done

## 背景

双仓 CLI 体验对齐靠人肉对账（子命令表/退出码/-h 语义/--json/补全口径），漂移无机械守护。
dev-standard-guard 已有同源文件周检机制——契约挂同一循环零新流程。主作者位本仓
（dev-standard 同款模式：改先本仓提交，wdc 同批拷贝）。

## 内容

- 新建 `docs/cli-parity.md`：双仓命令表（含旗标与退出码）、共用 UX 约定清单
  （裸命令只读快照 / 打错建议 / -h 语义 / JSON 出口 / BEL / 补全单一来源）、治理段
  （主作者位、guard 周检、validate 自侧断言）
- 内嵌机器可读注释行：`<!-- wdc-commands: … -->`、`<!-- ldc-commands: … -->`
- dev-standard-guard.yml 同源比对循环加 `docs/cli-parity.md`
- validate.sh 加一档断言：解析 `ldc` 的 `LDC_COMMANDS` 行 vs 契约注释行——不一致 FAIL
  （把「改实现忘改契约」从周检提前到提交时）

## 验收清单

- [ ] guard 等价演练：与 wdc 拷贝 diff 为空（wdc 工单07 同批落地后）
- [ ] validate 断言：临时删词 → FAIL；还原 → OK
- [ ] validate 全绿

## 实录

- 负测实录：契约删 sync 词 → validate FAIL（实现≠契约清晰报差）；还原 → 全绿
- guard 挂载：dev-standard-guard.yml 循环纳入 docs/cli-parity.md；wdc 侧拷贝随 wdc 工单07 同批（diff 归零验证在 wdc 侧收口时补锚点）
- validate 全绿（提交 d4eb5fc）
