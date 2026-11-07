# ADR-0019：Docker 安装面收编厂商 apt 源（退役 get.docker.com 管道脚本）

- 日期：2026-11-07
- 状态：已接受（2026-11-07 优化批定夺，工单 optimize-batch 01）

## 背景

2026-11-07 全仓优化审查提出：`install-packages.sh` 的 Docker 安装是全仓最后一个「curl | sh 管道执行网络代码」面（get.sh 的信任模型自己都把这类面标为需审阅）。同时仓内已有成熟范式——gh / VSCode / Chrome 均走 `add_vendor_repo`（keyring + sources.list.d + apt 事务），且 `audit-machine.sh` 的特殊安装面清单本就按 `docker-ce / containerd.io / …` 包名记账——这些包名正是 download.docker.com apt 源的产物（get.docker.com 底层配的就是这个源）。安装方式与记账口径错位。

## 决策

Docker 安装面收编厂商 apt 源配方，与 gh 同款：

- `add_vendor_repo docker.gpg https://download.docker.com/linux/<ubuntu|debian>/gpg docker.list 'deb [arch=<arch> signed-by=…] https://download.docker.com/linux/<distro> <VERSION_CODENAME> stable'`——distro / codename 直取 `/etc/os-release`（预检已限死 ubuntu/debian，映射面小且确定）
- `apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`
- marker 判重（`download\.docker\.com/linux/(ubuntu|debian)`）：get.docker.com 装过的机器（其源与 keyring 已在位，含 deb822 形态）幂等直入安装段，无需迁移动作
- **版本不钉**：与 gh 同口径——apt 事务与 dpkg 账本即记账（红线 11：用 apt 已有的能力，不重写）

`docker_skipped` 跳过语义、daemon.json 受保护合并（ADR-0009）、docker 组免 sudo 均不变。

## 取舍

- get.docker.com 能处理更多发行版形态——但 LDC 预检只放行 ubuntu/debian，codename 直取即可；Ubuntu interim 发行版 docker 源偶有数日滞后，届时本步 FAIL 带指引（查 docs.docker.com 支持矩阵），确定性优先、不静默降级。
- 不主动清理 / 改写存量机器上 get.docker.com 写下的源形态——marker 命中即复用，装没装由 `have docker` 判定，无谓惊动机器。

## 拒绝的替代

- 维持 get.docker.com：少几行代码，但保留网络管道执行面、无声明源可审计，与「声明-收敛-断言」定位不符。
- 发行版包 docker.io：版本旧、无 buildx / compose 插件拆分包，且与既有机器的 docker-ce 系共存会造出双引擎。
- 给 docker-ce 加版本钉（ADR-0011 同款）：重复造 apt 已有的账本能力（红线 11）。

## 统筹

WDC 委托契约不动（install-packages.sh 入口参数 / 退出码 / 独立可跑性不变）；本决策为 LDC 辖区内安装面变更，WDC 侧无需动作。
