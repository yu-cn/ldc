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

## 实录

- **CI 冒烟抓到幂等破绽（2026-10-25，run 40211476066）**：容器 `/root` 无 `.bashrc`，首跑渲染后落点成为实体文件；第二遍时迁移阶段旧判据「非符号链接」把自家渲染物误当待接管原始文件，重复 `.bashrc.bak` 备份 → CHANGED → 幂等关卡红。修复：首接管判据改为「自留地不存在」（兜底块保证任何一跑后 `.bashrc.local` 必在）。教训：接管类判据不能依赖「落点是不是链接」——渲染模型下落点恒为实体文件，「已完成」的标记是产物（自留地）而非形态。
- **同日并行撞车（编号）**：本决策起草时定 ADR-0013，另一会话的上游借鉴工单（flock，ADR-0007 统筹）先占 0013/0014 并推 origin——本决策顺延 0015，全库引用同 commit 改齐；变基零冲突落地。dev-standard §6 并行规则再添一例。
