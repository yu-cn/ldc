# 工单 04 — CI 冒烟补幂等重跑段

## 背景

fresh-container.yml 的冒烟（root 内联 + 交接路径 + 双架构矩阵）只跑一遍 bootstrap，
缺上游 CI 的核心验收语义——「装 → 用 → **重跑一遍证明幂等**」（上游 ci.yml 顶部注释
明示；上游 known limitations 特意声明引擎无 dry run，幂等证明全靠重跑）。
wdc fresh-machine 同款缺口（本轮对标共同发现，两仓可同日双改）。

## 内容

- 冒烟末尾补第二遍 bootstrap + 断言：第二遍零变更/全 SKIP（幂等证明），或按
  `LDC_SMOKE=1` 语义投影「第二遍不新增待办」
- 交接路径腿（handoff job）是否补重跑视实现成本：exit 2 语义腿的重点在交接命令，
  重跑非其验收面，可不补

## 验收

- [ ] 三腿矩阵含幂等重跑段且全绿
- [ ] 重跑段失败能在 CI 明确报出（非静默）

## 实录（2026-10-25）

- [x] 冒烟 smoke 腿补第二遍 bootstrap：断言 exit 0 且日志零 `[CHANGED]`（违例 `::error` 显式报出）；工件连带 rerun.log
- [x] handoff 腿不补重跑（其验收面是交接命令语义，ticket 内容已声明）
- [ ] CI 实测锚点：推送后手动触发 fresh-container，run id 补记于此
- [x] CI 实测锚点：run 40177716073（workflow_dispatch 手动触发）三腿全绿——handoff 25s / smoke amd64 1m29s / smoke arm64 1m22s；两腿「幂等确认：第二遍 exit 0 且零 CHANGED」判定行齐备（锁代码在容器路径同批覆盖验证）
