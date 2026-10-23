# 桌面域按需启用：gsettings 清单 + 会话探测降级

覆盖面含 GNOME 桌面偏好（用户决策，否掉了纯 headless 建议），但大量接入机器是服务器/SSH 形态——桌面域必须**按需启用**而非必装。机制：`configs/desktop.gsettings` 每行 `schema key value`（value 带引号原样）声明偏好，`apply-desktop.sh` 逐条应用；应用前以「读第一条 key」探测 D-Bus 会话——无会话（SSH、无桌面机器）优雅 SKIP 并提示「登录 GNOME 桌面后重跑 bootstrap」，bootstrap 将其记为待办（exit 2 族）；verify 同理 SKIP，不制造假 FAIL。

字体（JetBrainsMono NF）归入桌面域但仅以「机器有 gsettings」为门槛（有桌面栈的机器才需要终端字体），用户级安装（`~/.local/share/fonts/` + `fc-cache -f`，免 sudo），版本钉 `configs/nerd-fonts-version`，目录存在即跳过。桌面声明只取「每台桌面机都该一样」的少数 opinion（暗色、24h 时钟、显示隐藏文件等 6 条起步），不追 dconf 全量。拒绝的替代：dconf dump 全量声明（不可审查、混入机器噪声）；桌面域必装（服务器机器被迫装 GNOME 依赖）；SKIP 判定用 `$DISPLAY`/`$WAYLAND_DISPLAY` 环境变量（在非交互 bootstrap 上下文不可靠，gsettings 读试探是效果级证据）。
