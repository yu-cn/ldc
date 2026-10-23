# root-user 两阶段与 sudo 交接

Linux 收敛的写入面天然分两层：系统包（apt/gh 源/docker）需 root，用户工具与 dotfiles 不需要且不应以 root 执行（装到 `/root` 即错误）。定为两阶段：`scripts/install-packages.sh` 是**可独立 `sudo` 运行**的 root 阶段；其余阶段全部以普通用户执行。

bootstrap（普通用户启动）按 sudo 形态三路分发：容器/已提权（EUID=0）直接内联跑 root 阶段（CI 冒烟路径）；免密 sudo（`sudo -n true` 通过）自动 `sudo bash scripts/install-packages.sh`；**需密码**则不打断流程——其余阶段照常执行，末尾打印单条交接命令（`cd <repo> && sudo bash scripts/install-packages.sh`）并以 **exit 2** 表示「有待办手工步骤」（区别于 exit 1 的失败）。agent 与 CI 无法交互输密码，交接命令是唯一诚实形态：不静默跳过（机器处于部分收敛态必须可见），不伪造成功。

退出码语义因此定为：0 全部就绪 / 1 有失败 / 2 有待办（root 交接、身份未填、桌面待登录重跑）。容器冒烟语境（`LDC_SMOKE=1`）待办不适用——容器永无桌面会话、身份刻意保持占位——故 SKIP/占位记 INFO 不计待办、bootstrap 退 0，CI 得以继续跑 verify（身份断言同步降为存在性检查）。`ldc status` 的「root 阶段完成度」以包清单核销（dpkg -s 逐项 + gh + docker 在位）为据，不依赖 marker 文件——断言面即安装面，状态即事实。拒绝的替代：全程要求 sudo 跑 bootstrap（CI/agent 无法交互；user 阶段误入 /root）；pkexec/polkit 弹窗（无图形会话场景不可用）；把待办静默降级为日志一行（部分收敛态不可见，违背「一条命令收敛」的承诺）。
