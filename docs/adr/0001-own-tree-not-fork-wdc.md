# 独立仓库，不 fork WDC

LDC 借鉴 [WDC](https://github.com/yu-cn/wdc)（Windows + WSL 声明式开发环境）的经验另起独立仓库，服务 Ubuntu/Debian 裸机与服务器：两边的「机器事实」差异是本质性的（包管理器、提权模型、dotfiles 落点、桌面域），共享代码只会逼出一层跨平台抽象，而这层抽象当前只有两个消费者。v1 完全独立，dotfiles 语义对齐（同款 starship/gitconfig 习惯、同 vp 钉子），使两仓库在同一主人手里的心智模型一致。

将来 WDC 的 WSL 阶段复用 LDC user 阶段属 YAGNI——真出现该需求时再以「WSL 内 clone LDC 并调用其脚本」的松耦合形态评估，不为假想需求预留接口。一个边界约定：LDC 本身就是双架构纯 Ubuntu/Debian（ADR-0006），可以直接跑在任意 amd64/arm64 的 Ubuntu 内**包括 WSL Ubuntu**（桌面域在无 GNOME 会话时自动 SKIP），但**一个发行版只归一个管理器**——WDC 已管理的 WSL 发行版继续归 WDC，两边接管同一 `~/.bashrc` 只会互相顶掉对方的符号链接。拒绝的替代：fork WDC（历史与议题混杂 Windows 语义，改造成本高于重写）；单仓库双平台（bootstrap 需分叉判定平台，验证面翻倍，仓库对两套机器都「部分无关」）。

> **修订（2026-10-24）**：用户已明确要求 WDC 与 LDC 统筹——上段「YAGNI / WDC 独管 WSL」立场由 [ADR-0007](0007-wdc-ldc-coordination.md) 取代：WSL 发行版内部收敛委托给 LDC，WDC 保留 Windows 侧与 WSL 生命周期；「一个发行版只归一个管理器」原则不变，实现方式由「归 WDC」改为「归 LDC、WDC 委托调用」。
