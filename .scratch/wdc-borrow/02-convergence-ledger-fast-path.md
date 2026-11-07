# 工单02：收敛账本快速路径——已收敛且声明未变时 ldc sync 跳过 bootstrap

Status: in-progress

## 背景

`ldc sync` 每次全量跑 bootstrap 七阶段 + verify 全量，日常收敛大部分是幂等 SKIP 的重复劳动。wdc 工单42 同构落地（真机 417s→秒级），主人定夺吸收（ADR-0021 先行）。LDC 特有交叉点：非桌面机器（WSL/headless/容器）bootstrap 常态 exit 2（桌面域形态级 SKIP）——照搬「仅 exit 0 记账」会让快速路径在 ADR-0007 委托主场景永不生效，故终态口径加形态级终态条款（对齐委托方 WDC setup-ubuntu.sh 的严格容忍分支：todos 恰为 {desktop} 即视为完成）。

## 内容

- common.sh：`converged_ledger_file/get/set/record`（`~/.local/state/ldc/converged`，两行纯文本 sha+时刻，tmp+mv 原子落盘；get 行 1 经 40 位 hex 严格校验）
- bootstrap.sh：达终态尾部记账 HEAD——exit 0 路径，或 exit 2 且待办恰为 {形态级桌面 SKIP}（`desktop_stack_present` 为假）；exit 码与 `[LDC_TODO=desktop]` 标记照常输出（ADR-0007 契约零变化）；记账行置于判定行之前（`ldc status` 抓「最后一条 [状态] 行」口径不变）
- ldc sync：账本 commit==HEAD 且工作区干净（脏树守卫——未提交声明编辑不改 HEAD，只判账本会漏）→ 跳过 bootstrap 仅 verify --quick；`--full` 强制全量；quick 未过 FAIL 指路 --full
- help/usage/README 文案同步；CHANGELOG [Unreleased] 记账

## 验收清单

- [ ] validate 全绿（shellcheck）
- [ ] 账本三态演练：正常记账/损坏回退/缺失回退
- [ ] sync 四态演练：命中（SKIP+quick）/ 账本不匹配（全量）/ 脏树（全量）/ --full（全量）
- [ ] 真机端到端：bootstrap exit 2（WSL 形态级）后账本在位 → ldc sync 走快速路径
- [ ] WDC 委托契约不动（bootstrap.sh 入口参数/退出码/独立可跑不变）

## 实录

（收口补）
