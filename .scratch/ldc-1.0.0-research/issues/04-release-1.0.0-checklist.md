# 04 v1.0.0 发布 checklist（门槛制——不达标不发；发布动作待主人 explicit 指令）

Status: open（等待工单 02/03 收口 + 主人汇合点定夺）
Type: task

## 门槛

- [x] 工单 02/03 收口（内容批 34e3740 / demo c58d652）
- [x] fresh-container 四架构 dispatch 复跑绿（run 44934727486 @ c58d652 全绿：handoff + ubuntu-24.04/debian-13 × amd64/arm64 四腿——发布时点新 HEAD 实证）
- [x] 本机终验：`ldc sync` 收敛至 c58d652、收敛账本记形态级终态（exit 2=桌面域 N/A 待办，WSL 机器契约语义）→ `verify --quick` 全绿 exit 0（实机口径：单机本机 WSL Ubuntu）
- [ ] （可选，主人窗口）本机全环回归：`ldc exit --yes` → bootstrap → verify 全绿——存量机降级路径终极实证（对应 WDC LETH 回归环；CI 已覆盖 fresh 半场）
- [x] 文档一致终查：README / docs/undo-table.md / docs/upgrade-v1.md / ADR-0022/0023/0024 / cli-parity——零陈旧引用（vscode-extensions/settings 残留扫描零命中）、exit 口径与 ADR-0024 一致、ADR 互链齐（README 6 / undo 表 4 / 升级指引 3 处）；顺手修 validate.sh 假绿残留（80357bd）
- [ ] CHANGELOG 收节 v1.0.0（Unreleased → 版本节；compare 链续 v1.0.0...HEAD）
- [ ] release notes 效果优先：承诺面句置顶 / 存量机影响正面回答（链 docs/upgrade-v1.md）/ 叙事骨架五件展开 / 已知事项含 `LDC_TAG=v0.14.0` 钉版回退姿势
- [ ] 归档卫生：本批工单全归档

## 汇合点（两案备态——开跑前主人定夺；WDC 侧 checklist 门槛⑧已按 A 案铺路）

- **A 同号同日**：对齐 WDC 执行序——其③=本仓 CHANGELOG 收节 commit（WSL 内，LDC 会话做）→ ④ 双仓 tag v1.0.0 → ⑤ 双仓 release 同会话收口
- **B 随后独立发**：本仓自行 tag / release；WDC 侧门槛⑧由其会话改

## 发布执行序（主人指令后同会话）

① 门槛全勾 → ②（A 案）与 WDC 会话对表时点 /（B 案）径行 → ③ CHANGELOG 收节 commit → ④ tag v1.0.0 → ⑤ release（--latest，效果优先 notes）→ ⑥ 工单归档

## notes 草稿（发布会话取用，效果优先四段）

**一条命令，任何 Ubuntu/Debian 机器一次性配置到声明状态**

v1.0.0 承诺面：**一次性配置 · 显式更新/回归 · 完整退出 · 漂移不纠察**——bootstrap 跑一次即休眠，机器日常归你；跟进新声明 `ldc sync`，收回声明状态 `ldc exit`。

- **完整退出（本版最重要新件）**：`ldc exit [--yes|--keep-tools]`——apt 核心域卸载（共享资源豁免）+ 二进制卸载（数据面不动）+ dotfiles 落点 `.bak` 还原 + 状态删除；默认预演零变更。手工正典 [docs/undo-table.md](../docs/undo-table.md)
- **Linux 原生面**：双发行版 × 双架构四腿 CI 实证（Ubuntu 24.04+/Debian 13+）· apt + dpkg 账本——安装即记账、还原可机械推导（无注册表故无需快照）· gsettings 桌面域按需启用（含 ibus-rime 中文输入整链）· daemon.json 受保护合并绝不自动重启 · 可选包组自选语义
- **存量机升级**：一条 `ldc sync`——行为差异与建议手动两件见 [docs/upgrade-v1.md](../docs/upgrade-v1.md)

已知事项：姿态定版（ADR-0022，多机「随时全绿」收缩为手动时点对齐）· VSCode 扩展/设置/键位让位原生设置同步（ADR-0023，登录即回）· 1.0.0 起 SemVer 完整生效（破坏性走 MAJOR）· 需要停在 v0.14.0：get.sh 钉版 `bash -s -- v0.14.0`

## Comments

- 2026-11-22 开票（grilling 收口批；门槛结构对齐 WDC 04 同款）。
- **汇合点情报（2026-11-22 查证）**：WDC v1.0.0 已发布（UTC 2026-11-21T18:00 = 北京时间 11-22 02:00，末轮全环 run 44930767170 绿后 4 分钟收口）——**A 案「同号同日」按北京时间口径今天（11-22）内仍成立**，窗口开着；过今天则 A 案失效自动落 B 案。

## Comments

- 2026-11-22 开票（grilling 收口批；门槛结构对齐 WDC 04 同款）
