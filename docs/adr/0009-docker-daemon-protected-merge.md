# Docker 域配置：daemon.json 受保护合并

Docker 在 LDC 此前只覆盖安装面（在位即跳过/官方脚本 + docker 组），配置面为零。实测首台机器（DGX Spark，出厂 Docker 29 + compose/buildx 插件全齐）暴露的真缺口：`json-file` 日志驱动默认无大小上限，长跑容器日志可吃满盘——这是「每台跑 Docker 的开发机」都该一样的通用核心，不是机器偏好。

机制定为**受保护合并**而非全量接管：`daemon.json` 没有 include 机制，且机器自有键常见且正当（镜像加速器看网络环境、data-root 看磁盘布局、NVIDIA 运行时走厂商路径）——dotfiles 式符号链接整文件接管会碾过它们。声明集只取三条通用核心键：`log-driver: json-file` + `max-size: 50m` / `max-file: 3`（轮转），`live-restore: true`（daemon 重启不杀在跑容器——对长期跑 GPU 容器的机器价值直接，也让「改配置需重启」这件事本身变安全）。

- root 阶段经 jq 递归合并（`existing * declared`）：声明叶键胜出，机器未声明的键原样保留；现有文件非法 JSON 时拒绝合并交人工；变更前备份 `.bak`（保最早原件）。
- **绝不自动重启 docker**：重启杀在跑容器；live-restore 生效后的重启本就不再杀容器，重启时机留给机主（step 提示「下次 systemctl restart docker 生效」）。
- 断言口径（`docker_daemon_declared_ok`，verify 与 root 阶段完成度共用）：`target * declared == target` ⟺ 声明叶键全部在位同值（递归子集）——断文件而非运行态，运行态在重启前滞后是如实的。
- 与 `LDC_SKIP_DOCKER=1` 同门禁（CI 容器无 dockerd）；validate 内置合并语义自测（声明叶胜出/机器键保留两性质）。

拒绝的替代：全量接管（符号链接整文件——/etc 需 root 且碾机器差异）；文档化 snippet 让机器自抄（非声明式，不可验收）；systemd drop-in 环境变量传参（dockerd CLI 参数表达不了嵌套 log-opts 的可读形态）；自动重启应用（杀容器属危险动作，违背「收敛不伤机器」）。
