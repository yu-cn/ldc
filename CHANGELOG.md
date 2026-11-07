# Changelog

[![Keep a Changelog](https://img.shields.io/badge/Keep%20a%20Changelog-2.0.0-informational)](https://keepachangelog.com/en/2.0.0/)

本项目所有显著变更记录于此文件。

- 格式遵循 [Keep a Changelog 2.0.0](https://keepachangelog.com/en/2.0.0/) 的中文化改造版（[docs/changelog-standard.md](docs/changelog-standard.md)，双仓同源、主作者位 LDC）——显著变更人为记录、六类型（Added/Changed/Deprecated/Removed/Fixed/Security）分类归档、每版本 compare 链接可跳转、倒序排列；破坏性变更以 `Breaking:` 标记写在对应类型节内（不单列节）
- 版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)（v0.x 阶段破坏性变更走 MINOR）；提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/v1.0.0/)——feat / fix 驱动版本号。发布动作与验证锚点见各 [release](https://github.com/yu-cn/ldc/releases)。

## [Unreleased]

## [0.12.0] - 2026-11-07

### Added
- `ldc sync` 收敛账本快速路径（[ADR-0021](docs/adr/0021-convergence-ledger-fast-path.md)，联动 wdc 工单42 同构）：已收敛且声明未变（账本记「上次达终态时的 HEAD」== 当前 HEAD 且工作区干净）时跳过 bootstrap，仅 verify --quick 秒级复核——日常收敛免重跑幂等 SKIP 的七阶段。账本缺失/损坏/不匹配、工作区脏（未提交的声明编辑）一律回退全量（假账本会假绿，宁可慢不可假绿）；`ldc sync --full` 强制全量。终态口径含形态级终态：非桌面机器（WSL/headless/容器）的桌面域 SKIP 是形态级 N/A 不算活待办（与委托方 WDC 的容忍分支同款语义），bootstrap 退出码与 `[LDC_TODO=desktop]` 契约面零变化
- 钉子新鲜度周巡检 workflow（[ADR-0020](docs/adr/0020-pin-freshness-patrol.md)）：GitHub API 对五钉子（uv / mise / starship / lazygit / nerd-fonts）的上游 `releases/latest`，workflow summary 列「钉 X / 上游 Y」明细——只提醒不升级（钉子升级 = 人的决定 + sha256 同 commit 重算，ADR-0011，自动化会绕过重算纪律），恒 exit 0 不红 badge（钉子滞后于上游是常态非事故）
- CI 冒烟矩阵补 debian 腿并补齐双发行版 × 双架构四腿（ubuntu:24.04 / debian:13 × amd64/arm64）：README / 预检承诺的 ubuntu/debian 双发行版自此各有实证腿——Debian 命名差异（fdfind/batcat）由兼容链接段真实覆盖，此前仅 ubuntu:24.04 双架构。Debian 版本定夺 13+（主人 2026-11-07 定夺）：12/bookworm 仓库缺 eza/git-delta（debian 腿首跑即暴露的真缺口），README 承诺面同步收敛为「Ubuntu 24.04+ / Debian 13+」

### Changed
- dotfiles 备份轮转设上限（[ADR-0015 补记](docs/adr/0015-copy-render-not-symlink.md)，联动 wdc 工单44 同语义同日）：`.bak` 本体 + 编号系列至多 3 份——本体永不清，编号系列超出删 mtime 最老并逐项报告（删除动作可见；「机器侧内容绝不静默丢弃」以「报告在」的形态保持）——此前无限递增，长跑机器攒档
- Docker 安装面收编 download.docker.com 官方 apt 源（[ADR-0019](docs/adr/0019-docker-vendor-apt-repo.md)）——get.docker.com 管道脚本退役（全仓最后一个 curl | sh 安装面），与 gh / VSCode / Chrome 同款 `add_vendor_repo` 配方（keyring + 源 + 一次 apt 事务装 docker-ce 与 buildx / compose 插件）；marker 判重兼容既有安装（get.docker.com 装过的机器幂等直入，无需迁移）；版本不钉与 gh 同口径（apt 事务与 dpkg 账本即记账，红线 11）
- 四段钉子安装器收编单一来源：uv / mise / starship / lazygit 的「下载 → sha256 落盘验 → 解压 → install」同构面（约 200 行四份拷贝、文案已现漂移）收敛为 common.sh `pinned_tarball_install`，资产命名例外注释保留在调用点；临时目录统一登记（`ldc_tmp_*`）+ trap 清理，中断不在 /tmp 留残
- 包安装合批：`pkg_install` 缺失件合并为单次 apt 事务（新机收敛不再逐包 ~20 次独立事务；整批失败退回逐包定位元凶），逐包 `[OK]/[SKIP]` 口径不变——用 apt 自带的事务与依赖解析（红线 11）
- VSCode 扩展安装 fast-path：先 `code --list-extensions` 做差集（与 verify / plan 同款 comm 口径）只装缺失件——已装件零 marketplace 往返，每次收敛省 30 次网络请求
- `ldc status` 远端判读带 5s 超时 + 禁交互（坏网络不再挂起「秒级快照」；fetch 未达按本地缓存判读并 INFO 标注）；get.sh 复用路径显式传 tag 即升级重钉（同 tag 重跑 no-op 幂等，原仅作用于 fresh clone）
- validate 钉子检查收紧为 sha256 行必配（[ADR-0020](docs/adr/0020-pin-freshness-patrol.md) 对 ADR-0011 的机械收口）：分架构四钉须双 arch 行齐备、nerd-fonts 须无 arch 行——缺即 FAIL（原「有则查格式、无则放行」拦不住「升版本忘更哈希」落地）
- wsl-comfort 定性为**参考资源非上游**（主人 2026-11-07 定性，[ADR-0014 补记](docs/adr/0014-upstream-tracking.md)）：LDC 独立自持、不跟随其演进——check-upstream / 吸收账本 / `ldc status` 的措辞与输出标签由「上游」改为「参考资源」，机制、文件名与 `-UpdateBaseline` 参数不动；LDC 唯一的真上游关系在钉子资产一侧（ADR-0020 巡检盯的那侧）
- bootstrap 日志轮转：`logs/` 保留最近 20 份，更旧的随跑清理

### Fixed
- CI 冒烟容器（apt shellcheck 0.9.0）与新版（0.11）对带默认值可选参的 SC2120 判定分歧收口：`pinned_tarball_install` 收编引入的仓内无参调用点触发 0.9.0 报警致冒烟三腿红（11-02 以来首次冒烟暴露）——`ldc_arch` 定义点定点 disable 并注明版本分歧
- `ldc sync` fetch 失败不再静默继续——原按陈旧 origin/main 判「一致」可能漏拉仍报全绿（盲同步风险），现 FAIL 中止
- 钉版形态（get.sh LDC_TAG 钉 tag 后 detached HEAD）不再误判：`ldc status` 原对钉版机误报「落后 N」，`ldc sync` 原在 pull 上撞 detached HEAD 失败——钉版是合法形态，现单列口径（status INFO 标注、sync 跳过仓库同步仅收敛机器）
- validate 钉子检查清单补 starship-version（原仅四钉在册、实为五钉，starship 的版本行与 sha256 行此前不在格式检查面）
- README 系统清单陈旧订正：移除 v0.11.0 已除名的 tree、补同版吸收的 btop / direnv


## [0.11.0] - 2026-11-01

### Added
- `configs/cli-tools.pkg` 吸收 btop、direnv（[ADR-0018](docs/adr/0018-wsl-comfort-leftover-cleanup.md)）——本机 wsl-comfort（微软 Comfort Shell）残留定夺：btop 原为其可选包唯一留存；direnv 原局限于 Homebrew、bashrc 模板的 direnv 探测钩子自此激活。活体残留（六垫片 / `/home/linuxbrew` / 系统级旧 starship / 日志与脚本 / 孤儿 nvm——归属修正为机器自有非 comfort 所装）经机主授权一次性清理，「只装不删」红线不变；配方与证据入 ADR-0018 与工单 dev-env 11

### Changed
- 承接 WDC 移交三件（[ADR-0007](docs/adr/0007-wdc-ldc-coordination.md) 补记，联动 [wdc 工单41](https://github.com/yu-cn/wdc)「边界最小核心化」，工单12）——`install-packages.sh` 新增「机器形态」段：默认 shell=bash（幂等 chsh）、wsl.conf systemd=true（is_wsl 门控）、docker 组 usermod 归位（`root_target_user()` = SUDO_USER ?: LDC_USER，root 直调缺 SUDO_USER 由 LDC_USER 契约补）；`docker_skipped()` 单一来源（LDC_SKIP_DOCKER=1 外部覆盖优先、无 systemd 中间态自跳）四处换面同口径——原 WDC wrapper 的透传判定退役；verify 五组扩六组（默认 shell=bash 全形态、systemd 生效 is_wsl 门控，承接 WDC probe.sh 两键）
- bashrc Ctrl-T 加 bat 右侧实时预览（FZF_CTRL_T_OPTS，对齐 wdc pwsh 侧 cc46108；fd/bat 任一缺席不设）；`configs/cli-tools.pkg` 移除 tree（eza lt 完全覆盖，已装机残留按「只装不删」留存）；apt 索引 24h 内已更新（lists mtime 本地判定）则跳过（工单12 顺手项）
- dev-standard §46 补澄清句：同号同日仅限联动变更——无契约联动的批次不追齐版本号（v0.10.0 锚点回看：wdc 功能批 × 本仓治理批零交集仍同号同日，属过度执行；工单41 定澄清）
- WSL 便利垫片补全（[ADR-0017](docs/adr/0017-languages-surface-consolidation.md) 补遗，真机 wsl-comfort 残留排查驱动）：open 垫片对存在路径经 wslpath 转 Windows 形式（收编上游同名 shim 实现，原漏收）；补 xdg-open→open 探测门控委托（WSL 无 xdg-utils，`gh --web` 一类调用不再断链）——wsl-comfort 时代 `~/bin` 六 shim（pbcopy/pbpaste/open/xdg-open/fd/bat）确认由声明面接管
- CHANGELOG.md 升级 Keep a Changelog 2.0.0 并落地中文化改造版规范（docs/changelog-standard.md，本仓主笔、双仓同源）：版本节连字符归一、破坏性条目改 `Breaking:` 标记、节内六类型 canonical 序、修复 Unreleased compare 链陈旧；dev-standard-guard 同源守护扩展至 changelog-standard.md
- `.gitignore` 补全防误添加面：ZCode 工具工作区（`.v2c/`、`.video_agent/`、`.zcode/`）、退役面 `/HANDOFF.md` 防回流（f5a8610 退役）、`*.bak` 与编辑器/跨系统垃圾（`.vscode/`、`.idea/`、swap、`.DS_Store`、`Thumbs.db`、`desktop.ini`）、`__pycache__/`——`logs/`（bootstrap 每跑落一份日志）沿用既有忽略；`docs/demo.cast`（录制源）与 `*.gif` 为有意入库资产，保持不忽略

## [0.10.0] - 2026-11-01

### Changed
- 工单面统一收口（治理批，联动 [wdc v0.10.0](https://github.com/yu-cn/wdc/releases/tag/v0.10.0)）——14 张已收口票补 `Status: done` 行并归档 `done/`（dev-env 01–10、upstream-borrow 01–04、git-free-quickstart 01）：flock 运行锁 / 上游跟进面（research 笔记 + 账本 + check-upstream.sh）/ get.sh 钉版 / CI 幂等重跑段经巡检确认均已实现，票面不可读曾致「已实现误判为未实现」（双仓两连实录）；dev-standard §2 补「收口即时置终态」纪律（双仓同源同批）
- 上游基线核销：check-upstream 实跑无差异（HEAD fb564611 与 2026-10-25 基线一致、包清单零变化）

## [0.9.0] - 2026-10-31

### Added
- WSL 剪贴板/open 垫片：bashrc 模板 `clip.exe`/`explorer.exe` 探测门控段——pbcopy/pbpaste/open（[ADR-0017](docs/adr/0017-languages-surface-consolidation.md)，上游 WSL Comfort 同款件的 LDC 形态）
- `configs/mise-version`、`configs/uv-version` 双钉（哈希自官方 release 资产实算/侧车对齐，ADR-0011）
- VSCode 扩展清单补 fss/ZCode 上游推荐三件（better-comments / mermaid-preview / tailwindcss）——vite-plus 扩展包退役零损失核实（联动 wdc 工单39）

### Changed
- **Breaking:** 语言管理器 vp 退役、mise 升正（[ADR-0016](docs/adr/0016-vp-retire-mise-takeover.md)）——`install-user-tools.sh` 的 vp 安装/env 编排块换 mise（GitHub release + sha256 双钉、双架构经 `ldc_arch()`）+ `mise use -g node@lts` 默认环境；存量机一次性迁移豁免（探测到 vp 即按其安装器写入面反向清除，「只装不删」红线显式例外）；uv 从官方 curl|sh 升 release+sha256 双钉（ADR-0011）；env.sh 事实文件收缩为 fzf 面（mise/uv 布局固定、直接在 bashrc 模板声明）；verify/plan/validate 断言与投影换面；VSCode 清单去 `voidzero.vite-plus-extension-pack`；AGENTS 红线1、GLOSSARY、README 同步；dev-standard §6 钉子同值标注「当前无实例」（本仓主笔，WDC 拷贝随其工单39）
- README 首屏演示重录——换轨后真实输出（plan/verify mise 钉子行），agg v1.9.0 重转 GIF
## [0.8.0] - 2026-10-27

### Added
- get.sh 支持 `LDC_REPO` 覆盖引导地址（fork 用户一条命令对齐手动路径）与 `LDC_TAG` env 钉版（与位置参数同义，对齐 WDC get.ps1 的 env 口径）
- CI 新增 dev-standard-guard 双仓同源守护工作流：每周拉姊妹仓 WDC 的 `docs/dev-standard.md` 去 CR 归一比对，漂移即红（主作者位在本仓；刻意不挂 push——双仓协同编辑必有先后，瞬时红污染 badge）

### Changed
- bootstrap exit 2 的待办明细行尾追加机器标记 `[LDC_TODO=tag]`（root-handoff / desktop / git-identity）——委托方 WDC 的 WSL 阶段改按标记判定待办语义，退役散文文案 grep（委托契约增补，[LDC ADR-0007 补记](docs/adr/0007-wdc-ldc-coordination.md)）；人类可读待办文案不变
- dev-standard §5 补「双仓版本对齐」约定：双仓联动变更（委托契约 / 同源规范 / 同值钉子）发版时两仓版本号对齐收口（LDC_TODO 契约两仓同批积压 `[Unreleased]` 的实录定规矩）——本版与 WDC v0.8.0 同号同日为首次执行

## [0.7.0] - 2026-10-26

### Added
- `ldc audit` 清单准入对账：自装未声明（对全部 `.pkg` 并集的差集，喂清单准入）与已声明未装（收敛待办）两个方向，只读恒 exit 0
- 可选包组 `etckeeper`：`/etc` 纳入 git 审计——apt 事务前后与每日自动 commit（systemd timer + apt 钩子），root 写入面（daemon.json 合并等）自此有机器侧留痕
- 漂移方向判定（ADR-0015 补注）：渲染账本 `~/.local/state/ldc/rendered.sha256` 判定 template-update / machine / both / unknown 四方向——纯模板更新直接重渲染、不再产生 `.bak`
- CHANGELOG（本文件，Keep a Changelog 格式）与 README 首屏终端速览演示（`docs/demo.cast` + agg 转 GIF 嵌播）

## [0.6.0] - 2026-10-25

### Added
- 工具布局事实文件 `~/.config/ldc/env.sh`：bashrc 模板不再硬编码 vp / fzf 路径，上游换布局只改安装器
- verify `assert_pin`：starship / lazygit / vp 三钉全入断言面；红线 11「不重写包管理」入册
- 中文输入换代 ibus-rime + 雾凇拼音（ADR-0005 补记）
- bootstrap flock 运行锁（ADR-0013）；上游跟进机制（ADR-0014：check-upstream + status 30 天提醒）；get.sh 支持 tag 钉版
- CI 冒烟补幂等重跑段（第二遍 exit 0 且零 CHANGED 才放行）

### Changed
- **Breaking:** dotfiles 落点由符号链接改为安装期渲染拷贝（[ADR-0015](docs/adr/0015-copy-render-not-symlink.md)）——仓库缺席不再影响已收敛机器（只剩 `ldc` CLI 自身）；机器侧直改落点不再污染仓库，verify / status 改内容断言、triage 分流（吸收 / 还原）；覆盖前轮转备份 `.bak`

## [0.5.0] - 2026-10-24

### Added
- `scripts/get.sh` 零前置远程一键引导：缺 git / curl 自动 apt 装、`~/.ldc` 指针复用、转发 bootstrap

## [0.4.0] - 2026-10-24

### Added
- 可选包组（ADR-0010）：清单即菜单、`install-packages.sh <组>` 显式指名、dpkg 记账不进断言面（首个成员 media-doc）
- `ldc plan` 干跑预演：只读投影重跑会做什么（OK / PLAN / SKIP / INFO）

### Changed
- 下载资产从只钉版本升级为版本 + sha256 同文件双钉（ADR-0011），校验不符即拒绝安装

## [0.3.0] - 2026-10-24

### Added
- Docker daemon.json 受保护合并（ADR-0009）：声明叶键胜出、机器自有键保留、绝不自动重启
- WSL 发行版环境由 WDC 委托 LDC 收敛（ADR-0007 契约落地），Linux 侧单一来源归位

## [0.2.0] - 2026-10-24

### Added
- 桌面应用域（ADR-0008）：VSCode + 扩展清单 + Chrome，双架构厂商源对称
- CI 验证面扩三腿（handoff + amd64 / arm64 容器冒烟）

## [0.1.0] - 2026-10-23

### Added
- 首个发布锚点：bootstrap 七阶段收敛（预检 → 校验 → root 交接 → user 工具 → 桌面 → dotfiles → 汇总）、verify 机器断言、`ldc` CLI、dotfiles 机器自留地（ADR-0003）、双架构一等公民（ADR-0006）

[Unreleased]: https://github.com/yu-cn/ldc/compare/v0.12.0...HEAD
[0.12.0]: https://github.com/yu-cn/ldc/compare/v0.11.0...v0.12.0
[0.11.0]: https://github.com/yu-cn/ldc/compare/v0.10.0...v0.11.0
[0.10.0]: https://github.com/yu-cn/ldc/compare/v0.9.0...v0.10.0
[0.9.0]: https://github.com/yu-cn/ldc/compare/v0.8.0...v0.9.0
[0.8.0]: https://github.com/yu-cn/ldc/compare/v0.7.0...v0.8.0
[0.7.0]: https://github.com/yu-cn/ldc/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/yu-cn/ldc/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/yu-cn/ldc/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/yu-cn/ldc/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/yu-cn/ldc/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/yu-cn/ldc/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yu-cn/ldc/releases/tag/v0.1.0
