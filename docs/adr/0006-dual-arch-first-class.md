# 双架构一等公民：amd64 / arm64

用户常用机器横跨两种架构：物理机/服务器以 amd64 为主，DGX Spark 等新机器为 arm64；WDC 实测过的 WSL Ubuntu 亦属 amd64 Linux。定为**双架构一等公民**，而非「arm64 上碰巧能跑」：

- **单点映射**：`ldc_arch()`（common.sh）是全仓库唯一的架构判断点，`uname -m` → GitHub 资产名（x86_64→amd64、aarch64/arm64→arm64），不受支持的架构返回非零。新增任何按架构选资产的下载必须经它，禁止散落 `uname -m` 判断。
- **三道验证面**：bootstrap 预检架构门禁（不支持的架构在第一步就 FAIL，而不是等到 lazygit 下载中途炸）；verify 断言「架构受支持」；validate 内置映射离线自测（x86_64/aarch64/arm64 各归其位、riscv64 拒绝）。
- **CI 双架构冒烟矩阵**：fresh-container 在 amd64 与 arm64（`ubuntu-24.04-arm`，公开仓库免费）两条 runner 上各跑一遍 root 全量 bootstrap + verify——资产 URL、安装器自探测在两种架构上都真实过一遍。

其余工具面天然架构无关：uv/vp/starship 官方安装器与 gh apt 源（`dpkg --print-architecture`）、get.docker.com 均自探测；字体 zip 与 apt 包名架构无关。WSL Ubuntu 作为 amd64 目标可直接跑 LDC，但**一个发行版只归一个管理器**——WDC 管的 WSL 侧继续归 WDC（见 ADR-0001）；无 systemd 的 WSL 里 docker 装得上起不来，此类机器用 `LDC_SKIP_DOCKER=1`。拒绝的替代：仅按首机锁 arm64（用户的 amd64 机器立即受害）；「尽力支持一切架构」（无 CI 验证面的空头承诺）；按架构写分支脚本（单点映射已足够，分支只会漂移）。
