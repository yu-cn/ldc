# 存量机升级到 1.0.0 指引（LDC 版）

> 适用：已用旧版 LDC 收敛过的 Ubuntu/Debian 机器（WSL Ubuntu 走 WDC 委托路径或独立直用均可）。对齐 WDC docs/upgrade-v1.md。

## 一条命令

```bash
ldc sync
```

fetch → `pull --ff-only` → 全量 bootstrap → verify。sudo 需密码的机器照旧走 root 阶段交接（末尾打印单条命令）。幂等、落点 `.bak` 保护。

## 升级中自动发生什么（无需干预）

| 变化 | 对存量机的效果 |
|---|---|
| VSCode 扩展全让位原生设置同步（[ADR-0023](adr/0023-vscode-handoff-native-sync.md)） | 扩展清单与安装动作退役为 SKIP；已装扩展**原样保留**，转为账号同步自管 |
| 定位叙事（[ADR-0022](adr/0022-oneshot-posture-manual-update-reconverge.md)） | 零行为变更——`ldc sync` 改口「手动更新/回归入口」，漂移合法不纠察 |
| 新增 `ldc exit`（[ADR-0024](adr/0024-ldc-exit.md)） | 完整退出面就绪（声明面全退、数据面不动、默认预演） |

## 建议的手动事（升级前后皆可）

1. **登录 VSCode 开设置同步**——扩展/设置/键位随账号走（不开启也不坏：扩展冻结在当前版本）
2. WSL 内的机器顺带跑 `ldc audit` 看自装未声明面（对账口径，只报不裁）

## 可选：回退钉版

出问题可钉旧版重引导（get.sh 既有能力）：

```bash
curl -fsSL https://raw.githubusercontent.com/yu-cn/ldc/main/scripts/get.sh | bash -s -- v0.14.0
```

已装机器升级重跑同一命令带新 tag 即重钉。

## 新能力速览

- `ldc plan`——更新/回归前预演（漂移积累越久回归覆盖面越大，先看一眼）
- `ldc exit [--yes] [--keep-tools]`——完整退出（预演默认；共享资源豁免、数据面不动红线见 [undo 表](undo-table.md)）
