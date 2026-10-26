# 词汇表

| 术语 | 含义 |
|---|---|
| **bootstrap** | 收敛入口（`bootstrap.sh`）：预检 → 校验 → root 阶段 → user 工具 → 桌面 → dotfiles → 汇总；幂等可重放 |
| **声明式层** | `configs/` 下的纯文本清单（`.pkg` / `.gsettings` / 版本钉子），一行一事实（ADR-0002） |
| **编排层** | `scripts/` 各阶段脚本负责的流程控制：sudo 交接、二进制安装、迁移机制 |
| **dotfiles 层** | `dotfiles/` 仓库目录（模板=唯一声明源），bootstrap 渲染拷贝安装到 `~`（覆盖前备份 `*.bak`；ADR-0015）；例外 `~/.local/bin/ldc` 保持符号链接 |
| **域** | 一份清单对应的一个覆盖面：base-linux / cli-tools / desktop（GNOME 桌面域）/ desktop-apps（桌面应用域） |
| **通用核心** | 「每台 Ubuntu/Debian 开发机都需要」的内容，判据决定什么进仓库（ADR-0003） |
| **可选包组** | 常用但非每台必需的工具清单（如 media-doc）：平铺 `configs/<名>.pkg`，指名安装、装没装由 dpkg 记账，不进断言面（ADR-0010） |
| **干跑预演（plan）** | 只读投影「重跑会做什么」：OK=已就位 / PLAN=将变更 / SKIP=不适用 / INFO=需手工；与 verify（断言现状）互补，sudo 前先看一眼 |
| **清单准入对账（audit）** | `ldc audit` 只读对账：①自装未声明（showmanual − 全部 .pkg 并集 − 特殊安装面 gh/docker，滤系统底座）= 准入候选；②已声明未装 = 收敛待办。恒 exit 0，核销语义在 verify |
| **机器自留地** | 机器私有内容，不入仓库不受移除清单影响；shell 侧的载体是 `~/.bashrc.local` |
| **`.bashrc.local`** | 机器自留地的 shell 段：首次接管时从原 bashrc 迁移标记块/nvm 块而来，模板最末尾加载、可覆盖模板 |
| **`.gitconfig.local`** | 机器自留地的 git 段（与 .bashrc.local 同构）：gh 凭据助手等按机配置，模板经 `[include]` 引用 |
| **钉子** | 版本钉子：`configs/*-version` 单一来源，升级只改这一个文件（vp / lazygit / starship / nerd-fonts，漂移自动收敛） |
| **架构映射** | `ldc_arch()`：全仓库唯一的架构判断点，`uname -m` → GitHub 资产段（amd64/arm64）；其它架构拒绝（ADR-0006） |
| **受保护合并** | daemon.json 的声明式管理方式：jq 递归合并，声明叶键胜出、机器自有键保留，绝不整文件接管（ADR-0009） |
| **root 阶段** | 需提权的系统层：apt 清单核销 + gh 官方源 + Docker（`install-packages.sh`，可独立 sudo） |
| **user 阶段** | 免提权的用户层：uv / vp / starship / lazygit / 字体 + dotfiles |
| **交接命令** | sudo 需密码时 bootstrap 末尾打印的单条手工命令（ADR-0004）；exit 2 = 有待办 |
| **写穿** | 机器侧工具直改落点渲染物（VSCode / gh auth setup-git 等）；ADR-0015 后仓库不受污染，triage 负责分流 |
| **分流（triage）** | 落点漂移的逐文件处置：吸收=落点回写模板（显式路径暂存）/ 还原=自模板重渲染（ADR-0015） |
| **落点内容断言** | verify 的「落点与模板一致」检查（ADR-0015：断效果不断实现，取代旧「防写穿断言」的 readlink+HEAD 比对） |
| **落点映射（dotfiles_map）** | `common.sh` 单一来源的「模板→落点」映射，安装/断言/预演/分流/快照五方共读（对齐 WDC dotfiles-map.ps1） |
| **渲染（render）** | bootstrap 把模板内容拷贝到落点（覆盖前轮转备份 `.bak`/`.bak.N`，同内容幂等跳过；ADR-0015） |
| **env.sh** | 机器事实文件 `~/.config/ldc/env.sh`：install-user-tools 安装期探测的工具布局（vp env 脚本、fzf 键位路径），bashrc 模板只 source 它（ADR-0015） |
| **渲染账本（rendered.sha256）** | `~/.local/state/ldc/rendered.sha256`：上次渲染时各落点的内容指纹（sha256sum 兼容格式，可丢自愈）；`drift_direction` 据此判漂移方向（template-update/machine/both/unknown），纯模板更新重渲染免 .bak（ADR-0015 补注） |
| **LDC_SMOKE** | 容器冒烟降级开关：身份断言降为存在性检查（占位即过） |
| **LDC_TODO** | bootstrap exit 2 待办明细行尾的机器标记 `[LDC_TODO=tag]`（root-handoff / desktop / git-identity）：委托方 WDC 按标记判定语义，字面量属委托契约、变更同日双改（ADR-0007） |
| **LDC_SKIP_DOCKER** | 跳过 docker 域（CI 容器无 systemd，装了也跑不起来） |
| **运行锁** | bootstrap 收敛进程持有的 flock 文件锁（`${XDG_RUNTIME_DIR:-/tmp}/ldc-bootstrap-$UID.lock`）：同一时刻只允许一个收敛会话（bootstrap / `ldc sync`），后来者 exit 1 让路；持锁进程崩溃由内核自动释放（ADR-0013） |
