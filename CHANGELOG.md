# Changelog

本项目所有显著变更记录于此文件。

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)（显著变更人为记录、分类归档、每个版本可跳转）；版本号遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)（v0.x 阶段破坏性变更走 MINOR）；提交信息遵循 [Conventional Commits](https://www.conventionalcommits.org/zh-hans/v1.0.0/)——feat / fix 驱动版本号。发布动作与验证锚点见各 [release](https://github.com/yu-cn/ldc/releases)。

## [Unreleased]

### Changed
- bootstrap exit 2 的待办明细行尾追加机器标记 `[LDC_TODO=tag]`（root-handoff / desktop / git-identity）——委托方 WDC 的 WSL 阶段改按标记判定待办语义，退役散文文案 grep（委托契约增补，[LDC ADR-0007 补记](docs/adr/0007-wdc-ldc-coordination.md)）；人类可读待办文案不变

## [0.7.0] – 2026-10-26

### Added
- `ldc audit` 清单准入对账：自装未声明（对全部 `.pkg` 并集的差集，喂清单准入）与已声明未装（收敛待办）两个方向，只读恒 exit 0
- 可选包组 `etckeeper`：`/etc` 纳入 git 审计——apt 事务前后与每日自动 commit（systemd timer + apt 钩子），root 写入面（daemon.json 合并等）自此有机器侧留痕
- 漂移方向判定（ADR-0015 补注）：渲染账本 `~/.local/state/ldc/rendered.sha256` 判定 template-update / machine / both / unknown 四方向——纯模板更新直接重渲染、不再产生 `.bak`
- CHANGELOG（本文件，Keep a Changelog 格式）与 README 首屏终端速览演示（`docs/demo.cast` + agg 转 GIF 嵌播）

## [0.6.0] – 2026-10-25

### Changed
- **破坏性**：dotfiles 落点由符号链接改为安装期渲染拷贝（[ADR-0015](docs/adr/0015-copy-render-not-symlink.md)）——仓库缺席不再影响已收敛机器（只剩 `ldc` CLI 自身）；机器侧直改落点不再污染仓库，verify / status 改内容断言、triage 分流（吸收 / 还原）；覆盖前轮转备份 `.bak`

### Added
- 工具布局事实文件 `~/.config/ldc/env.sh`：bashrc 模板不再硬编码 vp / fzf 路径，上游换布局只改安装器
- verify `assert_pin`：starship / lazygit / vp 三钉全入断言面；红线 11「不重写包管理」入册
- 中文输入换代 ibus-rime + 雾凇拼音（ADR-0005 补记）
- bootstrap flock 运行锁（ADR-0013）；上游跟进机制（ADR-0014：check-upstream + status 30 天提醒）；get.sh 支持 tag 钉版
- CI 冒烟补幂等重跑段（第二遍 exit 0 且零 CHANGED 才放行）

## [0.5.0] – 2026-10-24

### Added
- `scripts/get.sh` 零前置远程一键引导：缺 git / curl 自动 apt 装、`~/.ldc` 指针复用、转发 bootstrap

## [0.4.0] – 2026-10-24

### Added
- 可选包组（ADR-0010）：清单即菜单、`install-packages.sh <组>` 显式指名、dpkg 记账不进断言面（首个成员 media-doc）
- `ldc plan` 干跑预演：只读投影重跑会做什么（OK / PLAN / SKIP / INFO）

### Changed
- 下载资产从只钉版本升级为版本 + sha256 同文件双钉（ADR-0011），校验不符即拒绝安装

## [0.3.0] – 2026-10-24

### Added
- Docker daemon.json 受保护合并（ADR-0009）：声明叶键胜出、机器自有键保留、绝不自动重启
- WSL 发行版环境由 WDC 委托 LDC 收敛（ADR-0007 契约落地），Linux 侧单一来源归位

## [0.2.0] – 2026-10-24

### Added
- 桌面应用域（ADR-0008）：VSCode + 扩展清单 + Chrome，双架构厂商源对称
- CI 验证面扩三腿（handoff + amd64 / arm64 容器冒烟）

## [0.1.0] – 2026-10-23

### Added
- 首个发布锚点：bootstrap 七阶段收敛（预检 → 校验 → root 交接 → user 工具 → 桌面 → dotfiles → 汇总）、verify 机器断言、`ldc` CLI、dotfiles 机器自留地（ADR-0003）、双架构一等公民（ADR-0006）

[Unreleased]: https://github.com/yu-cn/ldc/compare/v0.7.0...HEAD
[0.7.0]: https://github.com/yu-cn/ldc/compare/v0.6.0...v0.7.0
[0.6.0]: https://github.com/yu-cn/ldc/compare/v0.5.0...v0.6.0
[0.5.0]: https://github.com/yu-cn/ldc/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/yu-cn/ldc/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/yu-cn/ldc/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/yu-cn/ldc/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/yu-cn/ldc/releases/tag/v0.1.0
