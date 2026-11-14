# 13: wsl.conf 管理权回 WDC——机器形态段瘦身为两件（联动 WDC ADR-0008）

**What to build:** 主人 2026-11-14 定夺「WSL 配置归 WDC」（按「配置属于谁」而非「文件在哪个文件系统」划界）——`/etc/wsl.conf` 读者是 WSL 平台而非发行版内工具，整文件管理权归 WDC 单一实现（其 setup-ubuntu.sh root 阶段保护合并，ADR-0021 修订 ADR-0007 补记 2026-11-01 的②）。本单承接本仓瘦身：

- ① `install-packages.sh` 机器形态段去 wsl.conf systemd 写入块，段标题同步（默认 shell + docker 组两件留任）
- ② `verify-machine.sh`「systemd 生效」断言保留（Docker 域依赖，断效果不断实现）——收敛路径文案改指 WDC（wsl.conf 写入归 wdc bootstrap）；phase 头注释同步
- ③ ADR-0021 新增 + ADR-0007 追补记（2026-11-14）
- ④ CHANGELOG [Unreleased] 记账

fresh-machine 时序不变：WDC root 阶段在委托本仓 install-packages.sh 之前写 wsl.conf，`docker_skipped()` 无 systemd 中间态自跳口径不变。

**Blocked by:** None

**Status:** open

- [ ] ① install-packages.sh 机器形态段瘦身
- [ ] ② verify-machine.sh 断言文案与注释同步
- [ ] ③ ADR-0021 + ADR-0007 补记
- [ ] ④ CHANGELOG 记账
- [ ] validate.sh 全绿 + 本机 verify --quick 全绿
- [ ] 联动 WDC 侧（ADR-0008/工单）同日收口后双仓迁移验收

## Comments
