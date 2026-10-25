# Spec：上游借鉴反哺（对标 microsoft/WindowsDeveloperConfig 与 wdc 本轮学习）

## 背景

2026-10-25 wdc 侧完成对上游 microsoft/WindowsDeveloperConfig 的对标评估并落地两项
（运行锁、重启自动续跑；wdc 0ad0788），顺带修复了自身对标工具的基线缺陷
（wdc 9d1dc3b：正则噪声→结构化真源抓取）。本目录承接同一评估对 LDC 的适用面：
LDC 与上游 wsl-comfort / 引擎同题材，部分缺口同构存在。

## 范围（四张工单）

1. 01 运行锁：bootstrap / `ldc sync` 收敛入口无并发防护（grep 无 flock/lockdir 实证）
2. 02 上游跟进机制：无 research 笔记 / 吸收账本 / check-upstream 等价物（docs/ 仅 adr + dev-standard）
3. 03 get.sh 钉版：远程入口指 raw main，信任点未钉（与 wdc get.ps1 同款缺口）
4. 04 CI 幂等重跑：fresh-container 冒烟只跑一遍，缺上游 CI 的「重跑证明幂等」语义

## 已评估并排除的借鉴项

- **重启自动续跑**：WSL 发行版侧无重启生命周期（重启是 Windows 侧事务，归 wdc bootstrap-resume），不适用。
- **签名体系 / src-真源+签名副本**：个人仓库 Authenticode 是重装备，YAGNI。
- **多档 profile / workload 选择器**：与「一台机器一个声明状态」哲学冲突，多机差异由机器对等解决。
- **卸载路径**：LDC 红线 2 明文「只装不删」语义（无移除清单），不引入。
- **LDC 已领先上游的面**（无需借鉴，记录防误判）：plan-machine.sh 干跑预演（上游引擎明文
  "No dry run"）、版本钉+sha256 单一来源（ADR-0011，比上游只钉字体全面）、daemon.json
  受保护合并（ADR-0009）、双架构 CI 矩阵。
