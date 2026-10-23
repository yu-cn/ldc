# LDC — 声明式 Linux 开发环境（Ubuntu/Debian）

> clone 之后一条命令，任何一台 Ubuntu/Debian 机器收敛到声明状态：软件、语言运行时、CLI 工具、GNOME 桌面偏好、dotfiles——幂等、可重放、可迁移。

基于 [WDC](https://github.com/yu-cn/wdc)（Windows + WSL 同思路仓库）的经验自建，独立仓库不 fork（[ADR-0001](docs/adr/0001-own-tree-not-fork-wdc.md)）；两仓库为**关联项目、统筹演进**（[ADR-0007](docs/adr/0007-wdc-ldc-coordination.md)）：WDC 管 Windows 侧与 WSL 生命周期，Linux 机器内部（含 WSL Ubuntu）的收敛归 LDC。仓库以 [MIT](LICENSE) 开源，欢迎直接使用或 fork 改造成你自己的环境。

**支持的机器形态**：Ubuntu/Debian · **amd64 / arm64 双架构一等公民**（[ADR-0006](docs/adr/0006-dual-arch-first-class.md)），其它架构在 bootstrap 预检即失败。WSL Ubuntu 亦属 amd64 目标可直接跑；WDC 管理的发行版按 ADR-0007 走委托路径（一个发行版只归一个管理器）；无 systemd 的 WSL 建议 `LDC_SKIP_DOCKER=1`。

## 一条命令得到什么

**系统**（root 阶段，[base-linux](configs/base-linux.pkg) + [cli-tools](configs/cli-tools.pkg)）
build-essential · git · curl/wget · jq · fzf / ripgrep / bat / fd / zoxide / eza / git-delta / tree / htop / shellcheck · gh（官方 apt 源）· Docker Engine（已装则跳过，默认用户入 docker 组）

**语言运行时**（user 阶段）
Node 归 **vp**（[版本钉 configs](configs/vp-version)，默认跟随 LTS）、Python 归 **uv**——与 WDC 两侧同工具同习惯；机器已有的 nvm 等属自留地，共存不卸载（[ADR-0003](docs/adr/0003-universal-core-and-machine-reserve.md)）

**CLI 增强**（user 阶段，版本钉 configs）
starship 提示符 · lazygit · JetBrainsMono NF 字体（仅桌面栈机器）

**GNOME 桌面域**（按需启用，[desktop.gsettings](configs/desktop.gsettings)，[ADR-0005](docs/adr/0005-desktop-domain-on-demand.md)）
暗色主题 · 24h 时钟 · 显示日期 · 关热角 · Nautilus 显示隐藏文件 · 触摸板轻触点击——无桌面会话自动 SKIP，登录桌面后重跑 bootstrap 应用

**dotfiles**（[dotfiles/](dotfiles/)，符号链接安装，旧文件备份 `*.bak`）
bashrc（历史/别名/fzf/zoxide/starship + 末尾 `.bashrc.local` 机器自留地）· gitconfig（delta / rerere / zdiff3；身份经 `~/.gitidentity` 每机本地提供）· starship.toml

## 快速开始（新机器）

前置：装好 git 与 curl（`sudo apt update && sudo apt install -y git curl`）。然后：

```bash
git clone <你的仓库地址> ldc && cd ldc
bash bootstrap.sh
```

七阶段：预检 → 无副作用校验 → root 阶段 → user 工具 → 桌面 → dotfiles → 汇总，全程日志落 `logs/bootstrap-<时间戳>.log`。重跑幂等：已就位的全部跳过。

**sudo 需密码的机器**（服务器常态）：bootstrap 不打断、不静默——root 阶段留待交接，末尾打印单条命令：

```bash
cd <repo> && sudo bash scripts/install-packages.sh
```

退出码：`0` 全部就绪 · `1` 有失败 · `2` 有待办手工步骤（root 交接 / `~/.gitidentity` 未填 / 桌面待登录重跑）。

<details>
<summary><strong>首次运行你需要配合的三件事</strong></summary>

1. **root 阶段交接**——sudo 需密码时按末尾打印的命令手动执行（agent/CI 无法替你输密码）
2. **填写身份**——bootstrap 生成 `~/.gitidentity` 占位后，填上**本机**的 git name/email（占位未填则 git 拒绝提交，这是防错护栏），然后做首次 commit：`git add -A && git commit -m "Initial LDC scaffold"`
3. **桌面域**——有 GNOME 的机器在 SSH 上下文会 SKIP，登录桌面会话后重跑 `bash bootstrap.sh`（或 `ldc sync`）应用 gsettings 与字体

</details>

## 常用命令

| 命令 | 用途 |
|---|---|
| `ldc` | 只读快照（裸命令默认，秒级）：远端差距 / dotfiles 漂移 / 身份 / root 阶段 / 最近 bootstrap |
| `ldc sync` | 日常一键同步（fetch → pull --ff-only → bootstrap → verify 全量） |
| `ldc verify [--full]` / `ldc triage` / `ldc log` / `ldc help` | 机器断言（默认 --quick）/ dotfiles 写穿分流 / 最近日志尾部 / 帮助与版本 |
| `bash bootstrap.sh` | 完整收敛（日常改了配置后重跑） |
| `bash validate.sh` | 只做无副作用校验（bash -n + shellcheck + 清单格式） |
| `bash scripts/verify-machine.sh [--quick]` | 机器断言的脚本直跑形态 |

## 各层职责（ADR-0002）

```
configs/    声明式层：包清单（base-linux / cli-tools）· gsettings 清单 · 版本钉子
scripts/    编排层：bootstrap 各阶段、CLI、断言、漂移分流
dotfiles/   dotfiles 层：linux / shared 两处，符号链接安装（旧文件备份 *.bak）
```

- git 身份不入仓库：模板 include 每机本地的 `~/.gitidentity`
- Node 全权归 **vp**（钉 1.3.0），Python 全权归 **uv**；机器已有运行时管理器（nvm 等）属自留地，共存不卸
- shell 机器自留地：`~/.bashrc.local`（模板最末尾加载，别名可覆盖模板）
- 桌面域按需启用：无 D-Bus 会话自动 SKIP，不制造假 FAIL

## 新开发机接入（机器对等，任意台可重复）

1. 该机上 `git clone` 本仓库 → `bash bootstrap.sh` → 按提示完成 root 交接与身份填写
2. 验收：`bash scripts/verify-machine.sh`（全绿即与声明一致）
3. 机器改进直接 push `main`（pre-commit 钩子把关：shellcheck 已装则硬把关，未装警告放行、CI 兜底）；个性需求走 `~/.bashrc.local` 自留地，不进仓库

## 文档

- 词汇表：[GLOSSARY.md](GLOSSARY.md) · 决策：[docs/adr/](docs/adr/) · 面向 agent 的红线：[AGENTS.md](AGENTS.md)
- 工单与规格：`.scratch/`（作者的本地 markdown 工单流）

## 许可证

[MIT](LICENSE) © [yu-cn](https://github.com/yu-cn)
