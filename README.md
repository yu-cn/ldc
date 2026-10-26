# LDC — 声明式 Linux 开发环境（Ubuntu/Debian）

> clone 之后一条命令，任何一台 Ubuntu/Debian 机器收敛到声明状态：软件、语言运行时、CLI 工具、GNOME 桌面偏好、dotfiles——幂等、可重放、可迁移。

[![validate](https://github.com/yu-cn/ldc/actions/workflows/validate.yml/badge.svg)](https://github.com/yu-cn/ldc/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

<p align="center">
  <a href="docs/demo.cast"><img src="docs/demo.gif" width="720" alt="ldc 终端速览：ldc / ldc plan / ldc verify --quick（约 4 秒循环播放）"></a>
</p>
<p align="center"><sub>↑ 速览：<code>ldc</code> 快照 · <code>ldc plan</code> 干跑预演 · <code>ldc verify --quick</code> 机器断言（源文件 <a href="docs/demo.cast">docs/demo.cast</a>）</sub></p>

基于 [WDC](https://github.com/yu-cn/wdc)（Windows + WSL 同思路仓库）的经验自建，独立仓库不 fork（[ADR-0001](docs/adr/0001-own-tree-not-fork-wdc.md)）。两仓为**对等的关联项目**：WDC 主管 Windows 侧，LDC 主管 Linux 侧（含 WSL Ubuntu），各自完整自闭环；WSL 的 Linux 收敛由 WDC 移交 LDC（[ADR-0007](docs/adr/0007-wdc-ldc-coordination.md)）。仓库以 [MIT](LICENSE) 开源，欢迎直接使用或 fork 改造成你自己的环境。

**支持的机器形态**：Ubuntu/Debian · **amd64 / arm64 双架构一等公民**（[ADR-0006](docs/adr/0006-dual-arch-first-class.md)），其它架构在 bootstrap 预检即失败。WSL Ubuntu 亦属 amd64 目标可直接跑；WDC 管理的发行版按 ADR-0007 走委托路径（一个发行版只归一个管理器）；无 systemd 的 WSL 建议 `LDC_SKIP_DOCKER=1`。

**安全与边界**：幂等重跑（已就位即跳过）· 只装不删、清单外不碰——无卸载清单，机器私有内容不受影响（[ADR-0003](docs/adr/0003-universal-core-and-machine-reserve.md)）· dotfiles 落点为模板渲染拷贝——仓库缺席不影响已收敛机器；纯模板更新直接重渲染（渲染账本判定），机器侧改动覆盖前必备份 `*.bak`（[ADR-0015](docs/adr/0015-copy-render-not-symlink.md)）· Docker daemon 只做受保护合并，绝不自动重启（[ADR-0009](docs/adr/0009-docker-daemon-protected-merge.md)）。动手前想先看？`ldc plan` 干跑预演「重跑会做什么」，只读零变更。

## 快速开始（新机器）

零前置——一条命令（缺 git/curl 自动经 apt 安装，sudo 需密码的机器就地询问）：

```bash
curl -fsSL https://raw.githubusercontent.com/yu-cn/ldc/main/scripts/get.sh | bash
```

get.sh 是唯一的远程引导脚本：缺 git/curl 自动 apt 安装 → 定位或 clone 仓库（`~/.ldc` 指针有效则复用，缺省 clone 到 `~/ldc`）→ 直接进入 bootstrap 全流程。`curl | bash` 属于直接执行网络代码——介意可先[审阅 get.sh](scripts/get.sh)再粘贴；求稳可钉版本：`curl -fsSL https://raw.githubusercontent.com/yu-cn/ldc/main/scripts/get.sh | bash -s -- <tag>`（clone 后 checkout 该 tag，tag 清单见 GitHub Releases）。偏好手动管理的等价两行（git/curl 需自备，`sudo apt install -y git curl`）：

```bash
git clone https://github.com/yu-cn/ldc.git ldc && cd ldc
bash bootstrap.sh
```

fork 改造成自己环境的用户在引导命令前设 `LDC_REPO` 指向自己的仓库（`LDC_REPO=https://github.com/<你>/ldc.git curl -fsSL https://raw.githubusercontent.com/yu-cn/ldc/main/scripts/get.sh | bash`，同样一条命令），或把手动路径的 clone 地址换成你的仓库——`ldc sync` 跟随你 clone 的远端；直接使用者保持上面的地址，`ldc sync` 一键跟进上游演进。

七阶段：预检 → 无副作用校验 → root 阶段 → user 工具 → 桌面 → dotfiles → 汇总，全程日志落 `logs/bootstrap-<时间戳>.log`。重跑幂等：已就位的全部跳过。收敛完成后验收：`bash scripts/verify-machine.sh`（全绿即与声明一致）。

**sudo 需密码的机器**（服务器常态）：bootstrap 不打断、不静默——root 阶段留待交接，末尾打印单条命令：

```bash
cd <repo> && sudo bash scripts/install-packages.sh
```

退出码：`0` 全部就绪 · `1` 有失败 · `2` 有待办手工步骤（root 交接 / `~/.gitidentity` 未填 / 桌面待登录重跑）。

<details>
<summary><strong>首次运行你需要配合的四件事</strong></summary>

1. **root 阶段交接**——sudo 需密码时按末尾打印的命令手动执行（agent/CI 无法替你输密码）
2. **填写身份**——bootstrap 生成 `~/.gitidentity` 占位后，填上**本机**的 git name/email（占位未填则 git 拒绝提交，这是防错护栏），然后做首次 commit：`git add -A && git commit -m "Initial LDC scaffold"`
3. **桌面域**——有 GNOME 的机器在 SSH 上下文会 SKIP，登录桌面会话后重跑 `bash bootstrap.sh`（或 `ldc sync`）应用 gsettings 与字体
4. **关闭 VSCode 设置同步**（桌面应用域机器）——首次启动 VSCode 若已登录账号，关闭「设置同步」：它是账号级开关、配置文件管不到；不关的话云端会与仓库 dotfiles 打架（仓库是唯一主人）

</details>

<details>
<summary><strong>一条命令得到什么</strong>（点开看完整清单）</summary>

**系统**（root 阶段，[base-linux](configs/base-linux.pkg) + [cli-tools](configs/cli-tools.pkg)）
build-essential · git · curl/wget · jq · fzf / ripgrep / bat / fd / zoxide / eza / git-delta / tree / htop / shellcheck · gh（官方 apt 源）· Docker Engine（已装则跳过，默认用户入 docker 组；daemon.json [受保护合并](configs/docker-daemon.json)声明日志轮转与 live-restore——机器自有键保留，不自动重启，[ADR-0009](docs/adr/0009-docker-daemon-protected-merge.md)）

**可选包组**（不随 bootstrap，[ADR-0010](docs/adr/0010-optional-package-groups.md)）
常用但非每台必需的工具按组平铺在 [configs/](configs/)（[media-doc](configs/media-doc.pkg)：pandoc + ffmpeg · [etckeeper](configs/etckeeper.pkg)：/etc 纳入 git 审计，apt 事务与机主自改全程留痕），`sudo bash scripts/install-packages.sh <组名>` 显式指名安装——装没装由 dpkg 记账，verify 不断言；新增可选组只需加一个清单文件。

**语言运行时**（user 阶段）
Node 归 **vp**（[版本钉 configs](configs/vp-version)，默认跟随 LTS）、Python 归 **uv**——与 WDC 两侧同工具同习惯；机器已有的 nvm 等属自留地，共存不卸载（[ADR-0003](docs/adr/0003-universal-core-and-machine-reserve.md)）

**CLI 增强**（user 阶段，版本钉 configs）
starship 提示符 · lazygit · JetBrainsMono NF 字体（仅桌面栈机器）

**GNOME 桌面域**（按需启用，[desktop.gsettings](configs/desktop.gsettings)，[ADR-0005](docs/adr/0005-desktop-domain-on-demand.md)）
暗色主题 · 24h 时钟（含星期几）· 关热角 · 字体渲染 rgba/slight · Nautilus 显示隐藏文件 · 隐私去噪（关最近文件/应用使用记录）· 触摸板轻触 · Ubuntu Dock 点击最小化 · **中文输入源保底**（美式键盘 + ibus-rime 中州韵，词库走雾凇拼音）——无桌面会话自动 SKIP；发行版无对应组件的条目自动跳过

**桌面应用域**（桌面栈机器启用，[ADR-0008](docs/adr/0008-desktop-apps-domain.md)）
VSCode（packages.microsoft.com 源）+ [30 个扩展](configs/vscode-extensions.txt)（Python/Jupyter 全家、Remote-SSH/容器、中文语言包等）+ Chrome（dl.google.com 源）+ ibus-rime——双架构对称（两家厂商源均有 arm64/amd64）；扩展清单与 WDC 同名同格式，自装扩展不核销

**dotfiles**（[dotfiles/](dotfiles/)，渲染拷贝安装（[ADR-0015](docs/adr/0015-copy-render-not-symlink.md)），覆盖前备份 `*.bak`）
bashrc（历史/别名/fzf/zoxide/starship + 工具布局事实 [env.sh](scripts/install-user-tools.sh) + 末尾 `.bashrc.local` 机器自留地）· gitconfig（delta / rerere / zdiff3；身份经 `~/.gitidentity` 每机本地提供）· starship.toml · VSCode settings/keybindings（桌面应用域机器）

</details>

## 常用命令

`ldc` 由 bootstrap 链接到 `~/.local/bin/ldc`——任意目录可用，无需进仓库（对齐 wdc 的裸命令体验）。

| 命令 | 用途 |
|---|---|
| `ldc` | 只读快照（裸命令默认，秒级）：远端差距 / dotfiles 漂移 / 身份 / root 阶段 / 最近 bootstrap |
| `ldc plan` | 干跑预演（只读零变更）：重跑收敛会做什么——sudo/重跑前先看一眼 |
| `ldc sync` | 日常一键同步（fetch → pull --ff-only → bootstrap → verify 全量） |
| `ldc verify [--full]` / `ldc audit` | 机器断言（默认 --quick）/ 清单准入对账（自装未声明 / 已声明未装，只读） |
| `ldc triage` / `ldc log` / `ldc help` | dotfiles 落点漂移分流 / 最近日志尾部 / 帮助与版本 |
| `bash bootstrap.sh` | 完整收敛（日常改了配置后重跑） |
| `bash validate.sh` | 只做无副作用校验（bash -n + shellcheck + 清单格式） |
| `bash scripts/verify-machine.sh [--quick]` | 机器断言的脚本直跑形态 |

## 各层职责（ADR-0002）

```
configs/    声明式层：包清单（base-linux / cli-tools / 可选包组）· gsettings 清单 · 版本钉子
scripts/    编排层：bootstrap 各阶段、CLI、断言、预演、漂移分流
dotfiles/   dotfiles 层：linux / shared 两处，渲染拷贝安装（覆盖前备份 *.bak，ADR-0015）
```

- git 身份不入仓库：模板 include 每机本地的 `~/.gitidentity`
- Node 全权归 **vp**（钉 1.3.0），Python 全权归 **uv**；机器已有运行时管理器（nvm 等）属自留地，共存不卸
- shell 机器自留地：`~/.bashrc.local`（模板最末尾加载，别名可覆盖模板）
- 桌面域按需启用：无 D-Bus 会话自动 SKIP，不制造假 FAIL

## 新开发机接入（机器对等，任意台可重复）

1. 该机上跑「快速开始」一条命令（或手动 `git clone` 本仓库 → `bash bootstrap.sh`）→ 按提示完成 root 交接与身份填写
2. 验收：`bash scripts/verify-machine.sh`（全绿即与声明一致）
3. 机器改进直接 push `main`（pre-commit 钩子把关：shellcheck 已装则硬把关，未装警告放行、CI 兜底）；个性需求走 `~/.bashrc.local` 自留地，不进仓库

## 文档

- 词汇表：[GLOSSARY.md](GLOSSARY.md) · 决策：[docs/adr/](docs/adr/) · 面向 agent 的红线：[AGENTS.md](AGENTS.md) · 更新日志：[CHANGELOG.md](CHANGELOG.md)（Keep a Changelog）
- 首屏演示由 [docs/demo.cast](docs/demo.cast)（asciinema v2 录播，真实命令输出脱敏生成）经 [agg](https://github.com/asciinema/agg) 转 GIF 嵌入——`asciinema play docs/demo.cast` 可原速回放
- 工单与规格：`.scratch/`（作者的本地 markdown 工单流）

## 许可证

[MIT](LICENSE) © [yu-cn](https://github.com/yu-cn)
