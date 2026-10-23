# WDC↔LDC 统筹：WSL 委托 LDC

LDC 与 [WDC](https://github.com/yu-cn/WDC) 是同一主人的关联项目（本 ADR 取代 ADR-0001 中「WSL 复用属 YAGNI、WDC 独管 WSL」的立场——用户已明确要求统筹）。目标形态按**机器事实**而非「Windows 项目 / Linux 项目」划分职责：

- **WDC 保留**：Windows 侧全部 + WSL 生命周期（启用 WSL、安装发行版、`wsl.conf` systemd、默认用户）。
- **LDC 接管**：任何 Ubuntu/Debian 机器**内部**的一切收敛——包括 WDC 装出的 WSL Ubuntu（它本来就是一台 amd64 Linux，ADR-0006）。包、语言栈、dotfiles、验证全部走 LDC 单一实现，消灭 setup-ubuntu.sh 与 LDC 的双实现漂移（vp 钉子、bashrc/gitconfig 模板已是两份近似拷贝）。

**委托契约**（WDC 侧改造见 `.scratch/dev-env/03-wdc-wsl-delegation.md`）：

1. LDC 获取：WSL 内首次 `git clone https://github.com/yu-cn/LDC.git ~/dev/ldc`；已存在则等同 `ldc sync` 的仓库步（fetch + `pull --ff-only`，分叉中止交人工）。
2. root 委托：`wsl -d Ubuntu -u root -e bash ~/dev/ldc/scripts/install-packages.sh`——LDC 的 EUID=0 内联路径（ADR-0004），无需 sudo 交互。
3. user 委托：`wsl -d Ubuntu -e bash ~/dev/ldc/bootstrap.sh`——root 阶段已核销自动跳过；无 GNOME 会话桌面域自动 SKIP（ADR-0005）；无 systemd 的发行版 WDC 侧传 `LDC_SKIP_DOCKER=1`。
4. dotfiles：LDC `dotfiles/linux/` 接管 `~/.bashrc` 等落点（替换 WDC 指向 /mnt/c 的旧链接），WDC `dotfiles/wsl/` 随委托退役；机器段由 `.bashrc.local` / `.gitconfig.local` 承接（接管外来符号链接时 LDC 兜底创建空自留地）。
5. 验收：WDC 的 WSL 断言组替换为对 `verify-machine.sh --quick` 的委托调用；WSL 特有残留（默认 shell=bash 的 chsh 等）随委托迁入 LDC。

**演进统筹规则**：Linux 侧 shell/git/提示符模板的主作者位归 LDC（WDC 的 wsl 拷贝冻结至退役）；`configs/vp-version` 两仓库保持同值，升级同日双改、各自记账；WDC 的 upstream-ledger 与 LDC 的 .scratch 工单互引重大决策。拒绝的替代：抽第三个共享仓库供两方消费（为单人双仓库引入包管理复杂度，升级 vp 要跨三处）；保持双实现靠约定同步（正是要消灭的漂移源）；LDC 吞并 WDC 成单仓库双平台（ADR-0001 已否：验证面翻倍）。
