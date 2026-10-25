# ADR-0014：上游跟进机制——人工挑选、结构化真源

LDC 的上游对标面是 microsoft/WindowsDeveloperConfig 的 **wsl-comfort**（apt 清单 /
Starship / 终端主题化 / 字体）；引擎包目录是 Windows 侧事务，归 wdc 对标（其深调研与
check-upstream 在 wdc 仓；wdc 9d1dc3b 修复了「全文件正则要求 X.Y/Z 带斜杠、抓不到真包
ID、基线被 URL/DSC 类型噪声灌满」的坑）。本仓建立同构但更小的跟进面：

- **真源直取**：wsl-comfort 的 apt 清单在 `comfort-shell-bootstrap.sh` 顶部两个
  `readonly COMFORT_APT_*` 数组——按数组名结构化提取，不做全文件正则（wdc 的坑不重踩）。
- **基线 + 账本**：`docs/upstream-baseline.json`（机器可读）+ `docs/upstream-ledger.md`
  （检查/吸收两表，人读）；`scripts/check-upstream.sh -UpdateBaseline` 固化新基线。
- **人工挑选**：脚本只出「上游新增 / 我方已有等价物」事实报告，绝不自动同步配置；
  移植决策归环境主人，吸收后账本记一笔。
- `ldc status` 距上次检查 >30 天提醒——只提醒不巡检（对齐 wdc）。

拒绝的替代：自动 PR 机器人同步（上游措辞与本仓语义不同源，自动吸收必踩 opinion 冲突，
且违背「事实自查、主人定夺」）；正则全文件扫描（wdc 实证的噪声路径）；两仓共享同一份
check-upstream（wdc 的 winget 包维度对 LDC 无意义，反过来亦然——各仓各面，账本互引）。
