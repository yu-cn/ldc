# 工单 01 — 收敛入口运行锁（flock）

## 背景

bootstrap / `ldc sync` 都会发起 apt 与下载类收敛，当前无并发防护（2026-10-25 grep
bootstrap.sh、ldc、scripts/*.sh、scripts/lib/*.sh 无 flock/lockdir/mutex 实证）：
`ldc sync` 与手工重跑 bootstrap 并发会互相踩安装事务。上游引擎有全局命名互斥体
`Global\WindowsDevConfigSetup`；wdc 已落地同思想实现（wdc 0ad0788，工单
`.scratch/bootstrap-run-lock/`），本工单为 LDC 侧对等落地。

## 内容

- flock 文件锁（util-linux 自带，容器内可用）：`exec 9><锁文件> && flock -n 9` 抢占式，
  崩溃时内核自动释放，无陈旧锁清理问题
- 取锁点 = 收敛入口（bootstrap.sh 真实跑阶段的路径；`ldc sync` 经 bootstrap 子进程间接受保护，
  sync 对锁占用退出码给专属提示）；status / verify / plan / triage 等只读入口不取锁
- 已被占用：输出「已有一次收敛在跑」，exit 非零（wdc 口径为 3，LDC 红线 7 的 0/1/2 词表内取值
  由实现定，需同步 `ldc status` / CI 对退出码的既有消费）
- GLOSSARY 补「运行锁」词条（与 wdc 同名词条同义）

## 验收

- [ ] 抢占语义实测：持锁中第二入口被拒（非零退出 + 提示）、释放后可入、kill 持锁进程后立即可入
- [ ] 只读入口行为不变
- [ ] validate.sh 全绿；CI 三腿不受影响

## 实录（2026-10-25）

- [x] 抢占语义实测：holder 持锁 → bootstrap `[FAIL] 运行锁 - 已有一次收敛在跑` exit 1 秒退（预检之前，零机器接触）；无 holder → 获锁放行（插桩克隆法：锁后 `exit 99` 桩，全量跑不触真机）
- [x] 释放后可获取（flock -n 重入成功）；内核崩溃释放语义由 flock(1) 文档背书 + wdc 侧 AbandonedMutex 等价实测
- [x] validate.sh 全绿（bash -n + shellcheck --severity=warning，WSL 本机 shellcheck 实跑）
- [x] ldc sync 对锁占用日志关键字补专属提示（退出码保持红线 7 词表内的 1）
- **测试事故入档（一句话教训：测收敛入口用插桩克隆或 plan 干跑，绝不用临时克隆全量跑）**：首轮用临时克隆全量跑 bootstrap，dotfiles 落点被重链到克隆、克隆删除即死链（AGENTS 坑「仓库缺席」同构场景）——已按配方恢复（`~/.ldc` 指针写回真仓 + 真仓重跑 bootstrap 重链，verify --quick 全绿）
