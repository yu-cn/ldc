# 词汇表

| 术语 | 含义 |
|---|---|
| **bootstrap** | 收敛入口（`bootstrap.sh`）：预检 → 校验 → root 阶段 → user 工具 → 桌面 → dotfiles → 汇总；幂等可重放 |
| **声明式层** | `configs/` 下的纯文本清单（`.pkg` / `.gsettings` / 版本钉子），一行一事实（ADR-0002） |
| **编排层** | `scripts/` 各阶段脚本负责的流程控制：sudo 交接、二进制安装、迁移机制 |
| **dotfiles 层** | `dotfiles/` 仓库目录，符号链接安装到 `~`（旧文件备份 `*.bak`） |
| **域** | 一份清单对应的一个覆盖面：base-linux / cli-tools / desktop（GNOME 桌面域）/ desktop-apps（桌面应用域） |
| **通用核心** | 「每台 Ubuntu/Debian 开发机都需要」的内容，判据决定什么进仓库（ADR-0003） |
| **机器自留地** | 机器私有内容，不入仓库不受移除清单影响；shell 侧的载体是 `~/.bashrc.local` |
| **`.bashrc.local`** | 机器自留地的 shell 段：首次接管时从原 bashrc 迁移标记块/nvm 块而来，模板最末尾加载、可覆盖模板 |
| **`.gitconfig.local`** | 机器自留地的 git 段（与 .bashrc.local 同构）：gh 凭据助手等按机配置，模板经 `[include]` 引用 |
| **钉子** | 版本钉子：`configs/*-version` 单一来源，升级只改这一个文件（vp / lazygit / starship / nerd-fonts，漂移自动收敛） |
| **架构映射** | `ldc_arch()`：全仓库唯一的架构判断点，`uname -m` → GitHub 资产段（amd64/arm64）；其它架构拒绝（ADR-0006） |
| **root 阶段** | 需提权的系统层：apt 清单核销 + gh 官方源 + Docker（`install-packages.sh`，可独立 sudo） |
| **user 阶段** | 免提权的用户层：uv / vp / starship / lazygit / 字体 + dotfiles |
| **交接命令** | sudo 需密码时 bootstrap 末尾打印的单条手工命令（ADR-0004）；exit 2 = 有待办 |
| **写穿** | 机器侧工具经符号链接把改动落进仓库内模板文件（污染仓库）；triage 负责分流 |
| **分流（triage）** | 写穿漂移的逐文件处置：吸收进模板（git add）/ 还原为机器噪声（checkout） |
| **防写穿断言** | verify 的「dotfiles 与 HEAD 一致」检查；仓库无 commit 时降级为 INFO |
| **LDC_SMOKE** | 容器冒烟降级开关：身份断言降为存在性检查（占位即过） |
| **LDC_SKIP_DOCKER** | 跳过 docker 域（CI 容器无 systemd，装了也跑不起来） |
