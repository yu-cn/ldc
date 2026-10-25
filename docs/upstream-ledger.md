# 上游吸收账本（ADR-0014）

记录每次对 microsoft/WindowsDeveloperConfig 的检查与吸收（对标面 = wsl-comfort，ADR-0014）。
基线的机器可读版本在 [upstream-baseline.json](./upstream-baseline.json)，由
`scripts/check-upstream.sh -UpdateBaseline` 维护。

## 检查记录

| 日期 | 上游 HEAD | 结论 | 备注 |
|---|---|---|---|
| 2026-10-25 | fb564611cf | 建立基线 | wsl-comfort apt 清单真源（`COMFORT_APT_*` 数组 15 包）；深版调研（2026-10-19，一手核实）在 wdc 仓 `docs/research/`，本仓视角见 [research/windowsdeveloperconfig.md](research/windowsdeveloperconfig.md) |

## 吸收记录

| 日期 | 吸收内容 | 上游来源 | 进入本仓库的位置 |
|---|---|---|---|
| 2026-10-25 | 运行锁思想（全局互斥防并发收敛） | 引擎 `Global\WindowsDevConfigSetup` | ADR-0013 / bootstrap.sh flock（对等实现；与 wdc 0ad0788 同源评估、各仓各面） |

（基线建立前的历史参考——Starship / 现代 CLI 工具等思路——经 wdc 调研间接完成，无独立账本可考，不补记。）
