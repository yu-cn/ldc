# spec · LDC 1.0.0 定版（grilling 三轮收口，2026-11-22）

Status: grilling 收口 → 执行（工单 02/03/04）
Type: program

## 定夺

主人 2026-11-22 三轮 grilling 逐轮批准（R1 六问 / R2 四问 + Linux 原生 steer / R3 三问）。1.0.0 总口径：**机制面零新增、已齐面宣告定版、叙事面 Linux 原生做足**——不照搬 WDC 的 Windows 工作（主人 steer 明示）；承诺面同构、注脚按 Linux 事实。

里程碑加持项对齐 WDC 六件：README 翻新 ✓ / SemVer 宣告 ✓ / demo 重录（三段 `ldc`/`ldc plan`/`ldc exit` 预演，verify 出镜让位）/ 坑档空过（11 月下半无新实录，主人无点名）/ 钉版回退预案（notes 已知事项 `LDC_TAG=v0.14.0`）/ 归档照收。

## 承诺面（README / notes / CHANGELOG 收节同用）

「**一次性配置 + 显式更新/回归 + 完整退出（`ldc exit` / undo 表 / 升级指引）+ 漂移合法不纠察**」——WDC 1.0.0 承诺面的同构四件套；LDC 注脚：还原基准 = dpkg 账本 + undo 表（无注册表故无 pre-install 快照，见下）。

## 三件对应物缺口的定性（WDC 有、LDC 定为不做）

| WDC 件 | LDC 定性 | 落档 |
|---|---|---|
| pre-install 快照 | apt 面 undo 由 dpkg 账本机械可推导、dotfiles 落点 `.bak` 即首次渲染前快照、daemon.json 只写声明键——「不可推导原值」面不存在 | `docs/undo-table.md` 头部定性句 |
| clean-legacy 命令 | 自家残留面≈空：vp 随航（ADR-0016）/ wsl-comfort 一次性清档（ADR-0018）/ 链接残形渲染期替换（ADR-0015）/ `.bak` 轮转自管理 / 状态目录 exit 删 | `docs/cli-parity.md` ldc 列「—」脚注（双仓同源，改后 WDC 侧拷贝） |
| CLI 注入用户选择 | 无痛点信号；1.0.0 前夜加交互面 = CI + 契约 + 模板三处成本 | 本 spec 遗留观察 |

## 对照面在档（不单开对照研究）

LDC 无血统上游，三段对照各有在档：WDC 同构面（cli-parity + 双仓纪律持续对齐）；wsl-comfort（ADR-0014 参考资源定性 + ADR-0018 清残吸收完毕）；业界（ADR-0015 chezmoi/stow/Ansible 对照在档）。

## Linux 原生面定夺（2026-11-22 steer）

机制候选逐一过判据（ADR-0003 通用核心 / 自留地 / 只装不删 / 不替系统做主），全部不进 1.0.0 机制面：

- **sysctl 调优（inotify 等）：后移待实录**——本机 watches=524288（VSCode 推荐值即此）、instances=128，无撞限实录；真撞限再按 sysctl.d 声明文件 + 受保护合并同款配方开票
- snap/flatpak 政策、unattended-upgrades、fstrim/zram/swap：不做——系统策略不接管
- apt autoremove/autoclean：不做（红线「只装不删」+ 红线 11，无讨论空间）
- GNOME opinion：desktop.gsettings 14 条定版，点名口随 1.0.0 关闭（后续加随时开票——声明面是平的，加一行就是）

叙事骨架五件（README 翻新 / release notes 展开面，全部为已实现面的重新表达，零机制变更）：① 双发行版 × 双架构四腿 CI 实证 ② apt + dpkg 账本——安装即记账、还原可机械推导 ③ gsettings 桌面域按需启用，含 ibus-rime 中文输入整链 ④ daemon.json 受保护合并、绝不自动重启 ⑤ 可选包组自选语义。

## 遗留观察（不阻塞；前两条为 WDC checklist 遗留观察的答复，经主人回告 WDC 侧）

- **Chrome 不除名**：desktop-apps.pkg 是可选包组（ADR-0010 指名安装、不进断言）——WDC「通用消费软件出局」判例的压力被自选语义天然消解
- **exit T3 已消解**：WDC 遗留观察②写于 `ldc exit` 落地前；`ldc exit` 即那个「未备卸载器」，WDC T3a 指路即完全体
- CLI 注入用户选择：见定性表
- sysctl 调优：后移待实录（见上）

## 汇合点（两案备态，发布票开跑前主人定夺）

WDC checklist 门槛⑧已写「双仓 v1.0.0 同号同日」、执行序③=「LDC CHANGELOG 收节（WSL 内）」——WDC 侧已按 A 案铺路。

- **A 案 同号同日**：与 WDC 会话协同，LDC 收节 commit 由本会话做，随后双仓 tag → 双仓 release 同会话收口
- **B 案 随后独立发**：本仓自行 tag/release；WDC 侧门槛⑧需其会话改

## 工单群

- **02 内容批**：README 里程碑翻新（承诺面句 + 叙事骨架五件 + 四件事口径核对）/ SemVer 宣告 / undo-table 定性句 / cli-parity 脚注（含 WDC 拷贝步）
- **03 demo 重录**：三段 `ldc` / `ldc plan` / `ldc exit` 预演
- **04 发布主票**：门槛制（终验 ①② 必做 ③ 可选 + 收节 + notes）+ 执行序两案备态

## 沿革

立项开票 aa88b80 → 并行技术件 e8fb90f（undo 表 / 升级指引 / ADR-0023 修订，工单01 已归档）→ 移交快照 f441aa8（已齐面清单与双仓纪律在彼处存档）→ 本定版。终验实机口径：单机（本机 WSL Ubuntu）；如报第二台实机补双机半场。
