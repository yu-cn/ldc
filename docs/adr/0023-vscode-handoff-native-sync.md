# VSCode 全让位原生设置同步——扩展清单与安装动作退役

2026-11-21 主人定夺（WDC 侧同日同判例，[WDC ADR-0003 修订标注二](https://github.com/yu-cn/wdc/blob/main/docs/adr/0003-universal-core-only.md)）：VSCode 扩展/设置/键位属**账号态**（跟人走的个人配置），VSCode 自带账号级设置同步就是为此而生——仓库强行代理清单等于替账号做主、与原生机制打架。上游 microsoft/WindowsDeveloperConfig 同款边界：只装本体、零扩展管理。

## 决策

- `configs/vscode-extensions.txt` 清单除名；install-user-tools 的扩展安装段、plan-machine 的扩展投影、verify-machine 的扩展清单断言全部退役为 SKIP 行（留痕指向本 ADR）。
- code 本体照装（desktop-apps.pkg，仅桌面机器形态）；登录 VSCode 开启设置同步后扩展/设置/键位自动恢复——账号是事实源。
- 自装扩展不再有「清单 vs 在装」对账面（原 ADR-0003 的不核销原则随清单一并失去对象）。

**修订（2026-11-22，1.0.0 并行批）**：让位范围扩至 settings/keybindings——dotfiles_map 两项与模板除名（README 表述与实现不一致被核对抓出，README 先行而实现滞后）；LDC 与 WDC 自此 VSCode 全让位完全对齐（本体照装，账号态归同步）。

## 取舍

拒绝的替代：**保留清单与同步并行**（两主打架——WDC 侧旧设计「要求关闭原生同步」已被主人撤销，同理不捡）；**折中只交扩展留设置**（同步面板逐项配置跨机不一致，最不干净）。
