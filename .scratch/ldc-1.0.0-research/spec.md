# spec · LDC 1.0.0 立项研究（WDC 1.0.0 发布后启动）

## 定夺

主人 2026-11-22：「wdc 做完后，让 ldc 研究下 1.0.0 应该做什么」——WDC 1.0.0 收官后，LDC 启动同号里程碑的立项研究（grilling/调研会话，非直接开工）。

## 已备事实（WDC 1.0.0 收官批沉淀，研究起点）

- **承诺面对齐现状**：退出面已齐（ADR-0024 `ldc exit` 同构落地，2026-11-22）；一次性姿态已对齐（ADR-0022 镜像）。LDC 距 1.0.0 的差距比 WDC 收官前小。
- **WDC 1.0.0 门槛清单可作参照**（`.scratch/v1-program/issues/04-release-1.0.0-checklist.md`）：CI 全环（已加 exit 腿）/双机终验/文档一致/CHANGELOG 收节/SemVer 宣告/效果优先 notes。
- **候选研究题**（来自 WDC 侧对话沉淀，供 grilling 展开）：
  1. LDC 有没有 WDC 已做的对应物缺口：pre-install 快照等价物（apt 侧无注册表，等效物=？dpkg 状态导出？可能不必要）；undo 表等价物（apt 面可机械推导？）；clean-legacy 等价（LDC 历史残留清单：vp 迁移已随航、rc 残留？）
  2. 双仓对照研究（WDC docs/research/v1-comparison.md 同款：上游 wsl-comfort 对照已封卷，LDC 的对照对象=？Debian/Ubuntu 官方 dev setups / dotfiles 管理器生态）
  3. 1.0.0 承诺面定义 + 里程碑加持项（demo 重录、README 翻新、升级指引）
  4. 双仓版本节奏：LDC 1.0.0 与 WDC 1.0.0 是否同号同日（联动面=姿态对齐批已发各自仓；§5 判据）

## 边界

- 本票只立项研究（grilling 一次一问），研究产出 spec + 工单群后再开工
- LDC 侧规矩：决策归环境主人；工具镜头/桌面域边界等既有定夺不翻案

## 移交快照（2026-11-22 主人定夺：LDC 后续工作移交 ZCode 对应 LDC 项目会话推进）

**新会话开场路径**：读 `AGENTS.md` → 本 spec → `CHANGELOG.md` Unreleased（1.0.0 记账已积累）→ `git log --oneline -8`。

**已齐面（勿重做）**：一次性姿态（ADR-0022）/ VSCode 全让位（ADR-0023 含修订：扩展+设置+键位）/ `ldc exit`（ADR-0024，fresh-container 四架构全绿含装了→退→退了→装全环腿，run 44930860595）/ undo 表 + 升级指引（docs/undo-table.md、docs/upgrade-v1.md）/ 契约面与 WDC 同步（cli-parity 双仓命令面含 exit ✓）。

**待推进**：① grilling（候选题四道在上方，需主人）→ 产出 1.0.0 spec+工单群；② demo 评估（命令集未大变，caption 已新——大概率仅微调或跳过）；③ **发布汇合点两选一（主人定）**：与 WDC 1.0.0 同号同日（exit 批契约联动成立，tag/release 同会话——需与 WDC 会话协同）或随后独立发；④ CHANGELOG 收节 + SemVer 宣告 + 效果优先 notes（参照 WDC docs/changelog-standard.md 双仓同源 + `.scratch` 工单04 同款门槛制）。

**双仓纪律提醒**：cli-parity / dev-standard / changelog-standard 三文件双仓同源（主作者位 LDC）；改命令面先改本仓契约再由 WDC 侧拷贝；WDC 侧发布动作不依赖 LDC（各自仓各自发，仅同号同日选项需协同）。
