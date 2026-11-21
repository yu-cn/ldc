# 02 内容批——README 里程碑翻新（Linux 原生叙事）+ SemVer 宣告 + 两处定性

Status: ready-for-agent
Type: task

## 定夺

grilling R1 Q5a/b + R3 Q3（spec 定版 2026-11-22）：叙事面原生做足——承诺面句同构 WDC 四件套，展开面用「Linux 原生强项五件」骨架，不逐词翻 WDC 的 Windows 工作。

## 内容

1. **README 里程碑翻新**：
   - 首段补「1.0.0 承诺面」句（spec 承诺面原文）+ 装完即走锚链（升级指引 / 退出面文档互链）
   - 「安全与边界」段按叙事骨架五件重排表达：双发行版×双架构四腿 CI / apt+dpkg 账本（安装即记账、还原可推导）/ gsettings 桌面域按需启用含 ibus-rime / daemon.json 受保护合并绝不自动重启 / 可选包组自选语义
   - 「首次运行你需要配合的四件事」口径核对（ADR-0023 让位后 VSCode 相关条的口径按 LDC 事实定）
   - 钉版示例核对（现有 `<tag>` 泛化示例够用则不动）
2. **SemVer 1.0.0 宣告**：CHANGELOG.md 前言补「1.0.0 起 SemVer 完整生效——破坏性变更走 MAJOR，承诺面即『一次性配置 + 显式更新/回归 + 完整退出』」（对齐 WDC 前言文案；落前言不触发 changelog-standard.md 双仓同步）
3. **undo-table.md 头部定性句**：apt 面 undo 由 dpkg 账本机械可推导、dotfiles `.bak` 即首次渲染前快照、daemon.json 只写声明键——LDC 无「不可推导原值」面，故无 WDC 式 pre-install 快照（结构差异，非缺口）
4. **cli-parity.md ldc 列脚注**：clean-legacy 行 ldc 列「—」处补定性（ADR-0016 随航 / ADR-0018 一次性清档 / ADR-0015 渲染期替换——LDC 无版本残留清扫面）。**双仓同源文件：本仓提交后 WDC 侧拷贝（WDC 会话动作）**

## 验收

- [x] README 承诺面句 / 骨架五件 / 四件事口径与 ADR-0022/0023/0024 及 docs/upgrade-v1.md 互链一致
- [x] CHANGELOG 前言宣告与 WDC 侧文案同构
- [x] cli-parity 改动落档（WDC 侧拷贝步在 Comments 留痕）
- [x] bash validate.sh 绿

## Comments

- 2026-11-22 开票（grilling 收口批）；同日实施收口（待 commit）。
- **核对抓出工单01 漏网两处陈旧引用**：README 四件事第 4 条仍是「关闭 VSCode 设置同步」（与 ADR-0023 让位判例相反，WDC 侧已反转同条）——已反转为「登录 VSCode 同步」；「一条命令得到什么」dotfiles 段仍列「VSCode settings/keybindings」（e8fb90f 已 dotfiles_map 7→5+模板除名）——已除名。
- 骨架五件落点核实：③gsettings/④daemon 受保护合并/⑤可选包组 README 原本已原生在位（完整清单段），仅②apt+dpkg 账本位补写进「安全与边界」；①在「支持的机器形态」段——最小编辑达成，未整段重写。
- **WDC 侧拷贝步（跨仓，WDC 会话动作）**：docs/cli-parity.md 本仓已改（clean-legacy 行 ldc 列定性脚注），WDC 侧需同步拷贝。
- CHANGELOG 前言 SemVer 宣告与 WDC 侧文案同构（WDC 用『』、本仓按 CHANGELOG 既有「」体例）；落前言未触发 changelog-standard.md 改动，无双仓同步义务。
