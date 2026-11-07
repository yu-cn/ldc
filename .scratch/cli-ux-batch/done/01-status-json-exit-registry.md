# 工单01：ldc status --json 机器可读出口 + 退出码注册表进 help 总览

Status: done

## 背景

agent 判定 state 只能 scrape 带颜色的 `[OK]/[FAIL]` 行；退出码（0/1/2）语义只在 verify
文档与散落注释里，`ldc help` 总览无注册表。wdc 侧同批同构（wdc 工单02，旗标因 pwsh 绑定器
限制为 `-Json` + 包装层 `--json` 归一）。

## 内容

- status 分支先算后印：`--json` 输出单行紧凑 JSON，键：`tool/version/command`、
  `repo{state,ahead,behind}`（state 含 ok/ahead/behind/diverged/detached/no-origin/fetch-unreachable）、
  `dotfiles{drift_count,drift_items[]}`、`identity{ok}`、`root_stage{complete,handoff}`、
  `last_bootstrap{log,verdict}|null`、`upstream_check{days}|null`、`hints[]`；人读输出零变化
- JSON 字符串经转义助手（反斜杠/双引号）手工拼 printf——不引入 jq 运行时依赖（validate 红线）
- status 只认 `--json`（其余位置参数报错，对齐 sync 的严格口径）；退出码不因 --json 改变
- help 总览补退出码行：`退出码：0 成功 · 1 失败 · 2 有待办手工步骤`

## 验收清单

- [ ] `ldc status --json` 输出合法 JSON（python3 -m json.tool / node 回解验证）
- [ ] 人读输出逐字节不变
- [ ] help 总览含退出码行
- [ ] validate 全绿（shellcheck）

## 实录

- 烟测（ASUS/WSL）：`ldc status --json` 输出经 python3 json.tool 回解合法；布尔 true/false（首版 1/0 即时修正）；人读输出形态不变；`--badarg` 报错 exit 1
- 验收四项全过；validate 全绿（提交 2db3bfa）
