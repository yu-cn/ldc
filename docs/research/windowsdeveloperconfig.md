# 调研笔记：microsoft/WindowsDeveloperConfig（LDC 视角）

> 调研日期：2026-10-25。深版调研（机制原理/DSC/签名体系/全部一手来源清单）在姊妹仓库
> wdc 的 `docs/research/windowsdeveloperconfig.md`（2026-10-19，一手核实），本笔记只记
> LDC 对标面的结论，不重复深版内容。上游后续事实以本仓 `scripts/check-upstream.sh`
> 的基线（docs/upstream-baseline.json）与账本（docs/upstream-ledger.md）为当前事实源。

## LDC 的对标面

LDC 与上游的交集是 **wsl-comfort**（WSL shell 舒适化流程）——apt 包、提示符、终端
主题化、字体、git 默认值，正是 LDC 的 user 阶段 + dotfiles 层覆盖的面。上游其余部分
与本仓无对标关系：整装机引擎与单语言 Workloads 是 Windows 侧事务（wdc 对标），AI
tooling 是硬件检测装 PyTorch（双仓均不需要）。

## wsl-comfort 覆盖面（wdc 深版调研 + 2026-10-25 基线核实）

- **apt 清单**：真源是 `comfort-shell-bootstrap.sh` 顶部两个结构化数组——
  `COMFORT_APT_REQUIRED`（build-essential / pkg-config / fzf / ripgrep / fd-find / bat /
  jq / unzip / curl / wget / git / ca-certificates）与 `COMFORT_APT_OPTIONAL`
  （eza / btop / tmux）。check-upstream.sh 按数组名直取，不做正则。
- **shell 与提示符**：默认 zsh（可选 bash）、Starship 提示符——LDC 取 bash + Starship
  （bash 归 WDC 委托契约的默认 shell，zsh 属 opinion 不吸收）。
- **其余**：Homebrew（gh/direnv/zoxide）、剪贴板与 open shim、托管式 dotfile 块、git
  默认值（init.defaultBranch=main 等）、Nerd Font、主题化 Terminal profile。
  LDC 对应物：gh 走 root 阶段 apt 官方源；zoxide 在 cli-tools.pkg；字体走
  nerd-fonts-version 钉子（sha256 校验，比上游的 GitHub 直装更严）；Terminal 主题
  （Catppuccin Mocha）在 wdc dotfiles 层，不属 LDC 面。

## 机制背景（影响判读，不构成借鉴项）

上游主体已从 winget-configure/DSC 迁往 PowerShell 原生引擎（CI 注释明示）——引擎有
重启续跑/签名校验，无 dry run（known limitations 明文）；wsl-comfort 仍是 bash 脚本形态。
LDC 的 plan 干跑（ADR 对标面）与双架构 CI 在验收面上反而领先；上游的 重启续跑/运行锁
见 ADR-0013（锁已落地）与 wdc bootstrap-resume（Windows 侧，不适用 LDC）。

## 一手来源

- wsl-comfort readme 与脚本：https://github.com/microsoft/WindowsDeveloperConfig/blob/main/src/wsl-comfort/
- 根 README / src/docs/development.md / src/docs/windows-dev-config.md：同仓库
- wdc 深版调研（机制原理与完整来源清单）：wdc 仓 `docs/research/windowsdeveloperconfig.md`
