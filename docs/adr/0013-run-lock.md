# ADR-0013：收敛入口 flock 运行锁

bootstrap 与 `ldc sync` 都会动 apt 与下载事务，此前无并发防护（2026-10-25 grep
bootstrap.sh / ldc / scripts 实证），并发会互相踩安装。上游引擎用全局命名互斥体
（`Global\WindowsDevConfigSetup`）；wdc 已落地同思想（wdc 0ad0788）。LDC 取 Linux
惯用等价物：

- **flock 抢占式文件锁**：`exec 9>"${XDG_RUNTIME_DIR:-/tmp}/ldc-bootstrap-$UID.lock"`
  + `flock -n 9`。持锁进程崩溃由内核自动释放，无陈旧锁清理；util-linux 随系统必备
  （CI 容器同）。
- **取锁点在 bootstrap.sh 真实收敛路径顶端**（预检之前）：只有跑阶段的进程持锁；
  status / verify / plan / triage 只读入口不取锁。
- **占用退出码 1**（红线 7 词表 0/1/2 内——「本次收敛无法进行」按 FAIL 语义），
  判定行详情区分于真失败；`ldc sync` 失败分支按日志关键字补专属提示。

拒绝的替代：锁文件 + PID 陈旧检测（内核 flock 语义已覆盖，多余实体）；mkdir 原子目录锁
（无崩溃自动释放语义，仍需手工清理）；新增退出码 3（破坏红线 7 的 0/1/2 契约——
`ldc status` 与 CI 依赖该约定）。
