# 更新日志（CHANGELOG）

面向使用者的版本要点摘录；完整变更、决策 ADR 与验证锚点见各 [release](https://github.com/yu-cn/ldc/releases) 与 git log。发版时随 release notes 同步摘录本文件。

## v0.6.0 — dotfiles 渲染拷贝（ADR-0015）（2026-10-25）

- **dotfiles 落点反转符号链接模型**：改安装期渲染拷贝——仓库缺席不再影响已收敛机器（只剩 `ldc` CLI 自身，报错自带恢复指引）；机器侧直改落点不再污染仓库，verify/status 内容断言暴露、triage 分流（吸收/还原）；覆盖前轮转备份 `.bak`
- 工具布局事实外置 `~/.config/ldc/env.sh`——bashrc 模板不再硬编码 vp/fzf 路径，上游换布局只改安装器
- 同批：中文输入换代 ibus-rime+雾凇、assert_pin 三钉入断言面 + 红线 11「不重写包管理」、flock 运行锁（ADR-0013）、上游跟进机制（ADR-0014）、get.sh tag 钉版、CI 冒烟补幂等重跑段

## v0.5.0 — 零前置快速开始：get.sh 远程一键引导（2026-10-24）

- 新机器一条命令收敛：`curl -fsSL https://raw.githubusercontent.com/yu-cn/ldc/main/scripts/get.sh | bash`——缺 git/curl 自动 apt 装、`~/.ldc` 指针复用、转发 bootstrap
- fork 用户走手动 clone 两行（get.sh 写死上游地址）

## v0.4.0 — 可选包组、干跑预演与供应链钉（2026-10-24）

- 可选包组（ADR-0010）：清单即菜单、`sudo bash scripts/install-packages.sh <组>` 显式指名、dpkg 记账不进断言面（首个成员 media-doc）
- `ldc plan` 干跑预演：只读投影重跑会做什么（OK/PLAN/SKIP/INFO 四态）
- 供应链钉（ADR-0011）：starship/lazygit/字体版本 + sha256 同文件双钉，下载先校验后落盘

## v0.3.0 — WDC 委托落地与 Docker 配置域（2026-10-24）

- ADR-0007 双仓统筹从契约变事实：WSL 发行版环境由 WDC 委托 LDC 收敛，Linux 侧单一来源归位
- Docker daemon.json 受保护合并（ADR-0009）：声明叶键胜出、机器自有键保留、绝不自动重启

## v0.2.0 — 桌面应用域与 WDC 统筹（2026-10-24）

- 桌面 Linux 机的 GUI 软件纳入声明（ADR-0008：VSCode + 扩展清单 + Chrome，双架构厂商源对称）
- WDC↔LDC 双仓统筹定稿（ADR-0007）；CI 验证面扩到三腿（handoff + amd64/arm64 容器冒烟）

## v0.1.0 — 开源基线（2026-10-23）

- 首个发布锚点：bootstrap 七阶段收敛（预检 → 校验 → root 交接 → user 工具 → 桌面 → dotfiles → 汇总）、verify 断言、`ldc` CLI、dotfiles 机器自留地（ADR-0003）、双架构一等公民（ADR-0006）
