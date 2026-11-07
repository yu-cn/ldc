# 工单02：收敛账本快速路径——已收敛且声明未变时 ldc sync 跳过 bootstrap

Status: done

## 背景

`ldc sync` 每次全量跑 bootstrap 七阶段 + verify 全量，日常收敛大部分是幂等 SKIP 的重复劳动。wdc 工单42 同构落地（真机 417s→秒级），主人定夺吸收（ADR-0021 先行）。LDC 特有交叉点：非桌面机器（WSL/headless/容器）bootstrap 常态 exit 2（桌面域形态级 SKIP）——照搬「仅 exit 0 记账」会让快速路径在 ADR-0007 委托主场景永不生效，故终态口径加形态级终态条款（对齐委托方 WDC setup-ubuntu.sh 的严格容忍分支：todos 恰为 {desktop} 即视为完成）。

## 内容

- common.sh：`converged_ledger_file/get/set/record`（`~/.local/state/ldc/converged`，两行纯文本 sha+时刻，tmp+mv 原子落盘；get 行 1 经 40 位 hex 严格校验）
- bootstrap.sh：达终态尾部记账 HEAD——exit 0 路径，或 exit 2 且待办恰为 {形态级桌面 SKIP}（`desktop_stack_present` 为假）；exit 码与 `[LDC_TODO=desktop]` 标记照常输出（ADR-0007 契约零变化）；记账行置于判定行之前（`ldc status` 抓「最后一条 [状态] 行」口径不变）
- ldc sync：账本 commit==HEAD 且工作区干净（脏树守卫——未提交声明编辑不改 HEAD，只判账本会漏）→ 跳过 bootstrap 仅 verify --quick；`--full` 强制全量；quick 未过 FAIL 指路 --full
- help/usage/README 文案同步；CHANGELOG [Unreleased] 记账

## 验收清单

- [x] validate 全绿（shellcheck）
- [x] 账本三态演练：正常记账/损坏回退/缺失回退/非 hex 回退
- [x] sync 四态演练：命中（SKIP+quick 绿）/ 账本损坏（全量）/ 脏树（全量）/ --full（全量）
- [x] 真机端到端：bootstrap exit 2（WSL 形态级）后账本在位 → ldc sync 走快速路径
- [x] WDC 委托契约不动（bootstrap.sh 入口参数/退出码/独立可跑不变）

## 实录

- 账本四态：set/get 往返、两行形态、损坏/缺失/40 位非 hex 全部正确回退（rc 1）；record 落当前 HEAD。DRILL PASS。
- 真机端到端（ASUS/WSL，提交后干净树）：`bash bootstrap.sh` exit 2（形态级）+ 收敛账本记 74a53ad（记账行先于 PENDING 判定行，status 抓取口径不破）；`ldc sync` 命中快速路径（SKIP bootstrap → verify --quick 全绿 → exit 0，亚秒级；本机已收敛态 bootstrap 仅 3s，快速路径收益主要在新机首收敛后的日常面与免全量 verify）。
- sync 五态（clone 演练，origin 指本地路径避开真仓未推送领先）：命中/账本损坏（全量+重记）/脏树（全量）/--full（全量）/未知参数（exit 1 拒绝）。意外收获：clone 场景 `~/.local/bin/ldc` 链接与 hooksPath 两项断言 FAIL 被 quick 兜住——实证「快速路径是免重跑不是免断言」的 fail-safe 链。演练后指针/链接已还原，verify --quick 全绿复核。
- 提交 74a53ad（validate 随 pre-commit 与自查双跑全绿）。
