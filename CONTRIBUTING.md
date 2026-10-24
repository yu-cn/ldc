# 贡献指南

这是作者的个人开发环境仓库（声明式 Linux 收敛），开源是为了参考与 fork——**最欢迎的用法是 fork 一份改成你自己的环境**，路径见 README「快速开始」与「新开发机接入」。

## 给本仓库提改进

- **判据**：只收「通用核心」——任何一台 Ubuntu/Debian 开发机都需要的改进（[ADR-0003](docs/adr/0003-universal-core-and-machine-reserve.md)）。机器个性化内容走你自己的 fork 与机器自留地（`.bashrc.local` 等机制）。
- **方式**：直接开 GitHub Issue / Pull Request。`.scratch/` 本地工单流是仓库主人自己的内部流程，与外部贡献无关。
- **CI**：PR 自动跑无副作用校验（`validate.sh`：bash -n + shellcheck + 清单格式），本地可先 `bash validate.sh` 自查。
- **语言**：散文用中文；标识符、命令、既定格式保持英文。

仓库主人自己的内部开发规范见 [docs/dev-standard.md](docs/dev-standard.md)（双仓同源，主作者位在 LDC）；外部贡献无需遵循其工单 / 发布流程。
