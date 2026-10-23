# 工单 04 — 桌面应用域（VSCode/Chrome）+ GNOME 优化扩充

## 背景

用户决策：① 桌面 Linux 把 VSCode、Chrome 等常用 GUI 软件纳入统一配置（对齐 WDC editors 域）；② GNOME 桌面优化配置扩充（对齐 WDC base-windows 注册表域的去噪工作）。范围定稿：VSCode + 扩展清单 + google-chrome-stable；Chrome 偏好不管（YAGNI）。关键事实修正：Chrome 官方源已发布 arm64（2026-10 实测 dl.google.com binary-arm64 在库），双架构无需例外。

## 内容

- `configs/desktop-apps.pkg`（code、google-chrome-stable）+ `configs/vscode-extensions.txt`（WDC 底本去 remote-wsl/powershell，30 项）+ `dotfiles/linux/vscode-{settings,keybindings}.json`（WDC 底本去 windows 键 + defaultProfile.linux）
- root：`add_vendor_repo` 原语（gh/vscode/google 三源共用，keyring 幂等、失败清理半成品）+ gsettings 门禁的 desktop-apps 段
- user：扩展幂等安装（code 未装 → INFO 待 root）；dotfiles：vscode 配置链接（gsettings 门禁）
- GNOME 清单 6→12 条（星期几、字体渲染、隐私去噪、dock 点击最小化）；apply/verify 两侧 schema 存在性降级（Debian 无 Ubuntu Dock → SKIP 非 FAIL）
- verify：桌面应用核销 + vscode 链接 + 扩展清单断言；root_stage_complete 纳入 desktop-apps；validate 扩展格式与模板在位
- ADR-0008 新增；ADR-0005 补记 schema 降级；README/GLOSSARY 同步

## 验收

- [ ] validate 全绿
- [ ] 本机 bootstrap：root 回到交接态（desktop-apps 未装）、扩展 INFO（code 未装）、vscode 链接创建、GNOME 新 6 条真实应用
- [ ] verify：新增 FAIL 全在「待 root 交接」族；全量模式 12 条读值比对过
- [ ] 推送后 CI validate + fresh-container 双架构绿（容器无 gsettings → 全域 SKIP 不受影响）

## 实录

（执行后回填）
