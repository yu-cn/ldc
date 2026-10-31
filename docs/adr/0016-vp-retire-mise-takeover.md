# vp 退役、mise 升正：语言管理器换轨（双仓）

2026-10-31 主人在「双仓如何贴合 fss 产品线开发需求」评估中定夺：fss 的硬前置是 mise（`mise.toml` 同时承担 tools 钉版、env 注入、tasks 包装三面），而两仓声明的语言管理器是 vp（vite.plus，钉 `configs/vp-version`）——Windows 侧 mise 已被手动 winget 安装（`wdc audit` 自装未声明），双管理器并存靠 PATH 优先级裁决，新机器 bootstrap 完 fss 第一步即断；主人确认 vp 仅作 Node 管理器使用、无其他依赖面。

- **vp 全面退役（两仓）**：LDC `install-user-tools.sh` 的 vp 安装/env 编排块、`verify-machine.sh` 断言、`configs/vp-version` 同值钉子、env.sh 生成逻辑中的 vp 落位探测、VSCode 清单 `voidzero.vite-plus-extension-pack`；WDC `install-languages.ps1` 重写、`lib/common.ps1` 助手、`pwsh-profile.ps1` 的 `vite-plus\env.ps1` source、verify/inventory/bootstrap 各面——同轮除名。档案（工单、旧 ADR 正文、CHANGELOG、logs）按「已推送历史不可回改」不动。
- **mise 升正**：WDC 进 `cli-tools.winget`（useLatest，域内惯例免钉）；LDC `install-user-tools.sh` 走 GitHub release 二进制 + sha256 双钉（ADR-0011 模式，双架构经 `ldc_arch()`）。默认环境语义平移：`mise use -g node@lts`（对齐原 `vp env default lts` 的零维护口径），全局不装 pnpm（fss 仓内已钉，通用场景 npm 足够）。
- **存量机器去收敛**：WDC `remove-leftovers.ps1` 增 vp 卸载——vp→mise 属其宪章「迁移冲突」类（WDC ADR-0007）；LDC 一次性豁免：`install-user-tools.sh` 探测到 vp 即调其官方卸载——「只装不删」红线的显式例外，理由：`vp env on` 的 shims 不撤会与 mise PATH 打架，属迁移冲突、非自留地（自留地不碰不变）。
- **钉子同值条款收缩**：`vp-version` 是 dev-standard §6「钉子同值」唯一实例，随退役消失——机制保留、标注当前无实例；LDC 主笔、WDC 同步拷贝。
- **发版**：破坏性换轨 → 双仓同号 v0.9.0（v0.x 破坏性走 MINOR）。

拒绝的替代：双管理器并存（仅声明 mise、vp 留任——PATH 阴影长期化）；fss 弃 mise 改 vp（fss 用的是 mise 的 tasks/env 能力而非仅版本钉子，产品仓治理独立，成本高收益负）；仅 WDC 换轨（同值钉子与 LDC 的 vp 部署面要求两仓同步，单侧制造跨仓断裂）。
