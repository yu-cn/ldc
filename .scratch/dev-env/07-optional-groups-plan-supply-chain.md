# 工单 07 — 可选包组 + 干跑预演 + 供应链钉（ADR-0010/0011）

## 背景

用户问「pandoc/ffmpeg 等常用工具是否该进清单」。盘点：apt 两清单全为纯开发链工具，文档/媒体转换类为零。三重约束在案：ADR-0003 通用核心判据（每台都需要才进）、用户「如无必要勿增实体」裁定、对标调研（WindowsDeveloperConfig / WDC / tasksel / dnf group / Ansible tags——生态通例「菜单在声明侧、选择在调用时、包管理器记账」，无一发明激活文件+断言层）。同会话用户追加需求：sudo/重跑前能先看一眼（信任面），以及下载资产防篡改。

## 内容

- **可选包组（ADR-0010）**：`configs/media-doc.pkg`（pandoc + ffmpeg）平铺 configs/；install-packages.sh 参数分支显式指名安装（走同一 pkg_install 循环，未知名报错并列可用清单）；激活态即 dpkg 状态——verify/root 完成度零改动；红线 #10
- **ldc plan 干跑预演**：`scripts/plan-machine.sh` 只读投影（预检/apt/桌面应用/Docker/user 工具/dotfiles/桌面域七面逐项），四态 OK/PLAN/SKIP/INFO；common.sh step() 新增 PLAN 状态；CLI plan 子命令 + help + 错字建议；与 verify 互补（断言现状 vs 投影未来）
- **供应链钉（ADR-0011）**：starship/lazygit/nerd-fonts 钉子文件增 `sha256 [amd64|arm64] <hex>` 行（哈希自官方 release 资产实算）；`pin_sha256()` + install-user-tools 三处下载先落盘校验后安装、不符即拒绝并报「疑似供应链异常」；validate 补 sha 行格式检查；vp/uv/docker（curl|sh 安装器）不钉
- 文档：README「安全与边界」块 + 可选包组段 + plan 行；GLOSSARY「可选包组」「干跑预演」；AGENTS 红线 #10 + 自查加 plan

## 验收

- [x] validate 全绿（含 sha 行格式检查；本地与 CI run 40108379100 双过）
- [x] media-doc 本机实装（sudo 交接真实走可选组分支）
- [x] plan 首跑 0 将变更（本机全收敛态投影）
- [x] 推送后 CI：validate（40108379100）+ fresh-container 三腿全绿（40108395169：handoff / smoke-amd64 / smoke-arm64）——冒烟容器全新下载 starship/lazygit，sha256 校验路径首获双架构 CI 覆盖

## 实录（2026-10-24）

- [x] validate 全绿（pre-commit 与手工各一遍）
- [x] media-doc 实装：pandoc 3.1.3 / ffmpeg 6.1.1-esm15（Ubuntu Pro ESM 源）；参数分支真实 sudo 运行验证通过
- [x] plan 首跑抓到本机 hot-corners 漂移（机器 true vs 声明 false——verify --quick 不查 gsettings 读值的盲区），apply-desktop 收敛后 0 将变更
- [x] 顺带处置（ADR-0003 流转实例）：nvwb/git-lfs 写穿块迁自留地 + 模板还原；apt 源被第三方工具误改（cn.archive.ubuntu.com + 三处 NVIDIA PPA 签名块折叠）经 .save 快照恢复 ports.ubuntu.com 原版——DGX 仓库属机器态，LDC 清单外不碰
- [x] 设计取舍实录：激活文件 + ldc 交互子命令方案被「勿增实体」否决（激活态即 dpkg 状态）；README.en 与 CI 发行版矩阵扩张落地后按同裁定回退——两次裁定同向，取向入档 [[LDC 简洁偏好]]

**过程中的插曲**：sha256 哈希本可抄 release 页面，改为下载官方资产实算——哈希的可信度不能建立在被校验对象自己提供的信息上。
