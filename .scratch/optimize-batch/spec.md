# Spec：2026-11-07 全仓优化批

## 背景

主人问「ldc 还有什么可优化的地方吗」——实施会话通读全部脚本（约 2500 行 shell）、CI、ADR 与工单面后给出审查清单，主人定夺「全都做」。清单与红线/ADR 对照自查过：不碰包管理重写（红线 11）、不动可选包组断言面（ADR-0010）、不动委托契约（ADR-0007 入口参数/退出码/独立可跑性不变）。

## 范围（五张票，01/02 需先写 ADR——新决策先 ADR 再代码）

1. **docker 官方 apt 源**（ADR-0019）：get.docker.com 管道脚本退役，收编 add_vendor_repo 厂商源配方
2. **钉子治理**（ADR-0020）：pin-freshness 周巡检 workflow（只提醒不升级、恒 exit 0）+ validate sha256 行必配 + 补 starship-version 入检
3. **钉子安装器单一来源**：四段同构拷贝收编 common.sh `pinned_tarball_install` + tmp 登记/trap 清理
4. **合批与 fast-path**：pkg_install 单次 apt 事务 + VSCode 扩展差集安装
5. **CLI 体验与测试面**：ldc fetch 超时/失败中止 + 钉版形态（detached HEAD）口径 + get.sh 复用路径重钉 + 日志轮转 + CI debian:12 腿

## 已评估并否决的替代

见各 ADR「拒绝的替代」节；非决策项（3/4/5）为内部重构与体验收口，无需 ADR（无行为决策反转）。
