# 11: wsl-comfort 残留清理与吸收定夺（ADR-0018）

**What to build:** 2026-11-01 主人巡检本机 WSL 侧提出清理 microsoft/WindowsDeveloperConfig wsl-comfort（Comfort Shell）残留（「nvm、comfort-shell 命令等」）。深查定归属（探查全程只读，证据表见 [ADR-0018](../../docs/adr/0018-wsl-comfort-leftover-cleanup.md)）：活体残留六处——`~/bin` 六垫片（第 2 行逐个自证 `# comfort-shell shim`）、`/home/linuxbrew`（288M，日志 594 行「Homebrew setup complete」）、`/usr/local/bin/starship` v1.25.1（skel 系统级、dpkg 无主）、`~/.comfort-shell-install.log`（161KB）+ `~/comfort-shell-bootstrap.sh`（30KB）、btop（`COMFORT_APT_OPTIONAL` 唯一留存成员）；孤儿 `~/.nvm`（237M）**归属修正为机器自有**（comfort 脚本无 nvm 步骤，装于其日志后 17 小时，零 rc 引用，node 已由 mise 供 v26.13.0）。定夺（主人四项确认：nvm 删 / btop 吸收 / direnv 吸收 / 一次性人工清理+记账）：上游 README 无 uninstall 面，走一次性机主授权清理，「只装不删」红线不变；btop、direnv 并入 `configs/cli-tools.pkg`（direnv 激活 bashrc:104 既有探测钩子）。

**Blocked by:** None

**Status:** done

- [x] ADR-0018 成文（归属证据表 + 决策 + 拒绝的替代）+ cli-tools.pkg 吸收 btop/direnv + CHANGELOG Unreleased——ca65560（validate 全绿，pre-commit 同脚本把关）
- [x] 本机清理（用户级）：`~/bin` 六垫片 + 空目录 rmdir、日志与脚本两件、`~/.nvm`（237M）
- [x] 本机清理（root 级）：`/usr/local/bin/starship`、`/home/linuxbrew`——本会话 `sudo -n` 不可用，经 ADR-0007 委托契约同款通道 `wsl.exe -d Ubuntu -u root` 委派清除
- [x] DSHELL 核查：`/etc/adduser.conf` 仅注释默认行 `#DSHELL=/bin/bash`，skel 模式无默认 shell 残留
- [x] root 阶段补收敛：direnv 经 `install-packages.sh` apt 安装（同委派通道；幂等其余全 SKIP，exit 0）
- [x] 清后对账全绿：`verify --quick` exit 0 全过（btop/direnv 新进 dpkg 断言 OK、starship=钉 1.27.0、node 可用、落点零漂移）；`plan` 将变更 0（btop/direnv 投影 OK 已就位）；`audit` 自装未声明 42→41（btop 移出，direnv 新装且已声明不入候选）；交互面 `pbcopy`/`open`=ADR-0017 函数垫片接管、starship 1.27.0、node v26.13.0（mise）、direnv 2.37.1 钩子激活、brew 不复存在
- [ ] CI 锚点回填：ca65560 与本票待机主推送（本会话无 GitHub 凭据实况：HTTPS 无交互凭据、gh 未登录、SSH 无密钥）——push 后 validate 绿补 run id

## Comments

- 2026-11-01（本机 WSL 会话，开工即收口）：探查→定夺→实施→对账同日完成。删除前证据固定：comfort 日志 101 行「Default shell set to zsh」、174/175「starship installed / Wrote starship config」、376+491「CLI shims installed」（双轮）、451「brew install direnv」、594「Homebrew setup complete」、603「Wrote ~/.zprofile and ~/.zshrc managed blocks」、日志尾「Distro configured. Ready for first user.」（skel 装机流）；`~/.nvm/versions/node/v24.18.0` mtime 2026-06-24 18:29（`~/.comfort-shell-install.log` mtime 2026-06-24 01:26，17 小时差）。audit 其余 41 项自装未声明（fonts-*/x11 库/cmake/gdb/nginx/xvfb/docker-ce-rootless-extras 等）按 ADR-0003 判机器自留，不在本单处理面。Windows 侧 comfort 痕迹（字体注册表 / Windows Terminal fragment / `%LOCALAPPDATA%\DevConfig\wsl-comfort` 暂存）归 WDC 辖区（冻结待退役），未动。
