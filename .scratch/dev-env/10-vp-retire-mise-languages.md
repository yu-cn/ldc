# 10: 语言面换轨与补全——vp 退役、mise 升正（联动 WDC 工单39）

**What to build:** 2026-10-31 主人定夺语言面换轨+扩域（[ADR-0016](../../docs/adr/0016-vp-retire-mise-takeover.md) / [ADR-0017](../../docs/adr/0017-languages-surface-consolidation.md)）：动因是 fss 硬前置 mise 与两仓声明的 vp 双轨错位（Windows 侧 mise 已手装未声明，`wdc audit` 自装未声明清单实录）。本仓落点——① `install-user-tools.sh`：vp 安装/env 编排块整体退役换 mise（GitHub release + sha256 双钉、`ldc_arch()` 双架构）+ `mise use -g node@lts` 默认环境；探测到旧 vp 走其官方卸载（「只装不删」红线的一次性迁移豁免，ADR-0016 明示）。② uv 从 curl|sh 升 release+sha256 双钉（ADR-0011）。③ `configs/vp-version` 删除、`configs/docker.pkg` 新增（ADR-0010 机制）。④ env.sh 生成逻辑的 vp 落位探测换 mise。⑤ `dotfiles/linux/bashrc` 加 WSL 垫片门控段（clip.exe/explorer.exe 在位才定义 pbcopy/pbpaste/open）。⑥ `verify-machine.sh` / `plan-machine.sh` / `lib/common.sh` / `validate.sh` 换面：mise 在位 + node@lts 解析 + uv 在位进断言；docker 与垫片不进（可选/环境门控）。⑦ `configs/vscode-extensions.txt` 去 `voidzero.vite-plus-extension-pack`。⑧ AGENTS.md 红线1 vp 除名、GLOSSARY vp 面收缩、dev-standard §6 钉子同值标注「当前无实例」（主笔本仓，WDC 拷贝随其工单39）。⑨ README / demo 重录。⑩ 双仓同号 v0.9.0 与 WDC 同日发版。

**Blocked by:** None

**Status:** todo

- [ ] ① install-user-tools.sh：mise 换轨 + vp 一次性卸载豁免 + node@lts 默认
- [ ] ② uv 双钉升级（release + sha256）
- [ ] ③ docker.pkg 新增、vp-version 删除
- [ ] ④ env.sh 生成逻辑换 mise
- [ ] ⑤ bashrc WSL 垫片门控段
- [ ] ⑥ verify / plan / common / validate 换面
- [ ] ⑦ VSCode 清单去 vite-plus 扩展包
- [ ] ⑧ AGENTS / GLOSSARY / dev-standard 三处成文
- [ ] ⑨ README / demo 重录
- [ ] ⑩ 本机 WSL 真机验收（bootstrap 收敛、vp 消失、mise+node@lts+uv 就位）+ CI 双架构绿 + v0.9.0 同日发版（联动 WDC 工单39）

## Comments

- 2026-10-31（ASUS 会话，开工）：评估定夺实录——双管理器 PATH 错位为直接动因；上游 WSL Comfort 调研结论「仅 shell 体验层，LDC 已全覆盖」；真机复核修正一处会话内误判：WSL 语言面原已工作（vp+node 26.13.0、uv 双 python），非「全缺」——本单是换轨+补全，不是从零建 languages 面。ADR-0016/0017 随本单提交。
