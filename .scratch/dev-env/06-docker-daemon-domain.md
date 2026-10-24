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

## 实录

（执行后回填）
