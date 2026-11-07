# 0021 — 收敛账本：已收敛且声明未变时 ldc sync 走快速路径

日期：2026-11-07 · 状态：已接受 · 联动：wdc 工单42 同构决策（主作者位 LDC）

## 背景（谁在什么场景问的）

主人 2026-11-07 对照 wdc 侧提交面定夺吸收两项，其一为 wdc 工单42 的收敛账本快速路径（真机 417s→秒级）。LDC 的 `ldc sync` 每次都全量跑 bootstrap 七阶段 + verify 全量，日常收敛里大部分是幂等 SKIP 的重复劳动。

## 决策

1. **收敛账本**：bootstrap 达终态的尾部把当前 HEAD 记入 `~/.local/state/ldc/converged`（两行纯文本：40 位 sha + ISO8601 时刻；tmp+mv 原子落盘，对齐渲染账本模式）。记账点在 bootstrap 本体——bootstrap 直跑与 ldc sync 两条路径同点记账，单一来源。与渲染账本（rendered.sha256 管「落点↔模板」指纹）同目录同模式各管各的：本账本管机器整体收敛事实。
2. **终态口径**：exit 0（全绿）；或待办集合恰为 {形态级桌面 SKIP}——`desktop_stack_present` 为假的机器（WSL/headless/容器）上「非桌面机器形态」的桌面域 SKIP 登录桌面重跑永不适用，是形态级 N/A 而非活待办，与委托方 WDC setup-ubuntu.sh 的严格容忍分支同款语义（todos 恰为 {desktop} 即视为完成）。真桌面机器无会话的 SKIP（SSH 上下文）是活待办，不记。
3. **exit 语义与契约不动**：exit 2 照常返回、待办明细与 `[LDC_TODO=desktop]` 标记照常输出（ADR-0007 契约面零变化）——账本只加一层「已达终态」的记账，不改任何判定与退出码。
4. **快速路径**：`ldc sync` 见「账本 commit == HEAD 且工作区干净」→ 跳过 bootstrap 仅 verify --quick（秒级）；quick 未过 FAIL 并指路 `ldc sync --full`（强制全量）。
5. **脏树守卫**：未提交的声明编辑不改 HEAD——只判账本会漏，`git status --porcelain` 非空一律全量。
6. **fail-safe**：账本缺失/损坏/首行非 40 位 hex/与 HEAD 不匹配一律回退全量——假账本会假绿，宁可慢不可假绿。账本可丢（机器本地状态，不入仓库，ADR-0004 模式），丢了下次全量后自愈。

## 取舍

- 快速路径只跑 quick 断言：已收敛机器的日常复核口径；全量断言走 `ldc sync --full` / `ldc verify --full`。
- 账本锚 HEAD 而非声明内容指纹：工作区干净时 HEAD 就是全部声明+实现的不可变锚点；脏树由守卫兜住，指纹是重复劳动。
- 陈旧账本（记账后机器状态又被人手改动）由 quick 断言兜底：漂移/身份/清单任一不过即 FAIL 指路全量——快速路径是「免重跑」不是「免断言」。

## WDC 条款（ADR-0007 统筹）

双仓同构决策、各自实现（对齐 wdc 工单42）。三要件双仓一致：非终态不记账、脏树守卫、损坏/不匹配回退全量。形态级终态条款（决策 2）是 LDC 侧扩展——WDC 形态无常态 exit 2 的桌面待办问题，且其委托 wrapper 已按同款容忍语义消化 LDC 的 desktop 待办，语义闭环。账本文件形态从宽（WDC converged.json / LDC converged 纯文本两行）——机器本地状态无契约面，不追齐。

## 拒绝的替代

- **仅 exit 0 记账（照搬 wdc 原样）**：WSL/headless 机器 bootstrap 常态 exit 2（桌面域形态级 SKIP），快速路径在 ADR-0007 委托主场景永不生效——背离 wdc 工单42 的收益初衷。
- **改 apply-desktop 退出码让 WSL 退 0**：动 `[LDC_TODO=desktop]` 标记的产生面——委托契约（ADR-0007）、WDC 侧容忍分支、fresh-container 断言全要跟着同日双改，收益与风险不成比。
- **按声明内容算指纹记账**：HEAD 干净时等价且更强，脏树另有守卫。
- **时间阈值降级**（距上次全量 <N 天则跳过）：与声明状态无关，声明改了也会被跳过——正中假绿。
