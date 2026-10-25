# 分层应用模型：声明走纯文本清单，编排走 bootstrap，dotfiles 走仓库目录

覆盖面与应用机制定为三层（对齐 WDC ADR-0002 的分层思想，机制因平台而异）：

1. **声明式层**：软件包（`configs/*.pkg`）、桌面偏好（`configs/desktop.gsettings`）、版本钉子（`configs/*-version`）用纯文本清单声明——Linux 侧没有 winget configuration 那样自带 `validate/test` 的声明引擎，清单的可审查性由格式最小化保证（一行一事实），正确性由 verify 断言补位。
2. **编排层**：流程控制类步骤——sudo 交接（ADR-0004）、用户级二进制安装（vp/starship/lazygit/字体）、`.bashrc.local` 迁移——由 bootstrap 及 scripts/ 各阶段脚本负责。
3. **dotfiles 层**：`dotfiles/linux`、`dotfiles/shared` 作为仓库内独立目录版本化，由 bootstrap 符号链接安装（旧文件备份 `*.bak`）。**补注（2026-10-25）**：安装形态已改为渲染拷贝（[ADR-0015](0015-copy-render-not-symlink.md)）——「符号链接安装」条款自此被取代，分层本身不变。

关键取舍：不引入 Ansible/Salt 之类的配置管理引擎——单用户开发机的收敛用 600 行 bash 足以表达，引擎带来的 YAML/角色/jinja 抽象层与依赖管理成本不成比例；作为交换，失去引擎自带的漂移检测，由 `verify-machine.sh` 的断言组补位（无副作用、只读、可独立运行）。

**附注（gitconfig 编辑器决策）**：模板不设 `core.editor`。WDC wsl 版的 `editor = code --wait` 是 Windows 侧习惯，Linux 服务器无 code；编辑器属机器偏好（自留地判据），不设则走 git 默认链（`GIT_EDITOR`/`VISUAL`/`EDITOR`/vi），每台机器自行决定。相对 WDC wsl 版同时去掉 `longpaths`（Windows 专属），保留 `autocrlf = input`（跨平台协作仓库的主流约定）。拒绝的替代：设为 `nano`（替机器做主，且 nano 未必在）；Ansible 全托管（重）；纯脚本硬编码包列表（失去清单可审查性，WDC 的分层经验已证明声明与编排分离的价值）。
