# 桌面应用域：VSCode / Chrome 经厂商 apt 源纳入声明

用户要求桌面 Linux（Ubuntu Desktop 形态）把常用 GUI 软件纳入统一配置，对齐 WDC 在 Windows 侧的 editors 域。定为**桌面应用域**（与 ADR-0005 同族的按需启用），不塞进 cli-tools：

- **门禁 = `have gsettings`**（机器有桌面栈的事实判据，与字体同款）：headless 服务器、WSL、CI 容器自动整域跳过——安装面、断言面、`root_stage_complete` 三处同口径。
- **机制 = 厂商 apt 源 + keyring**（winget 的 Linux 等价物）：VSCode（packages.microsoft.com）与 Chrome（dl.google.com）与既有 gh 源共用 `add_vendor_repo` 原语（keyring 幂等、失败清理半成品防污染下次判断）。拒绝的替代：snap（更新不受本仓库控制、Ubuntu 之外不存在）、flatpak（多一层运行时与主题集成问题）；Ubuntu 仓的 chromium/firefox 在 24.04 起只是转 snap 的占位包，厂商源反而是唯一正经 deb 路径。
- **双架构对称（实测 2026-10）**：两家厂商源均发布 amd64 与 arm64（Chrome arm64 已实测在库），无需架构例外——apt 按机器架构自行解析。
- **VSCode 深度接管**：扩展清单 `configs/vscode-extensions.txt`（与 WDC 同名同格式、不钉版本、自装扩展不核销——ADR-0003）；settings/keybindings 入 `dotfiles/linux/` 符号链接到 `~/.config/Code/User/`（WDC 已验证的模式）。**接受的代价**：VSCode 会频繁写穿 settings.json——防写穿断言 + triage 分流兜底，且首次启动必须关 Settings Sync（账号级开关，云端会与仓库 dotfiles 打架，WDC 同款教训，README 已列）。
- **GNOME 优化扩充（同批）**：desktop.gsettings 从 6 条扩到 12 条（时钟星期几、字体渲染 rgba/slight、隐私去噪关 recent/usage 记录、Ubuntu Dock 点击最小化），对齐 WDC base-windows 注册表域的「去噪/隐私/信息密度」取向；新增 **schema 存在性降级**——发行版组件集不同（Debian 无 Ubuntu Dock），schema 不在 `list-schemas` 的行 SKIP 而非 FAIL，清单语义为「有此组件则应为此值」（ADR-0005 补记）。
- **Chrome 偏好不管**：managed policies JSON 等（YAGNI，等真有跨机不一致痛点再加）。拒绝的替代：管到偏好层（面扩大到 /etc 策略文件，v1 收益不成比例）。

**补记（2026-10-24，WDC 工单32 迁移验收实录）**：本 ADR 原文「WSL 自动整域跳过」的门禁假设被 WSLg 打破——WSLg 机器 `have gsettings` 为真，桌面应用域误激活：委托迁移时装进了 code/chrome，且 WSL 里 `code --install-extension` 全数失败（CLI 不可用）。裁定：**WSL 不装 Linux 桌面软件，即便有 WSLg**（GUI 由 Windows 侧承载，WSL 内 gsettings 只服务 Linux GUI 兼容层）。门禁从 `have gsettings` 收紧为 `desktop_stack_present()`（gsettings 在位 **且非 WSL 内核**，common.sh 单一来源），安装面（desktop-apps/字体/VSCode 配置链接/扩展）、断言面（verify 桌面域）、`root_stage_complete`、apply-desktop 四处同口径。判定用 `/proc/sys/kernel/osrelease` 含 microsoft（官方标记，只读不依赖环境变量）——拒绝 `$WSL_DISTRO_NAME` 等环境变量（非交互上下文不可靠，同 ADR-0005 拒 `$DISPLAY` 之理）。
