# LDC v1 规格（摘要）

> 完整背景见 docs/adr/（原仓库根 HANDOFF.md 交接文档已于 v1 收官后移除，历史见 git 首提）。本文件是 .scratch 工单流的规格锚点。

## 目标

一条命令把任意 Ubuntu/Debian 机器收敛到声明状态——幂等、可重放、可迁移。第一台接入机器：DGX Spark（Ubuntu 24.04, aarch64, sudo 需密码）。

## 已锁定决策（2026-10-24 定稿）

| 决策点 | 结论 | ADR |
|---|---|---|
| 发行版范围 | Ubuntu/Debian（apt）先行；`pkg_install()` 薄抽象留多发行版缝 | — |
| 覆盖面 | 含 GNOME 桌面域，按需启用（无会话自动 SKIP） | 0005 |
| 交付节奏 | 完整骨架 + 本机接入试跑（root 阶段单条 sudo 命令交接给机主） | 0004 |
| 分层 | 声明式（纯文本清单）+ 编排（bash 脚本）+ dotfiles（符号链接） | 0002 |
| 自留地 | `~/.bashrc.local` 机制；nvm 共存不卸；gitidentity 占位护栏 | 0003 |
| 仓库 | 独立仓库不 fork WDC | 0001 |

## 验收口径

- `bash validate.sh` 全绿（bash -n + shellcheck(如在) + 清单格式）
- 本机 `bash bootstrap.sh`：root 走交接路径、user/dotfiles 实跑、桌面 SKIP，exit 2（有待办）
- `bash scripts/verify-machine.sh --quick`：预期 FAIL 仅「身份未填（护栏）」与「root 阶段待交接」两族，其余绿/SKIP
- 不替用户做首次 commit（身份未填）
