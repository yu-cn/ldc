# 工单 06 — Docker daemon 配置域（受保护合并，ADR-0009）

## 背景

用户问「LDC 是否考虑了 docker 的配置」。盘点：安装面已有（在位跳过/官方脚本/入组），配置面为零。实测本机（DGX 出厂 Docker 29 + compose/buildx 全齐，daemon.json 不存在）暴露真缺口：json-file 日志无上限可吃满盘。

## 内容

- `configs/docker-daemon.json` 声明三条通用核心键：log-driver json-file + max-size 50m / max-file 3（轮转）、live-restore true（daemon 重启不杀在跑容器）
- root 阶段受保护合并：jq 递归合并（`existing * declared`），声明叶键胜出、机器自有键保留；非法 JSON 拒合并；变更备份 .bak；**绝不自动重启 docker**（live-restore 生效后的重启本就不杀容器，时机留机主）
- `docker_daemon_declared_ok()`（common.sh）：`target * declared == target` 递归子集判据，verify 与 root 阶段完成度共用
- validate：daemon JSON 合法性校验 + 合并语义自测（声明叶胜出/机器键保留）
- ADR-0009、AGENTS 红线 9、GLOSSARY「受保护合并」、README 系统段

## 验收

- [ ] validate 全绿（含 daemon JSON 校验与合并自测）
- [ ] 本机回归：root 回到交接态（daemon.json 未写）、bootstrap exit 2 列待办、verify 新增 FAIL 在「待 root 交接」族
- [ ] 推送后 CI：validate 绿 + 三腿冒烟不受影响（容器 LDC_SKIP_DOCKER=1 整域跳过）
- [ ] 用户侧：sudo 交接一次（创建 daemon.json）+ 择机 `sudo systemctl restart docker` 生效（首次重启前 live-restore 尚未生效，留意在跑容器）

## 实录（2026-10-24）

- [x] validate 全绿（本机 jq 在位走全检；裸机降级放行）
- [x] 本机回归：root 回到交接态（daemon.json 未写）、bootstrap exit 2、verify 新增 FAIL 在「待 root 交接」族
- [x] CI 三腿全绿（run 40062640993，合流后真实状态）
- [ ] 用户侧待办：sudo 交接一次（创建 daemon.json）+ 择机 `sudo systemctl restart docker` 生效（首次重启前 live-restore 尚未生效，留意在跑容器）

**过程中的两个插曲（都有独立价值）**：
1. **与 WDC 侧会话的跨仓合流**：本工单开发期间，WDC 工单32 迁移验收在 WSLg 机器上实测暴露 LDC 桌面域门禁缺陷（gsettings 可达 ≠ 桌面机器——code/chrome 被误装进 WSL、扩展 CLI 全败），WDC 侧直接修并推 `438f77c`（`is_wsl` + `desktop_stack_present` 单一来源门禁，四处同口径，ADR-0008 补记）。本工单 rebase 合流零冲突，语义双全。ADR-0007 的统筹协作第一次真实发生。
2. **validate 的 jq 硬依赖事故**（CI 三腿全红，run 40062496780）：daemon 检查用了 jq，而 validate 在 bootstrap 第 2 阶段运行、先于 root 装 jq——裸容器全炸。本机因 jq 预装未暴露。修法照 shellcheck 先例：未装时降级放行（root 腿 CI 兜底）。教训入档：**validate 不得引入 apt 之外的运行时依赖**。
