# Spec：2026-11-07 wdc 侧变化对照吸收批

## 背景

主人要求对照 wdc 侧（2026-11-01～07，约 30 笔提交）找 LDC 可参考项。逐项过滤后两项吸收，其余定夺不动：上游检查退役定性 LDC 同日已完成（ADR-0014 补记，8d60b34）、changelog §6 release notes 纪律本就 LDC 主笔已有、三 shell 最优化批只动 dotfiles/windows/（不涉冻结的 wsl 面，其「交互守卫防 agent 会话税」洞察 LDC 侧 bashrc:8 非交互整文件 early return 更彻底）、wdc upgrade-git 为 Git for Windows 专属、wdc 工单45（LETH inventory 反向吸收欠账）明示须 LETH 会话执行而本机是 ASUS——扫到即跳过。

## 范围（两张票，02 需先写 ADR——新决策先 ADR 再代码）

1. **dotfiles 备份轮转上限 3 份**（工单01，ADR-0015 补记）：install-dotfiles.sh render() 备份分支后置轮转清理——`.bak` 本体永不清、编号系列 ≤2、删 mtime 最老逐项报告（wdc 工单44 同语义同日联动，主人 2026-11-07 定夺）
2. **收敛账本快速路径**（工单02，ADR-0021）：bootstrap 达终态尾部记账 HEAD（含形态级终态条款——待办恰为 {非桌面机器的桌面域 SKIP}）+ `ldc sync` 快速路径（账本==HEAD 且干净 → 跳过 bootstrap 仅 quick 断言）+ `--full` 强制全量（wdc 工单42 同构）

## 已评估并否决的替代

见 ADR-0021「拒绝的替代」（仅 exit 0 记账 / 改 apply-desktop 退出码 / 声明指纹 / 时间阈值）；工单01 无行为决策反转（ADR-0015 补记口径），无需新 ADR。
