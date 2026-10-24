# AGENTS.md — 在本仓库干活的 agent 请先读

LDC：一条命令把 Ubuntu/Debian 机器收敛到声明状态（幂等、可重放、可迁移），思路与结构对齐 [WDC](https://github.com/yu-cn/wdc)。

## 语言与风格

- 文档、脚本注释、脚本输出**全中文**（对齐 WDC 习惯）；bash 脚本 `#!/usr/bin/env bash` + `set -uo pipefail`
- 例外：`.githooks/pre-commit` 为有意的 POSIX `sh`（钩子在最小环境也要能跑），不套用 bash 条款
- 输出口径统一走 `scripts/lib/common.sh` 的 `phase` / `step`（与 bootstrap/verify 同一观感）
- 提交信息遵循 Conventional Commits 1.0.0，完整开发规范（分支提交 / 工单 / ADR / 关卡 / 发布 / 双仓统筹）见 [CONTRIBUTING.md](CONTRIBUTING.md)（对外）与 [docs/dev-standard.md](docs/dev-standard.md)（对内，双仓同源、主作者位 LDC）——本文只留红线级摘要：feat/fix 驱动版本号（v0.x 破坏性走 MINOR）、已推送历史不回改（tag 锚定）、锚点走正文或 trailer 脚注
- ADR 风格：短、含取舍与「拒绝的替代」；新决策先写 ADR 再动代码

## 结构速览

- `configs/` 声明式层（清单与版本钉子；可选包组平铺其中——指名安装、不进断言，ADR-0010） · `scripts/` 编排层 · `dotfiles/` dotfiles 层（ADR-0002）
- `bootstrap.sh` 唯一入口 · `validate.sh` 无副作用校验 · `ldc` CLI · `scripts/verify-machine.sh` 机器断言 · `scripts/plan-machine.sh` 干跑预演（只读）
- `CONTRIBUTING.md` 对外贡献指南 · `docs/dev-standard.md` 内部开发规范（双仓同源，主作者位 LDC，ADR-0012）

## 姊妹仓库 WDC 统筹（ADR-0007）

LDC 与 WDC 同主人关联项目，改动需跨仓库统筹：

- **Linux 侧模板主作者位在 LDC**：`dotfiles/linux/` 与 WDC 的 `dotfiles/wsl/` 是同源拷贝，WDC 侧已冻结待退役——改 Linux 侧 shell/git/提示符习惯只改 LDC，勿反向同步
- **钉子同值**：`configs/vp-version` 与 WDC 的同名文件保持同值，升级同日双改、两仓库各自记账
- **WSL 委托契约**：WDC 的 WSL 阶段最终形态是调用 LDC（clone/pull → root 委托 install-packages.sh → user 委托 bootstrap.sh → 验收委托 verify --quick）；改动 bootstrap 各阶段脚本的入口契约（参数、退出码、独立可跑性）前先想 WDC 调用方

## 红线（改动前自查）

1. **版本钉子单一来源**：vp/lazygit/starship/nerd-fonts 的版本只存在 `configs/*-version`，升级只改这一个文件，脚本与断言都读它（starship 的 rust 资产命名与 lazygit 的 x86_64 例外都在 install-user-tools 调用点注释）；starship/lazygit/nerd-fonts 的 sha256 行（`sha256 [amd64|arm64] <hex>`）与版本行同文件同次更新、重算自官方 release 资产（ADR-0011）
2. **`.bashrc.local` / `.gitconfig.local` 是机器自留地**：永不入仓库、永不覆写（已存在只提示）；nvm 属自留地，不卸载、不主动清理（LDC 是「只装不删」语义，无移除清单——WDC 的 remove-leftovers 不搬过来）
3. **git 身份不入仓库**：模板经 `[include] path = ~/.gitidentity` 引用；占位文件的 name/email 必须保持注释态（这是「未填则拒提交」护栏生效的前提）
4. **dotfiles 落点是符号链接**：任何写穿（机器工具直改模板）都是漂移，verify 有断言、triage 负责分流
5. **不替用户做首次 commit**：身份未填时提交会造出占位作者污染历史；交接命令见 README/AGENTS 惯例
6. **install-packages.sh 必须可独立 `sudo bash` 运行**（ADR-0004 交接命令依赖此性质）
7. **exit 码语义**：0 就绪 / 1 失败 / 2 有待办手工步骤——`ldc status` 与 CI 依赖此约定
8. **架构适配单点**（ADR-0006）：新增二进制下载一律经 `ldc_arch()` 取资产段（amd64/arm64），勿散落 `uname -m` 判断；CI 双架构冒烟矩阵是承诺的验证面
9. **daemon.json 只做受保护合并**（ADR-0009）：jq 递归合并，声明叶键胜出、机器自有键保留，绝不整文件接管、绝不自动重启 docker
10. **可选包组不进断言面**（ADR-0010）：通用核心之外的清单（configs/ 下 base-linux/cli-tools/desktop-apps 以外的 .pkg）只经 install-packages.sh 显式指名安装，装没装由 dpkg 记账——不进 verify / root_stage_complete，不建激活文件、不做交互选择

## 修改后的自查

```bash
bash validate.sh                      # bash -n + shellcheck（如在）+ 清单格式
bash scripts/verify-machine.sh --quick # 本机断言（只读）
bash scripts/plan-machine.sh           # 干跑预演（只读）——改安装面后看投影是否符合预期
```

交付涉及提权/桌面/身份时，如实报告待办，不要把 SKIP/PENDING 说成 OK。

## 已知坑

1. **仓库缺席 → 系统配置死链失联**（2026-10-25 定性，实录自 WDC 侧同构事故，WDC 侧条目见其 docs/agents/collaboration.md 坑15）：`~/dev/ldc` 被删则 `~/.gitconfig` / `~/.bashrc` / `~/.config/starship.toml` 三条符号链接全变死链——Ubuntu 内 git 一切命令 fatal（**死链挡 clone 本身**，实测 exit 128）；bash/starship 静默降级；`~/.gitidentity` 不入仓库故幸存。两仓失效面互相隔离：删 LDC 不影响 Windows 侧（WDC 链接），反之亦然。恢复（无需提权）：`rm -f ~/.gitconfig` → `git clone https://github.com/yu-cn/ldc.git ~/dev/ldc`（同路径则 bashrc/starship 链即刻复活）→ `bash bootstrap.sh` 重链（install-dotfiles.sh 的 ln -sfn 天然覆盖死链）→ `bash scripts/verify-machine.sh --quick` 验收。WDC 的官方重装路径（install-wsl-env.ps1 → setup-ubuntu.sh ensure_ldc）已补死链预清，可自愈。
