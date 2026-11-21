# undo 表——退出与手工撤销对照（LDC 版）

> `ldc exit`（[ADR-0024](../adr/0024-ldc-exit.md)）的手工对照正典：声明面各域的撤销动作逐项列出，不跑 exit 也能手工拆解。对齐 WDC docs/undo-table.md 同款做法。

## apt 核心域（base-linux + cli-tools，configs/*.pkg 单一来源）

```bash
sudo apt-get remove -y --purge build-essential git ca-certificates gnupg unzip zip \
    jq bash-completion fzf fd-find ripgrep bat zoxide eza git-delta htop shellcheck btop direnv
sudo rm -f /etc/apt/sources.list.d/github-cli.list   # gh 官方源（gh 包随上行走）
```

**共享资源豁免不卸**（ADR-0024 红线——卸之伤及无关软件）：`libatomic1`（node/mise 链接依赖）、`fontconfig`（字体子系统公共件）、`curl`/`wget`（通用网络工具）。fd/bat 的兼容链接（`/usr/local/bin/fd`、`bat`）随 `--purge` 后手动核对残留。

## 二进制（user 级，~/.local/bin）

```bash
rm -f ~/.local/bin/uv ~/.local/bin/uvx ~/.local/bin/mise ~/.local/bin/starship
```

**数据面不动**（红线）：`~/.local/share/mise`（语言 runtime）、uv cache、venv 一概保留。

## dotfiles 落点（ADR-0015 渲染拷贝）

| 落点 | 处置 |
|---|---|
| `~/.bashrc` / `~/.gitconfig` / `~/.config/starship.toml` | 有 `.bak`（首次渲染前原文件）还原之；无则删（LDC 创建） |
| `~/.local/bin/ldc` | 删（符号链接） |
| VSCode settings/keybindings（desktop 形态） | 已随 ADR-0023 让位原生设置同步——账号态，不处置 |

## 桌面域 gsettings（desktop.gsettings 声明面）

逐键回 GNOME 默认（清单即 `configs/desktop.gsettings`）：

```bash
gsettings reset <schema> <key>    # 每声明行一条；无桌面会话跳过
```

输入源/rime 词库（`~/.config/ibus/rime`）属机器自留地，不碰。

## Docker / 状态 / 不碰面

- **Docker 引擎**：不代跑（ADR-0024）——`sudo apt-get remove docker-ce docker-ce-cli`；卷/镜像保留于 `/var/lib/docker`
- **状态**：`~/.local/state/ldc/`（渲染+收敛账本）、`~/.ldc` 指针——删
- **可选包组**（desktop-apps / media-doc）：指名装属自管，不在退出面
- **NF 字体**（`~/.local/share/fonts/JetBrainsMono-NF`）：共享资源不卸（对齐 WDC 红线）
