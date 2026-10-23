# 工单 01 — LDC 骨架落地 + DGX Spark 首接入

## 内容

按 HANDOFF.md 第 4 节蓝图写全部骨架：configs 清单与钉子、dotfiles 三模板、lib/common.sh、六阶段脚本、bootstrap/validate 入口、ldc CLI、ADR×5、GLOSSARY/AGENTS/README/LICENSE、pre-commit 钩子、CI×2、.scratch 工单流。然后 `git init`（不 commit）→ validate 全绿 → 本机 bootstrap 试跑 → verify --quick 如实出报告。

## 验收

- [ ] validate.sh 全绿
- [ ] bootstrap：root 交接路径（sudo 需密码）、user 工具实装（vp/starship/lazygit/字体）、桌面 SKIP、dotfiles 接管 + .bashrc.local 迁移（dgx-spark 块 + nvm 块）、exit 2
- [ ] verify --quick：FAIL 仅身份未填 + root 待交接两族
- [ ] 交接清单交付机主：root 命令 / 填身份后首次 commit / 桌面登录重跑
- [ ] 不做首次 commit

## 实录（2026-10-24）

- [x] validate.sh 全绿（本机无 shellcheck → 警告放行段；CI 兜底）
- [x] bootstrap：root 走交接路径（sudo 需密码）、uv/vp/starship/lazygit/字体实装、dotfiles 接管 + .bashrc.local 迁移（dgx-spark 块 + nvm 块原样保留，`gs=nvidia-smi` 机器别名胜出）、exit 2（2 项待办）；二次重跑全 SKIP/一致，幂等成立
- [x] verify --quick：11 项 FAIL 全部落在两族——身份未填（护栏）+ root 待交接（9 个 cli-tools 包 + gh）；dotfiles 链接/钩子/语言栈/字体全绿，无 commit 降级 INFO 生效
- [x] 交接清单已交付机主；未做首次 commit（身份未填）

**与 HANDOFF 记载的三处差异（以实测为准）**：
1. lazygit arm64 资产名为小写 `lazygit_<ver>_linux_arm64.tar.gz`（HANDOFF 记 `Linux_arm64`）；钉 0.66.2
2. `desktop.gsettings` touchpad 行：HANDOFF 的 4 词写法不是合法的 `gsettings set` 参数；实测存在独立 schema `org.gnome.desktop.peripherals.touchpad`，已改 3 词写法（validate 清单校验抓出）
3. 桌面域在本机 SSH 上下文**没有 SKIP**：环境带活跃会话总线（`DBUS_SESSION_BUS_ADDRESS=/run/user/1000/bus`、`DISPLAY=:1`），gsettings 真实应用 1 项（show-hidden-files false→true），字体同轮装毕——HANDOFF 预期的「手工步骤 3（桌面登录后重跑）」实际已在本轮完成；全量 verify 6 条读值回读一致

**其他**：nerd-fonts 钉 3.5.1；code-review 两轴自检一轮（spec 无缺失；standards 修掉 README 硬编码版本号、交接命令 4 处复制、判定行重复、桌面会话探测 2 处复制、命令清单硬编码、AGENTS 补 POSIX sh 例外）

**后续（同日，机主执行 root 交接后）**：root 阶段核销全绿（两清单 21 包 + gh + docker）；shellcheck 随 root 阶段就位、validate 转硬把关，修掉首批发现（SC2088 显示文案豁免 ×3、pre-commit 注释以 `# shellcheck` 开头被当指令、common.sh 加 `shell=bash` 声明）；bootstrap 交接闭环补完——需密码形态先 `root_stage_complete()` 核销，已完成的交接不再重复列为待办（exit 2 待办从 2 项降为身份 1 项）。
