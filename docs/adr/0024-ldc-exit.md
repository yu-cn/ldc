# ldc exit——一次性配置的退出面（声明面全退、数据面不动）

WDC 1.0.0 收官批（ADR-0010）把退出面做齐后，两仓承诺面不对称——LDC 仍是「只装不删」设计。主人 2026-11-22 定夺五件提前进 1.0.0，其中头等即 LDC 补 `ldc exit`（同构语义、各自母语实现——双边最优化）。上游对照（microsoft/WindowsDeveloperConfig 有 uninstall 但 "previous settings are not restored"）与本仓差异同 WDC 侧论述，不赘。

## 决策

- **`ldc exit [--yes] [--keep-tools]`**，执行体 `scripts/exit-ldc.sh`。T2 完整退出（默认）：apt 核心域卸载（base-linux + cli-tools 清单逐包 dpkg 在装核销）→ gh apt 源清理 → uv/uvx/mise/starship 二进制卸载 → dotfiles 落点处置（`.bak` 本体=首次渲染前原文件还原、无则删——ADR-0015 同款）→ 状态删除（`~/.local/state/ldc/` 两账本、`~/.ldc` 指针、`~/.local/bin/ldc` 链接——链接最后删，本命令正经它调用）。T1（`--keep-tools`）：只删状态。
- **预演默认**：非 tty 且无 `--yes` 自动降级预演零变更（对齐 wdc exit 的 CI 友好设计）；有 tty 无 `--yes` 打印全计划后问 yes。
- **root 面交接哲学**（对齐 bootstrap）：容器/root 上下文直跑；免密 sudo 直跑；sudo 需密码则收集成单条交接命令打印（不打断、不静默）。
- **红线（对齐 WDC 共享资源/数据面原则）**：共享资源豁免不卸（libatomic1/fontconfig/curl/wget——公共库与通用工具，卸之伤及无关软件；NF 字体同 WDC 豁免）；语言数据面不动（mise/uv 的 runtime/venv/cache）；**Docker 引擎打印指引不代跑**（用户直接使用概率高，卷/镜像数据在 `/var/lib/docker`）；可选包组（desktop-apps/media-doc）指名装的自管不在退出面。
- fresh-container 加全环腿：bootstrap → verify → `exit --yes` → 状态断言 → 重装 bootstrap（装了→退→退了→装）。

## 取舍

拒绝的替代：**Docker 引擎代卸**（误伤面大——数据卷语义复杂，指路即可）；**可选包组一并卸**（指名装的属用户自管，越权）；**apt remove --autoremove**（连坐依赖树不可控，逐包显式与安装面镜像）；**交互式逐项确认**（预演+一次确认足够，对齐 wdc）。
