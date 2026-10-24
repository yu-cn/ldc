# 工单 01 — get.sh 远程一键引导 + README 快速开始改造

> Status: done（2026-10-25 同会话收口）

**目标形态：** 新机器在零前置（不预装 git/curl、不手动 clone）下，粘贴一条命令即可走完
「apt 装依赖（缺则）→ 定位/clone 仓库 → bootstrap 全流程」。

- [x] `scripts/get.sh`：`set -uo pipefail`；缺 git/curl 时 root 直装 / sudo 装 / 无 sudo 报错给手动命令；
      `~/.ldc` 指针复用 / `~/ldc` 缺省 clone（非仓库目录不代删）；转发 bootstrap 并透传退出码
- [x] README 快速开始：单条命令为入口 + 审阅链接 + 手动两行保留 + fork 说明；新开发机接入步骤同步
- [x] validate.sh 全绿（bash -n + shellcheck --severity=warning + 清单格式）

## Comments

- 2026-10-25（自主执行会话）：已完成。决策背景与否决项见同目录 spec.md。
  未做真机端到端试跑（会触发完整 bootstrap 收敛，超出无副作用边界）——覆盖面 =
  bash -n + shellcheck + 逻辑对齐 setup-ubuntu.sh ensure_ldc 既有姿势；
  首位真实用户跑通前保留手动两行兜底。姊妹仓库 WDC 侧同日对等实施（get.ps1）。
