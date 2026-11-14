# wsl.conf 管理权回 WDC——WSL 平台配置集中

2026-11-14 主人定夺（起因：WDC 侧「.wslconfig 入声明」评审中追问 WSL 边界）：**WSL 平台/集成配置归 WDC**，按「配置属于谁」而非「文件落在哪个文件系统」划界。`/etc/wsl.conf` 的读者是 WSL 平台（wslservice/init），不是发行版内任何 Linux 工具——它与 Windows 侧的 `%USERPROFILE%\.wsl.conf` 同属一层。ADR-0007 的 2026-11-01 补记②（`wsl.conf` systemd=true 归本仓 install-packages.sh）随之退役。

## 决策

- **wsl.conf 整文件归 WDC 单一实现**（其 `setup-ubuntu.sh` root 阶段保护合并：`[boot]` systemd、`[user]` default 按机器事实写入；未管理段如本机的 `[network]` DNS 姿态保护不碰——WDC ADR-0008）。本仓 install-packages.sh「机器形态」段瘦身为两件：默认 shell + docker 组。
- **本仓保留「systemd 生效」效果断言**（`/run/systemd/system` 探测，is_wsl 门控）——Docker 域依赖 systemd，断效果不断实现（坑11 同精神）；收敛路径改指 WDC bootstrap。
- **时序不变**：WDC root 阶段在委托本仓 install-packages.sh **之前**写 wsl.conf——fresh-machine 语义照旧（写入 → `wsl --shutdown` 生效 → 重跑 bootstrap 补装 docker 域，`docker_skipped()` 无 systemd 中间态自跳的口径不变）。
- **平台纯度收益**：本仓对 WSL 的剩余依赖面只剩「要求 systemd 可用」（真机 Linux 天然满足）——is_wsl 写入面清零（verify 断言面的 is_wsl 门保留，断言语义本就 WSL 特有）。

## 取舍

当初移交（LDC 工单12 / ADR-0007 补记 2026-11-01）的动因是 WDC root 直调缺 SUDO_USER 的**实现便利**，非领域理由；`LDC_USER` 契约补齐后该障碍已不存在。若 2026-11-14 追问的 DNS 链入 LDC 通用核心（当时备选 a），`127.0.2.1` 上行之类 WSL 平台产物会反向长进本仓——主人否决，边缘案例反证了平台纯度的价值。

拒绝的替代：**继续由本仓写 wsl.conf**（单文件两主，WDC 管 `[network]`/`[user]`、本仓管 `[boot]`——INI 分段共管是漂移温床，保护合并语义两仓各造一份）；**双写过渡**（同键双写双断言，正是 ADR-0007 要消灭的双实现漂移）。
