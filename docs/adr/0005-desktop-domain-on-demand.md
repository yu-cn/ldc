# 桌面域按需启用：gsettings 清单 + 会话探测降级

覆盖面含 GNOME 桌面偏好（用户决策，否掉了纯 headless 建议），但大量接入机器是服务器/SSH 形态——桌面域必须**按需启用**而非必装。机制：`configs/desktop.gsettings` 每行 `schema key value`（value 带引号原样）声明偏好，`apply-desktop.sh` 逐条应用；应用前以「读第一条 key」探测 D-Bus 会话——无会话（SSH、无桌面机器）优雅 SKIP 并提示「登录 GNOME 桌面后重跑 bootstrap」，bootstrap 将其记为待办（exit 2 族）；verify 同理 SKIP，不制造假 FAIL。

字体（JetBrainsMono NF）归入桌面域但仅以「机器有 gsettings」为门槛（有桌面栈的机器才需要终端字体），用户级安装（`~/.local/share/fonts/` + `fc-cache -f`，免 sudo），版本钉 `configs/nerd-fonts-version`，目录存在即跳过。桌面声明只取「每台桌面机都该一样」的少数 opinion（暗色、24h 时钟、显示隐藏文件等起步；2026-10-24 扩至 12 条并对齐 WDC 注册表域的去噪/隐私取向，见 ADR-0008），不追 dconf 全量。

**补记（2026-10-24，随 ADR-0008）**：发行版组件集不同（如 Debian 无 Ubuntu Dock 的 dash-to-dock schema），清单行的语义定为「有此组件则应为此值」——schema 不在 `gsettings list-schemas`（含 relocatable）的行在应用与断言两侧一律 SKIP 而非 FAIL。输入源同批声明（`org.gnome.desktop.input-sources sources` = 美式键盘 + ibus-libpinyin）：中文输入是每台桌面机的通用核心，ibus 为 GNOME 原生框架（Wayland 无坑，优于 fcitx4 系的搜狗与需环境变量接线的 fcitx5）；该键声明**完整列表**、覆盖机器自定义布局，特殊布局机器把此条挪进自留地。拒绝的替代：dconf dump 全量声明（不可审查、混入机器噪声）；桌面域必装（服务器机器被迫装 GNOME 依赖）；SKIP 判定用 `$DISPLAY`/`$WAYLAND_DISPLAY` 环境变量（在非交互 bootstrap 上下文不可靠，gsettings 读试探是效果级证据）。

**补记（2026-10-25）**：输入源引擎自 ibus-libpinyin 换为 ibus-rime（中州韵）——libpinyin 实测卡顿且词库弱，rime 引擎响应快、词库经雾凇拼音（[rime-ice](https://github.com/iDvel/rime-ice)）精调；ibus 框架不动，原「GNOME 原生、Wayland 无坑」的论证原样成立。运维注意：装完 ibus-rime 须 `ibus restart`（或注销重登）让 ibus-daemon 重扫组件注册表，否则新输入源激活不了、中文整体失效（2026-10-25 实录：daemon 先于装包启动即踩）。雾凇配置不入仓库（`git clone --depth 1 https://github.com/iDvel/rime-ice.git ~/.config/ibus/rime`）：内含用户词频学习数据，性质同 `.bashrc.local` 机器自留地。拒绝的替代：fcitx5 全家桶（多一套框架实体，noble 又缺 zhwiki 词库包与 configtool GUI）；搜狗/百度闭源版（fcitx4 老底子、面向麒麟/UOS 生态，Ubuntu 24.04 GNOME 兼容性差）。
