# Spec：dotfiles 渲染拷贝（反转符号链接模型，ADR-0015）

> 编号补记：决策起草时定 0013，同日另一会话的上游借鉴工单（flock 运行锁）先占 0013/0014——本决策顺延为 **0015**。

## 背景

主人 2026-10-25 提出系统配置管理两个结构性问题：①系统配置对仓库强制依赖（符号链接落点，仓库缺席=git fatal，坑1 实录）；②系统变动反向逼仓库适配（机器工具写穿污染仓库、工具布局漂移逼模板追路径）。业界对照与决策全文见 [docs/adr/0015-copy-render-not-symlink.md](../docs/adr/0015-copy-render-not-symlink.md)。

## 决策（环境主人 2026-10-25 定夺）

1. 落点=安装期渲染拷贝（例外：`~/.local/bin/ldc` 保持符号链接）；覆盖前轮转备份 `.bak` / `.bak.N`
2. 可见性迁移：verify/status 改「落点内容与模板一致」内容断言；防写穿断言退役
3. triage 平移：吸收=落点回写模板（显式路径暂存）/ 还原=自模板重渲染
4. 工具布局事实外置：install-user-tools 探测写 `~/.config/ldc/env.sh`，bashrc 只 source 它
5. 落点映射入 common.sh 单一来源（`dotfiles_map`，五方共读）

## 验收清单

- [x] validate 全绿（含新增自测：entry_state 状态判定 / 映射模板在位 / bashrc 契约）
- [x] ldc plan 投影显示「符号链接 → 渲染拷贝」迁移（5 落点 PLAN、ldc CLI OK）
- [x] 本机真实迁移：install-dotfiles 后落点为实体文件（`-rw-r--r--`）、内容与模板一致；`.bashrc.bak` 最早原件保全
- [x] verify --quick 全绿；迁移前写穿漂移（gh 凭据段已在 local）+ 迁移中 VSCode 写落点（explorer.confirmDragAndDrop=false，模型上线即刻被内容断言抓到，按 ADR-0003 判据吸收进模板）
- [ ] CI fresh-container 冒烟绿（push 后看 run）
- [ ] WDC 侧对等实施（本机无 pwsh，待 Windows 侧会话；以 ADR-0015 WDC 条款为准）
