# WDC↔LDC 统筹：WSL 委托 LDC

LDC 与 [WDC](https://github.com/yu-cn/wdc) 是同一主人的关联项目（本 ADR 取代 ADR-0001 中「WSL 复用属 YAGNI、WDC 独管 WSL」的立场——用户已明确要求统筹）。目标形态按**机器事实**而非「Windows 项目 / Linux 项目」划分职责：

- **WDC 保留**：Windows 侧全部 + WSL 生命周期（启用 WSL、安装发行版、`wsl.conf` systemd、默认用户）。
- **LDC 接管**：任何 Ubuntu/Debian 机器**内部**的一切收敛——包括 WDC 装出的 WSL Ubuntu（它本来就是一台 amd64 Linux，ADR-0006）。包、语言栈、dotfiles、验证全部走 LDC 单一实现，消灭 setup-ubuntu.sh 与 LDC 的双实现漂移（vp 钉子、bashrc/gitconfig 模板已是两份近似拷贝）。

**委托契约**（WDC 侧改造见 `.scratch/dev-env/03-wdc-wsl-delegation.md`）：

1. LDC 获取：WSL 内首次 `git clone https://github.com/yu-cn/ldc.git ~/dev/ldc`；已存在则等同 `ldc sync` 的仓库步（fetch + `pull --ff-only`，分叉中止交人工）。
2. root 委托：`wsl -d Ubuntu -u root -e bash ~/dev/ldc/scripts/install-packages.sh`——LDC 的 EUID=0 内联路径（ADR-0004），无需 sudo 交互。
3. user 委托：`wsl -d Ubuntu -e bash ~/dev/ldc/bootstrap.sh`——root 阶段已核销自动跳过；无 GNOME 会话桌面域自动 SKIP（ADR-0005）；无 systemd 的发行版 WDC 侧传 `LDC_SKIP_DOCKER=1`。
4. dotfiles：LDC `dotfiles/linux/` 接管 `~/.bashrc` 等落点（替换 WDC 指向 /mnt/c 的旧链接），WDC `dotfiles/wsl/` 随委托退役；机器段由 `.bashrc.local` / `.gitconfig.local` 承接（接管外来符号链接时 LDC 兜底创建空自留地）。
5. 验收：WDC 的 WSL 断言组替换为对 `verify-machine.sh --quick` 的委托调用；WSL 特有残留（默认 shell=bash 的 chsh 等）随委托迁入 LDC。

**演进统筹规则**：Linux 侧 shell/git/提示符模板的主作者位归 LDC（WDC 的 wsl 拷贝冻结至退役）；`configs/vp-version` 两仓库保持同值，升级同日双改、各自记账；WDC 的 upstream-ledger 与 LDC 的 .scratch 工单互引重大决策。拒绝的替代：抽第三个共享仓库供两方消费（为单人双仓库引入包管理复杂度，升级 vp 要跨三处）；保持双实现靠约定同步（正是要消灭的漂移源）；LDC 吞并 WDC 成单仓库双平台（ADR-0001 已否：验证面翻倍）。

**对等原则**（补记 2026-10-25，主人明确）：LDC 与 WDC 是**对等项目**——按平台划界（WDC 主管 Windows 侧，LDC 主管 Linux 侧含 WSL Ubuntu），各自完整生命周期与治理对称；唯一交集是 WDC 的 WSL 域调用 LDC，属**辖区移交而非隶属**。要点：

- 「谁调用谁」由机器入口在哪决定（Windows 机器入口在 WDC），与项目地位无关；纯 Linux 机器上 WDC 不在场，LDC 独立完成全程。
- 该边单向（WDC→LDC）：Ubuntu 收敛按单一来源原则只在 LDC——对等指地位与治理对称，不是调用对称。
- 主作者位澄清：dotfiles/linux 与 dev-standard 的「主作者位在 LDC」是单一来源防漂移机制，与项目地位无关。
- 禁用「引擎 / 编排者 / 上下级」类隐喻；「委托契约」措辞只描述调用机制本身（哪个入口调哪个脚本），不隐含隶属。

**exit 2 语义契约机器化**（补记 2026-10-26，主人批准「按建议来」——起因：WDC setup-ubuntu.sh 曾以 grep 匹配本仓 bootstrap 散文文案（「桌面域：登录」「root 阶段：cd」「git 身份：编辑」）分类 exit 2，属两仓间无守护的字符串契约，任何一侧文案微调即静默失效）：

- bootstrap exit 2 的每条待办明细行尾追加机器标记 `[LDC_TODO=tag]`：`root-handoff` / `desktop` / `git-identity`。**标记字面量属委托契约**——变更须与 WDC `scripts/wsl/setup-ubuntu.sh` 同日双改；新增待办类别必须配新标记。
- WDC 侧判定改按标记、且取**严格形态**：待办集合恰为 `{desktop}` 才按「WSL 形态预期」容忍为完成；出现任何未知标记（本仓未来新增类别而 WDC 未跟进）一律按真问题浮出——宁可误红不可静默吞待办。
- 生产侧活测试：fresh-container.yml 的 handoff job 断言 `LDC_TODO=root-handoff` 在位（交接路径 exit 2 实跑），防契约标记静默漂移。

**root 阶段机器形态三件移交**（补记 2026-11-01，联动 WDC 工单41「边界最小核心化」——主人解除跨仓限制，GLOSSARY WDC 侧词条「双边最优化」）：WDC `setup-ubuntu.sh` 薄委托 wrapper 的最后三件「WDC opinion」归位本仓单一实现，WDC 侧撤除（其 Phase B）、probe.sh 随之退役：

- **本仓落点**：`install-packages.sh`（root 阶段唯一脚本）新增「机器形态」段——① 默认 shell=bash（幂等 chsh）；② `/etc/wsl.conf` systemd=true（`is_wsl` 内核探测门控，写入后提示 `wsl --shutdown` 生效语义与原 WDC 实现一致）；③ docker 组 usermod（原 SUDO_USER 块扩兜底）。三件此前是 WDC 因「root 直调缺 SUDO_USER」而保留的包装层职责。
- **`LDC_USER` 契约（新增）**：root 阶段操作对象 = `SUDO_USER ?: LDC_USER`（`root_target_user()` 单一来源）。本仓自身 bootstrap 流程走 sudo 语境天然有 SUDO_USER；WDC root 直调无此变量——WDC wrapper 显式 `LDC_USER=<WSL默认用户>` 传入。容器 root 冒烟两者皆空 → 按无目标用户跳过。**契约字面量与 WDC setup-ubuntu.sh 同日双改**（同 LDC_TODO 先例）。
- **docker 跳过自判定**：`docker_skipped()` 单一来源——`LDC_SKIP_DOCKER=1` 外部覆盖优先，否则无 systemd 中间态（`/run/systemd/system` 缺席）自跳；安装面（install-packages 两处）、verify 面、`root_stage_complete` 四处同读。原「WDC 探测 systemd 后透传 LDC_SKIP_DOCKER」退役，env 变量保留为外部覆盖语义（CI fresh-container 显式 `LDC_SKIP_DOCKER=1` 行为不变）。
- **verify 断言面**：新增「默认 shell = bash」（全形态）与「systemd 生效」（`is_wsl` 门控）两断言——承接 WDC probe.sh 的 WSL 特有两键；非 WSL 形态此前从未断言 systemd，不扩面。

拒绝的替代：WDC wrapper 以 `su -l <user> -c 'sudo -n …'` 复现 sudo 语境（WSL 默认用户 sudo 需密码，非交互必挂）；LDC 新开独立 root-ops 脚本（三件每件三五行的体量，并入 install-packages.sh 现有 root 面最省契约——退出码语义与「可独立 sudo 运行」红线不变）。
