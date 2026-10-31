# languages 面补全：uv 双钉、WSL 垫片（docker 核实已在位）

2026-10-31 主人定夺「LDC 负责把 Linux（含 WSL）侧开发环境配好」，参照 microsoft/WindowsDeveloperConfig 的 WSL Comfort。调研与真机复核：WSL Comfort 仅覆盖 shell 体验层（zsh/bash、Starship、现代 CLI、剪贴板/open 垫片、可选 Homebrew——LDC 已全覆盖且更强）；LDC 的语言面**已存在且工作中**（uv 管 Python、vp 管 Node+lts 默认、verify 已断言「node 可用」——本机 WSL 实录 node 26.13.0 / uv 双 python），并非从零新建。本 ADR 只做换轨（ADR-0016）后的补全，主人选定「全收」边界：

- **uv 供应链升级**：从「官方 curl|sh 安装器、跳过已装」升为 GitHub release 二进制 + sha256 双钉（ADR-0011 模式；现状口径「curl|sh 信任锚是域名、不在可钉范围」虽自洽，但 uv 有官方 release 资产，双钉更优）。
- **docker 面核实（无新增）**：实施时核实 docker 并非声明缺口——root 阶段本就经 get.docker.com 官方脚本安装并加 docker 组免 sudo（`LDC_SKIP_DOCKER=1` 供 CI 跳过）、daemon.json 走受保护合并（ADR-0009）；评估时的「E2E 引擎缺口」判断有误，不设 docker.pkg。
- **WSL 剪贴板/open 垫片**：`dotfiles/linux/bashrc` 模板加探测门控段（`clip.exe` 在位才定义 pbcopy/pbpaste、`explorer.exe` 在位才定义 open）——模板静态声明、零安装面、不进断言；上游同款件的 LDC 形态。
- **职责成文**：LDC 收敛「语言管理器 + 默认环境」（ADR-0016 后 = mise + node@lts、uv），具体语言版本归各项目（`mise.toml` / uv 项目管理）——与 WDC「装管理器不装版本」同哲学，首次在 ADR 层成文。

拒绝的替代：照搬 WSL Comfort 的 Homebrew（重写包管理，违 AGENTS 红线 11）；语言版本钉进 configs（版本事实归项目仓，环境仓钉语言版会跟项目脱节）；zsh 换轨（LDC 已定 bash，无换轨理由）。
