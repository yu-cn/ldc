# 工单 03 — WDC 侧 WSL 阶段委托 LDC（ADR-0007 落地）

> 状态：规格已定稿，**待 WDC 仓库侧实施**（本工单在 LDC 仓库流转，实施于 WDC）。前置：LDC 发布到 github.com/yu-cn/ldc。

## 目标形态

WDC 的 WSL 阶段从「自带 setup-ubuntu.sh 双角色实现」退位为「WSL 生命周期管理 + 委托 LDC」：

| 环节 | 现状（WDC 自实现） | 委托后 |
|---|---|---|
| WSL 启用 / Ubuntu 安装 / wsl.conf systemd / 默认用户 | install-wsl.ps1 / install-wsl-env.ps1 | **保留在 WDC**（Windows 侧生命周期） |
| WSL 内 apt/gh/docker | setup-ubuntu.sh root 段 | `wsl -d Ubuntu -u root -e bash ~/dev/ldc/scripts/install-packages.sh`（EUID=0 内联路径） |
| WSL 内 uv/vp/starship/dotfiles | setup-ubuntu.sh user 段 | `wsl -d Ubuntu -e bash ~/dev/ldc/bootstrap.sh`（root 已核销自动跳过） |
| dotfiles/wsl/{bashrc,gitconfig} | 符号链接到 /mnt/c 的 WDC 仓库 | 退役；由 LDC dotfiles/linux 接管（替换旧链接，.bashrc.local/.gitconfig.local 兜底承接机器段） |
| WSL 验收断言（probe.sh） | WDC 自有探针 | 委托 `verify-machine.sh --quick`；保留 WSL 特有项（见下） |

## WDC 侧改造清单

1. `scripts/wsl/setup-ubuntu.sh` → 改为薄委托：定位/clone LDC（`~/dev/ldc`，已存在则 fetch + `pull --ff-only`，分叉中止交人工——与 `ldc sync` 仓库步同语义）→ 按上表调用；`LDC_SKIP_DOCKER=1` 透传给无 systemd 的旧发行版
2. `scripts/install-wsl-env.ps1`：身份带过（Windows 侧 gitidentity → WSL）保留——LDC 的占位机制识别已存在的 `.gitidentity` 不覆盖，带过逻辑继续有效
3. `dotfiles/wsl/`：冻结（README 注明「由 LDC dotfiles/linux 接管」），一个过渡版本后删除
4. `scripts/verify-machine.ps1` 第 5/6 组 WSL 断言：改调 LDC verify；**保留 WSL 特有项**——默认 shell=bash、systemd 开启
5. `configs/vp-version`：委托后 WSL 侧读 LDC 的钉子，WDC 只剩 Windows 侧消费者；升级仍两仓库同日改
6. 移除清单（Go 等）与 WDC 特有 opinion 保留在 WDC 的委托包装层（pre/post 钩子），不进 LDC

## LDC 侧随迁清单（实施时在 LDC 补）

- 默认 shell=bash（`chsh`）：从 setup-ubuntu.sh 迁入 LDC——注意 chsh 需 PAM 认证，agent/CI 语境做成「不一致时列待办」而非自动改
- `ldc sync` 在无 origin 场景已优雅跳过（WSL clone 自 GitHub，有 origin，正常走全流程）

## 验收

- [ ] WDC 管理的既有 WSL 机器重跑 bootstrap 后：dotfiles 落点全部指向 LDC 仓库，`ldc status` 全绿
- [ ] WDC 侧 verify（含委托段）全绿；`dotfiles/wsl` 无机器再引用
- [ ] vp 钉子两仓库同值；各自账本互引记一笔

## 实录

（待 WDC 侧实施后回填）
