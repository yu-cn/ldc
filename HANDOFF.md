# LDC 交接文档 — Linux 开发环境配置项目（写给下一个 zcode 会话）

> 生成于 2026-10-24。上一个会话完成了 WDC 调研、LDC 设计定稿、本机（DGX Spark）摸底，**尚未写任何代码文件**——本目录除本文档外应为空。请按「执行顺序」一节从第 1 步继续。

## 1. 任务背景

用户维护 [yu-cn/WDC](https://github.com/yu-cn/WDC)（Windows + WSL 开发环境的声明式配置仓库），要求借鉴其经验新建 **LDC**：一条命令把任意 Ubuntu/Debian 机器收敛到声明状态——幂等、可重放、可迁移。本机 DGX Spark 是第一台接入机器。

WDC 参考副本在 `/tmp/WDC`（`git clone --depth 1 https://github.com/yu-cn/WDC /tmp/WDC`，若被清理请重新克隆）。重点参考文件：
- `README.md`（理念与 UX 约定）、`docs/adr/0002`（分层模型）、`docs/adr/0003`（通用核心判据）
- `scripts/wsl/setup-ubuntu.sh`（root/user 两阶段原型）、`scripts/wdc.ps1`（CLI 体验约定：裸命令只读、改状态须显式子命令）
- `scripts/verify-machine.ps1`（断言式验收）、`dotfiles/wsl/bashrc`、`dotfiles/wsl/gitconfig`、`dotfiles/shared/starship.toml`（LDC 模板直接以此为基础）

## 2. 已锁定决策（用户确认，勿再问）

| 决策点 | 结论 |
|---|---|
| 发行版范围 | **Ubuntu/Debian（apt）先行**；`lib/common.sh` 留 `pkg_install()` 薄抽象，多发行版日后增量加 |
| 覆盖面 | **含 GNOME 桌面域**（用户明确选了此项，否掉了推荐的纯 headless）——做成按需启用的域，无桌面会话自动 SKIP |
| 交付节奏 | **完整骨架 + 本机接入试跑**：user 阶段 + dotfiles 直接在本机执行，root 阶段整理成单条 sudo 命令交给用户，最后 verify 出断言报告 |

## 3. 本机事实（DGX Spark，已摸底验证）

- Ubuntu 24.04.5（DGX OS），**aarch64**；sudo **需要密码**（agent 无法提权）
- `~/.bashrc` = 原生 Ubuntu 段 + dgx-spark 增强段（`# >>> dgx-spark ... >>>` / `# <<< dgx-spark <<<` 标记内，含 CUDA_HOME、alias gs=nvidia-smi 等）+ `. "$HOME/.local/bin/env"`（uv）+ nvm 块（`export NVM_DIR=...` 起三行）
- `~/.gitconfig` 仅 `[init] defaultBranch=main` + `[push] autoSetupRemote`——属通用核心，模板直接吸收
- 已装：git / curl / wget / uv 0.13.5（`~/.local/bin/uv`）/ node v22.23.4（**nvm 管理**）/ jq / docker（用户已在 docker 组）/ gsettings / fc-cache / build-essential / bash-completion / fontconfig
- 缺：starship / lazygit / delta / eza / fzf / fd / bat / zoxide / gh / shellcheck
- apt 可装 eza、git-delta（有 candidate，版本未细看）；`rg` 只存在于 /opt/ZCode（agent 自带，非机器配置，忽略）
- git 身份未配置（AGENTS.md：待用户提供）→ 正好用 LDC 的 `~/.gitidentity` 占位机制

**上一会话最后一条验证命令被用户取消，以下三项未确认，开工前先补跑**：
1. `apt-cache policy eza git-delta shellcheck fzf fd-find ripgrep bat zoxide` 的完整 Candidate 行
2. lazygit 最新 release tag（GitHub API，arm64 资产名为 `lazygit_<ver>_Linux_arm64.tar.gz`）
3. nerd-fonts 最新 release tag（JetBrainsMono.zip）及 `curl -sI https://vite.plus/sh` 可达性

## 4. 设计蓝图

### 目录结构

```
ldc/
├── bootstrap.sh              # 入口：预检 → 无副作用校验 → root 阶段(或交接) → user 工具 → 桌面 → dotfiles → 汇总
├── validate.sh               # 独立校验入口：bash -n 全部脚本 + shellcheck(如在) + 清单格式检查
├── ldc                       # CLI（bash）：status/sync/verify/triage/log/help/version
├── configs/
│   ├── base-linux.pkg        # build-essential git curl wget ca-certificates gnupg unzip zip jq bash-completion
│   ├── cli-tools.pkg         # fzf fd-find ripgrep bat zoxide eza git-delta tree htop fontconfig shellcheck
│   ├── desktop.gsettings     # 声明式 gsettings 清单（schema key value 一行一条）
│   ├── vp-version            # 钉 1.3.0（与 WDC 同钉子同习惯）
│   └── lazygit-version       # 钉最新 tag（开工时查）
├── scripts/
│   ├── lib/common.sh         # log/step 输出、have()、清单解析、apt 安装、sudo 形态探测
│   ├── install-packages.sh   # root 入口（可独立 sudo 运行）
│   ├── install-user-tools.sh # uv(跳过已装) vp starship lazygit 字体
│   ├── apply-desktop.sh      # gsettings 应用；无 D-Bus 会话 → SKIP
│   ├── install-dotfiles.sh   # 符号链接 + .bak + bashrc.local 迁移 + gitidentity 占位 + ~/.ldc 指针 + hooksPath
│   ├── verify-machine.sh     # 分组断言，--quick 秒级
│   └── triage-dotfiles-drift.sh
├── dotfiles/
│   ├── linux/bashrc          # 以 WDC wsl/bashrc 为基础，末尾加 source ~/.bashrc.local
│   ├── linux/gitconfig       # 以 WDC wsl/gitconfig 为基础（见下方改动点）
│   └── shared/starship.toml  # 与 WDC 同款原样复制
├── docs/adr/0001..0005.md · GLOSSARY.md · AGENTS.md · README.md · LICENSE(MIT © yu-cn)
├── .githooks/pre-commit      # shellcheck 已装则硬把关，未装则警告放行（CI 兜底）
├── .github/workflows/validate.yml · fresh-container.yml
├── .gitattributes(* text=auto eol=lf) · .gitignore(logs/) · .scratch/dev-env/(spec + 工单01)
```

### 关键机制（均已定稿，实现时照此）

1. **root/user 两阶段 + sudo 交接（ADR-0004）**：bootstrap 以普通用户运行；EUID=0（容器）直接跑 root 阶段；`sudo -n true` 通过（免密）则 `sudo bash scripts/install-packages.sh`；否则**末尾打印单条交接命令**（本机即此形态），exit 码 2 表示「有待办手工步骤」。`install-packages.sh` 必须可独立 `sudo` 运行。
2. **`~/.bashrc.local` 机器自留地（ADR-0003 核心机制）**：install-dotfiles 首次接管 `~/.bashrc` 时——整文件备份 `~/.bashrc.bak`；抽取全部 `# >>> ... >>>`..`# <<< ... <<<` 标记块与 nvm 块（NVM_DIR 起三行）写入 `~/.bashrc.local`（已存在则不覆盖只提示）；其余差异留在 .bak 由用户自行搬运（bootstrap 输出里说明）。模板 bashrc **最末尾** source `.bashrc.local` → 机器段后加载、别名可覆盖模板（本机 gs=nvidia-smi 覆盖模板 gs='git st'，符合机主意图）。新机器无标记则创建带注释的空 .local。
3. **nvm/vp 共存**：按政策安装 vp（钉 1.3.0，`vp env default lts && vp env install lts && vp env on`，安装器 `curl -fsSL https://vite.plus/sh | bash` 注意用 bash 非 sh）；**不卸 nvm、不进移除清单**（自留地）。本机 node 仍走 nvm（.local 后加载胜出），verify 只断言 `vp --version == 钉子` 与 node 可用，不断言 node 走 vp shim。
4. **Debian 命名兼容**：root 阶段 `ln -sf $(command -v fdfind) /usr/local/bin/fd`、batcat→bat（存在才做，幂等），否则模板别名断链。
5. **gitidentity 护栏**：缺 `~/.gitidentity` 则生成占位（注释+占位 name/email），不填 git 拒绝提交（include 机制，照抄 WDC gitconfig 的 `[include] path = ~/.gitidentity`）。本机 git 身份本来就待用户提供——正好是首个落地案例。
6. **gitconfig 模板改动**（相对 WDC wsl 版）：去掉 `longpaths`（Windows 专属）；`autocrlf = input` 保留（WDC wsl 侧同款）；`editor = code --wait` 改动未定——建议改成不设 editor 或 `nano`（服务器没有 code），实现时定夺并记入 ADR-0002 附注。
7. **桌面域（ADR-0005）**：`desktop.gsettings` 每行 `schema key value`（value 带引号原样）。首批 6 条：`org.gnome.desktop.interface color-scheme 'prefer-dark'` / `clock-format '24h'` / `clock-show-date true` / `enable-hot-corners false`、`org.gnome.nautilus.preferences show-hidden-files true`、`org.gnome.desktop.peripherals touchpad tap-to-click true`。apply-desktop.sh 无图形会话（gsettings get 试探失败）→ SKIP 并提示「桌面登录后重跑 bootstrap」；verify 同理 SKIP。字体（JetBrainsMono NF zip → `~/.local/share/fonts/JetBrainsMono-NF/` + fc-cache -f）仅在有 gsettings 的机器装（免 sudo），版本钉 configs，目录存在即跳过。
8. **verify 断言组**：①dotfiles 符号链接 + 模板与 HEAD 一致（防写穿；**无任何 commit 时降级为 INFO 提示**，本机首跑即此态）+ hooksPath 接线 ②gitidentity 存在且非占位（未填=FAIL，是设计内护栏；容器冒烟用 `LDC_SMOKE=1` 降级为存在性检查）③包清单核销（dpkg -s 逐项）④语言栈（uv 在位、vp=钉子、node 可用）⑤桌面域（有会话才比对 gsettings 读值）。任一 FAIL exit 1。
9. **ldc CLI**：照 wdc.ps1 的体验约定——裸命令=status 只读快照（仓库 ahead/behind、dotfiles 漂移数、身份状态、root 阶段是否完成、最近 bootstrap 判定行）；`sync`=fetch→pull --ff-only→bootstrap→verify；`triage`=写穿漂移逐文件 吸收(a)/还原(r)/跳过(d)；`log`=logs/bootstrap-*.log 尾部；repo 定位用 `~/.ldc` 指针（bootstrap 写入）。打错子命令给「你是不是想输…」前缀建议。
10. **bootstrap 日志**：全程 tee 到 `logs/bootstrap-<时间戳>.log`，分阶段汇总 OK/PENDING/FAIL；`LDC_SKIP_DOCKER=1` 跳过 docker 域。
11. **install-packages.sh（root）**：apt-get update → 两清单逐包 dpkg -s 跳过/apt 装（逐包安装，失败收集不中断，结尾汇总非零退）→ fd/bat 兼容链接 → gh 官方 apt 源（keyring 方式，照抄 WDC setup-ubuntu.sh）→ docker：`command -v docker` 存在即跳过（本机已有），不存在才 get.docker.com + `usermod -aG docker $SUDO_USER`。
12. **CI**：validate.yml（ubuntu-latest：validate.sh，shellcheck runner 自带）；fresh-container.yml（ubuntu:24.04 容器内以 root 全量跑 bootstrap + verify，`LDC_SKIP_DOCKER=1 LDC_SMOKE=1`，workflow_dispatch + 周度 cron）——这是 Linux 侧对 WDC fresh-machine VM 冒烟的廉价替代。
13. **ADR 清单**：0001 独立仓库不 fork WDC / 0002 分层模型（无 winget 等价物 → 纯文本清单 + verify 断言补位）/ 0003 通用核心与自留地（.bashrc.local 机制、nvm 共存案例）/ 0004 root-user 两阶段与 sudo 交接 / 0005 桌面域按需启用。风格对齐 WDC：短、含取舍与「拒绝的替代」。
14. **git 仓库**：`git init`（defaultBranch=main 已全局配好）、`git config core.hooksPath .githooks`。**不要替用户做首次 commit**（身份未填会造出占位作者污染历史），交接命令见第 6 节。

## 5. 与 WDC 的关系

v1 完全独立仓库；dotfiles 语义对齐（同款 starship/gitconfig 习惯、同 vp 钉子）；将来 WDC 的 WSL 阶段可复用 LDC user 阶段属 YAGNI，只在 ADR-0001 记一句不实现。

## 6. 交付时给用户的手工步骤（汇总到最终报告里）

1. root 阶段：`cd /home/spark/dev/ldc && sudo bash scripts/install-packages.sh`（sudo 需密码，agent 不能代跑）
2. git 身份：编辑 `~/.gitidentity` 填本机 name/email，然后 `git add -A && git commit -m 'Initial LDC scaffold'`
3. 桌面域：登录 GNOME 桌面会话后重跑 `bash bootstrap.sh`（或 `ldc sync`）应用 gsettings 与字体

## 7. 执行顺序（下一会话照此推进）

1. `cd /home/spark/dev/ldc`；补跑第 3 节末尾三项未确认验证；`/tmp/WDC` 不在则重克隆
2. 写全部文件（第 4 节蓝图；bashrc 模板以 `/tmp/WDC/dotfiles/wsl/bashrc` 为基础改造）
3. `git init` + hooksPath 接线（不 commit）
4. `bash validate.sh` 全绿
5. `bash bootstrap.sh` 本机试跑：root 阶段应走「交接命令」路径，user/桌面/dotfiles 阶段实际执行（桌面在此 SSH 上下文应优雅 SKIP）
6. `bash scripts/verify-machine.sh --quick`，如实报告：预期 FAIL 项=身份未填（护栏）+ root 阶段待交接，其余应绿
7. 最终报告：做了什么/verify 结果/第 6 节三条手工步骤

## 8. 约束与坑（来自本机 AGENTS.md 与本会话实证）

- 用户偏好中文交流；LDC 文档、脚本注释、输出全中文（对齐 WDC 风格）
- aarch64：所有二进制下载走 arm64 资产；pip/wheel 注意 linux_aarch64（本项目仅 lazygit/字体/vp/starship 涉及）
- 本机 bashrc 的 dgx-spark 段约定「只追加不动原段」——.bashrc.local 迁移机制已满足（内容原样保留，仅换宿主文件）
- 不要动 `/usr/bin/python3`；uv 已在位走跳过路径；勿主动装 LLM 推理栈（用户暂缓令，与 LDC 无关但别顺手装）
- shellcheck 本机未装（在 cli-tools.pkg 里，root 阶段后才可用）——首次 validate.sh 本地只能 bash -n，pre-commit 设计成「未装则警告放行」正是为此

## 9. Suggested skills（下一会话按需调用）

- `implement` — 按本文档第 4/7 节落地骨架（本文档即 spec）
- `writing-for-agents` — 写 LDC 的 AGENTS.md / GLOSSARY.md / ADR 时
- `code-review` — 骨架完成自检一轮再交付
