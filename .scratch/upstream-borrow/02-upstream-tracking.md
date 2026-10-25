# 工单 02 — 上游跟进机制（research 笔记 + 吸收账本 + check-upstream.sh）

## 背景

LDC 无上游跟进面：docs/ 仅 adr 与 dev-standard，无 research 笔记、无吸收账本、无
check-upstream 等价物（2026-10-25 实证）。上游 wsl-comfort 与引擎仍在活跃演进
（2026-10-19～10-22 期间上游 HEAD 三易其值），LDC 的对标对象（apt 清单、Starship、
字体、终端主题化）恰是 wsl-comfort 的主战场。wdc 已建立全套纪律并踩平了一个坑：
check-upstream 的全文件正则抓不到 winget 包 ID（要求 X.Y/Z 带斜杠），基线被 URL/DSC
类型噪声灌满（wdc 9d1dc3b 修复）——LDC 直接抄修复后形态，不走弯路。

## 内容

- `docs/research/windowsdeveloperconfig.md`：LDC 视角的调研笔记（对标 wsl-comfort 的
  apt 数组、提示符、字体、终端 profile；一手来源纪律同 wdc）
- `docs/upstream-ledger.md`：吸收账本（检查记录 / 吸收记录两表）
- `docs/upstream-baseline.json` + `scripts/check-upstream.sh`：结构化抓取——上游
  wsl-comfort 的 apt 清单在 `comfort-shell-bootstrap.sh` 顶部数组（真源，无需正则猜），
  对比基线出「上游新增 / 我等价物」报告；`-UpdateBaseline` 等价旗标固化新基线；
  移植决策永远归环境主人，吸收后账本记一笔
- `ldc status` 加「距上次上游检查 >30 天提醒」（对齐 wdc 同款）

## 验收

- [ ] check-upstream.sh 只读可跑，报告可读；基线固化幂等
- [ ] 账本首行记录本工单（建立基线）
- [ ] validate.sh 全绿
