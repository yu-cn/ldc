# 01 并行技术件——undo 表等价物 + 存量机升级指引 + README 翻新

Status: ready-for-agent
Type: task

## 定夺

主人 2026-11-22：LDC 侧 1.0.0 工作与 WDC 发布同步推进。技术件（机械推导/文档面）先行，grilling 穿插，发布动作为汇合点（同号同日或随后独立发，按 §5 联动判据定）。

## 内容

1. `docs/undo-table.md` 等价物：apt 核心域逐包卸载表（含共享资源豁免）+ 二进制 + dotfiles（.bak 语义）+ gsettings 桌面域 reset 指针 + Docker/状态面——`ldc exit`（ADR-0024）的手工对照正典
2. `docs/upgrade-v1.md` 等价物：存量机一条 `ldc sync` + 自动变化表（VSCode 扩展让位→登录同步是 LDC 侧真实迁移面 / 姿态叙事 / exit 新命令）+ 钉版回退姿势（get.sh 带 tag）
3. README「一条命令得到什么」核对翻新（口径与两让位后现状对齐）

## 验收

- [x] 两文档落地，与 ADR-0022/0023/0024 互链一致
- [x] README 无陈旧引用（核对抓出 VSCode 让位「README 先行、实现滞后」不一致——已补齐实现：dotfiles_map 7→5+模板除名+ADR-0023 修订）
- [x] validate 绿

## Comments

- 2026-11-22 开票即收（e8fb90f）。**移交注记**：主人定夺 LDC 后续工作移交 ZCode 对应 LDC 项目会话推进（WDC 会话不再驱动 LDC 实施面）；本票随批收口，frontier 由 `.scratch/ldc-1.0.0-research/spec.md` 的移交快照接管。
