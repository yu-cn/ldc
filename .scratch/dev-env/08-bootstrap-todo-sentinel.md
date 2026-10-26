# 工单 08 — bootstrap exit 2 待办机器标记（LDC_TODO，委托契约机器化）

**背景**：委托契约的 exit 2 分类长期靠 WDC `setup-ubuntu.sh` grep 本仓 bootstrap 的散文文案（「桌面域：登录」「root 阶段：cd」「git 身份：编辑」）——两仓间无守护的字符串契约：LDC 侧任何文案微调都会让 WDC 的容忍判定静默失效（两个方向都有害：真待办被吞成 rc=0，或桌面域待办误判为真问题）。2026-10-26 会话复核委托实现时识别（主人评估提问「WSL 部分协作是否合适」），主人批准按建议改造。决策与理由全文见 [ADR-0007 补记](../../docs/adr/0007-wdc-ldc-coordination.md)。

**内容**：

- bootstrap.sh：exit 2 待办明细行尾追加 `[LDC_TODO=tag]`（root-handoff / desktop / git-identity）；人类可读文案不变；头部退出码注释与 GLOSSARY「LDC_TODO」词条同步
- fresh-container.yml handoff job：断言 `LDC_TODO=root-handoff` 在位——生产侧活测试，防契约标记静默漂移
- CHANGELOG [Unreleased] 记 Changed 一条
- WDC 侧消费改造：见 wdc 仓库 `.scratch/dev-env/issues/37-wsl-todo-sentinel.md`（跨仓按序：本单先行落地，WDC 侧随后）

**验收清单**：

- [x] `bash -n bootstrap.sh` 通过；待办文案仅行尾追加标记，无其他改动
- [x] ADR-0007 补记落档（契约字面量 + 严格容忍形态 + 同日双改规矩）
- [x] GLOSSARY「LDC_TODO」词条落档
- [x] fresh-container handoff job 含 LDC_TODO 断言（生产侧契约测试）
- [x] push 后 CI validate 全绿；手动触发 fresh-container 的 handoff job 验证 LDC_TODO 断言实跑通过（验证锚点回填本节）

## Comments

- 2026-10-26（ASUS 会话）：识别 + 实施。grep 全仓确认散文契约消费方仅 WDC setup-ubuntu.sh 一处（verify-ldc.sh 走退出码透传，无散文依赖）；本仓 CI（fresh-container handoff）本身已实跑 exit 2 路径，是断言新标记的天然位置。
- 2026-10-26（ASUS 会话）：CI 锚点——validate 绿 run 40339863144（00a0ea5）；fresh-container 全绿 run 40339885835（handoff 27s 含 `LDC_TODO=root-handoff` 断言实跑 + amd64/arm64 冒烟）。真机锚点——WSL Ubuntu 实跑 bootstrap exit 2 恰一条 `[LDC_TODO=desktop]`（root 已核销、身份已生效）；validate.sh 真 Linux 全绿（Windows Git Bash 的 ln FAIL 属 MSYS 环境限制）。WDC 消费侧切换见 wdc 工单37（be921c1，CI run 40341784763）。
