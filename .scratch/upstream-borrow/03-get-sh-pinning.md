# 工单 03 — get.sh 供应链钉版与审阅说明

## 背景

`scripts/get.sh` 是远程一键引导（curl | bash），当前指 raw main：
`raw.githubusercontent.com/yu-cn/ldc/main/scripts/get.sh`（2026-10-25 核实）。
clone 之后的部分已被本地 git 钉住，唯一未钉的信任点是 get.sh 自身——main 推进即
远程入口行为漂移。wdc get.ps1 同款缺口（同日发现，两仓同日双改对齐）。

## 内容

- 最小改法（择一或组合，实现时定）：① README/脚本头注明信任模型与审阅入口
  （curl 先看再管）；② 发布 tag 后提供 tag 版入口 URL（`refs/tags/<v>` 路径）并注明
  「求稳走 tag 版」；③ get.sh 内对 clone 的仓库 checkout 到发布 tag（clone 后钉子）
- 上游参照：上游 bootstrap 有 `-Ref` 钉 branch/tag/SHA（但其仓库至今无 tag，设计意图
  与现实脱节）；LDC 已有版本钉文化（ADR-0011），get.sh 钉版与之同族

## 验收

- [ ] 零前置一条命令路径不变（缺 git/curl 自动 apt 装语义不动）
- [ ] 信任模型在 README 可见
- [ ] validate.sh 全绿
