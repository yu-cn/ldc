# 可选包组：清单即菜单，调用期显式指名

通用核心（base-linux + cli-tools）的判据是「每台机器都需要」（ADR-0003），但存在一类工具：常用、依赖树不小、却不是每台机器都需要——如 media-doc（pandoc 文档转换 + ffmpeg 音视频）。塞进通用核心会让 CI 容器与 headless 机器陪跑依赖树；不做又回到「重装机器后忘了装」。解法刻意最小，对齐生态惯例：

- **清单即菜单**：可选包组平铺 `configs/<名>.pkg`（首个成员 `media-doc.pkg`），与通用清单同格式，validate 现有 glob 自动覆盖格式检查；
- **选择在调用时**：`sudo bash scripts/install-packages.sh media-doc` 显式指名安装——走同一 `pkg_install` 循环（幂等、同 phase/step 口径、同退出语义），名字不存在则报错并列出可用清单；
- **激活态即已装状态**：装没装由 dpkg 记账，不建激活文件、不建第二本账；verify 与 root 完成度对可选包沉默（对齐 ADR-0003 nvm「不断言归属」与 WDC「清单外不碰」）。

参照（2026-10 调研）：microsoft/WindowsDeveloperConfig（分组即入口命令，选择在调用时）、WDC（定制 = fork 改清单）、Debian tasksel / dnf group / Ansible tags（组菜单在声明侧、选择在命令行、包管理器记账）——四类均无「激活文件 + 断言」层；Omakub/Omarchy 同样以 fork 改清单为定制方式。

拒绝的替代：可选包直接进 cli-tools.pkg（所有机器与 CI 背 ffmpeg 依赖树）；激活文件 + `ldc` 交互子命令（在 dpkg 之外发明状态第二本账，无参照项目这么做，且交互进不了 sudo 语境）；本地 metapackage（需 deb 构建线，实体更多）。

语义边界：只装不删不变；迁移时可选组不自动回来，要不要装由机主逐机再决定——这正是「可选」的本义，WDC 的 inventory 反向吸收可兜底。新增可选包组的动作只有一步：加一个 `configs/<名>.pkg`（头注释写明用途与用法）。
