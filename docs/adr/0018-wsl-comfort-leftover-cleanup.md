# wsl-comfort 残留一次性清理与吸收定夺

2026-11-01 主人巡检本机 WSL 侧时提出：「还残留很多 microsoft/WindowsDeveloperConfig 里 wsl-comfort（Comfort Shell）的痕迹——nvm、comfort-shell 命令等，如何优化完善」。深查定归属后清理。本机时间线：2026-06-24 wsl-comfort 经 skel 装机流两轮安装（`~/.comfort-shell-install.log` 自证，日志尾「Distro configured. Ready for first user.」）；10 月 LDC 经 WDC 委托契约（ADR-0007）接管——三个渲染落点 sha256 零漂移、comfort 的 git 默认值/starship 款式/zsh 面已被吸收或清除，系统级活体残留仍在。上游 README 无任何卸载/uninstall 面（托管块整体替换语义），残留无法借官方手段移除。

## 归属证据与定夺

| 残留 | 归属证据 | 定夺 |
|---|---|---|
| `~/bin/{bat,fd,open,pbcopy,pbpaste,xdg-open}` 六垫片 | 文件自证注释 `# comfort-shell shim` + 日志 376/491 行「CLI shims installed」 | 删——交互面由 bashrc ADR-0017 函数垫片接管，bat/fd 另有 /usr/local/bin LDC 兼容链接 |
| `/home/linuxbrew`（288M，Cellar: bash/direnv/gh/ncurses/readline/zoxide） | 日志 594 行「Homebrew setup complete」；不在 PATH、零 rc 引用、全惰性（gh 曾装失败，现由 LDC apt 官方源供给） | 删 |
| `/usr/local/bin/starship` v1.25.1（root、dpkg 无主） | skel 模式系统级安装位（上游 readme 实证）；时间戳 2026-05-01 早于现存日志，属前 LDC 时代（comfort/WDC wsl 期）遗留 | 删——LDC 钉 1.27.0 于 `~/.local/bin`，旧版对非交互 shell 构成版本阴影 |
| `~/.comfort-shell-install.log`（161KB）+ `~/comfort-shell-bootstrap.sh`（30KB，09-29 重下的新版拷贝） | comfort 本体与其安装日志 | 关键证据摘录入本 ADR 与工单后删，home 根不留 |
| btop | `COMFORT_APT_OPTIONAL`（eza/btop/tmux）唯一留存成员 | **吸收**：并入 `configs/cli-tools.pkg`（与既有 htop 并列），audit 自装未声明 -1 |
| direnv | 日志 451 行 `brew install direnv`——此前只活在 brew Cellar，bashrc 模板 104 行的 direnv 探测钩子一直空转 | **吸收**：apt 版并入 `configs/cli-tools.pkg`，既有钩子激活 |
| `~/.nvm`（237M，node v24.18.0，alias default=lts/*） | **归属修正：机器自有，非 comfort 所装**——comfort 脚本无 nvm 步骤，nvm 装于其日志 17 小时后（06-24 18:29）；零 rc 引用，node 已由 mise 供 v26.13.0（ADR-0016） | 删——机主一次性个人操作；红线 2「nvm 属自留地」约束的是 LDC 工具行为，条款不变，之后本机亦不复有 nvm |

Windows 侧 comfort 痕迹（字体注册表、Windows Terminal fragment、`%LOCALAPPDATA%\DevConfig\wsl-comfort` 暂存）归 WDC 辖区（冻结待退役），本次不动。

## 决策

- **一次性机主授权清理**，配方固化于本 ADR 与工单（dev-env 11）——「只装不删」红线（AGENTS 红线 2）不变，不建移除清单、不设激活面；清后对账走 verify/plan/audit 常规关卡。
- btop、direnv 经吸收账本思路并入通用核心（ADR-0003 声明面）；上游清单基线（upstream-baseline.json）无需改动——check-upstream 对「上游包我方已有声明」本就按当前 configs 动态比对。

拒绝的替代：**仓库常驻清理脚本**（移除语义与「无移除清单」红线相抵，且脚本面会腐烂——残留是第三方所装、仅本机有，配方入档即档案）；**搬 WDC remove-leftovers**（辖区不符：WDC 卸载工具面向其自身安装面，comfort 非 LDC 所装）；**等上游官方卸载**（README 无 uninstall 面，不会有了）。
