# 10: 语言面换轨与补全——vp 退役、mise 升正（联动 WDC 工单39）

**What to build:** 2026-10-31 主人定夺语言面换轨+扩域（[ADR-0016](../../docs/adr/0016-vp-retire-mise-takeover.md) / [ADR-0017](../../docs/adr/0017-languages-surface-consolidation.md)）：动因是 fss 硬前置 mise 与两仓声明的 vp 双轨错位（Windows 侧 mise 已手装未声明，`wdc audit` 自装未声明清单实录）。本仓落点——① `install-user-tools.sh`：vp 安装/env 编排块整体退役换 mise（GitHub release + sha256 双钉、`ldc_arch()` 双架构）+ `mise use -g node@lts` 默认环境；探测到旧 vp 走其官方卸载（「只装不删」红线的一次性迁移豁免，ADR-0016 明示）。② uv 从 curl|sh 升 release+sha256 双钉（ADR-0011）。③ `configs/vp-version` 删除；docker 面核实为已有（root 阶段官方脚本 + ADR-0009 合并）——原拟 docker.pkg 不设（ADR-0017 修正）。④ env.sh 生成逻辑的 vp 落位探测换 mise。⑤ `dotfiles/linux/bashrc` 加 WSL 垫片门控段（clip.exe/explorer.exe 在位才定义 pbcopy/pbpaste/open）。⑥ `verify-machine.sh` / `plan-machine.sh` / `lib/common.sh` / `validate.sh` 换面：mise 在位 + node@lts 解析 + uv 在位进断言；docker 与垫片不进（可选/环境门控）。⑦ `configs/vscode-extensions.txt` 去 `voidzero.vite-plus-extension-pack`。⑧ AGENTS.md 红线1 vp 除名、GLOSSARY vp 面收缩、dev-standard §6 钉子同值标注「当前无实例」（主笔本仓，WDC 拷贝随其工单39）。⑨ README / demo 重录。⑩ 双仓同号 v0.9.0 与 WDC 同日发版。

**Blocked by:** None

**Status:** todo

- [ ] ① install-user-tools.sh：mise 换轨 + vp 一次性卸载豁免 + node@lts 默认
- [ ] ② uv 双钉升级（release + sha256）
- [ ] ③ vp-version 删除；docker 面核实已在位（不设 docker.pkg）
- [ ] ④ env.sh 生成逻辑换 mise
- [ ] ⑤ bashrc WSL 垫片门控段
- [ ] ⑥ verify / plan / common / validate 换面
- [ ] ⑦ VSCode 清单去 vite-plus 扩展包
- [ ] ⑧ AGENTS / GLOSSARY / dev-standard 三处成文
- [ ] ⑨ README / demo 重录
- [ ] ⑩ 本机 WSL 真机验收（bootstrap 收敛、vp 消失、mise+node@lts+uv 就位）+ CI 双架构绿 + v0.9.0 同日发版（联动 WDC 工单39）

## Comments

- 2026-10-31（ASUS 会话，开工）：评估定夺实录——双管理器 PATH 错位为直接动因；上游 WSL Comfort 调研结论「仅 shell 体验层，LDC 已全覆盖」；真机复核修正一处会话内误判：WSL 语言面原已工作（vp+node 26.13.0、uv 双 python），非「全缺」——本单是换轨+补全，不是从零建 languages 面。ADR-0016/0017 随本单提交。
- 2026-10-31（ASUS 会话，实施中事实修正）：① docker 并非声明缺口——root 阶段本就经 get.docker.com 官方脚本安装并加 docker 组（`LDC_SKIP_DOCKER=1` 供 CI 跳过）、daemon.json 走 ADR-0009 受保护合并；评估时的「E2E 引擎缺口」判断有误，ADR-0017 与本单相应修正（不设 docker.pkg）。② vp 官方无卸载命令（安装器 789 行无 uninstall 面、CLI 无 self 子命令）——退役迁移按安装器写入面反向清除（安装目录三处 + ~/.profile 标记行）。③ mise 哈希自官方 tarball 实算、uv 哈希取自官方 .sha256 侧车文件（ADR-0011 双钉口径）。
- 2026-10-31（ASUS 会话，真机收敛实录）：install-user-tools 实跑 exit 0——uv CHANGED 升 0.13.6、vp CHANGED 退役清除（~/.vite-plus 与 ~/.profile 标记行）、mise OK 2026.10.25 + node@lts OK；starship/lazygit SKIP 守钉。bashrc 模板重渲染后登录非交互 `node -v` → v26.13.0（shims 提前至交互守卫之前——登录 shell 经 .profile 间接 source 本文件也要能解析，vp 时代由 .profile 直供的语义补齐）；交互 shell pbcopy/open 函数就位。validate 与 verify --quick 双绿。待办：demo 重录（⑨）、CI 锚点回填、v0.9.0 与 WDC 同日发版（⑩）。
- 2026-10-31（ASUS 会话，CI 锚点）：实现提交 80c1e5a push 后 validate 绿 run 41207518817；fresh-container 冒烟已触发 run 41208421488（结论收口时回填）。
