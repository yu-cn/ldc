# 0015 — dotfiles 落点改为安装期渲染拷贝，不再符号链接

日期：2026-10-25 · 状态：已接受 · 取代：ADR-0002 中「dotfiles 由 bootstrap 符号链接安装」条款（AGENTS 红线 4 同步反转）

## 背景（谁在什么场景问的）

主人 2026-10-25 提出系统配置管理的两个结构性问题：① **系统配置对仓库强制依赖**——落点是直指仓库内文件的符号链接，仓库缺席/搬移即 `~/.gitconfig` 死链、git 一切命令 fatal（死链挡 clone 本身，坑1 实录），bash/starship 静默降级；② **系统变动反向逼仓库适配**——机器工具写穿符号链接污染仓库（WDC 坑6/14：WT/VSCode/gh 实录，养出防写穿断言 + triage + 禁 git add -A 一整套税），工具布局漂移逼模板追路径（bashrc 为 vp env 硬编码 5 条候选路径）。

业界对照（同日研究）：chezmoi 源目录全存普通文件、apply 渲染拷贝，symlink 仅显式 opt-in——其 diff/apply/verify/update/re-add 与 ldc plan/bootstrap/verify/sync/triage 命令面一一对应，唯一系统性分歧恰是链接 vs 拷贝；GNU stow（symlink 派）的写穿与「应用原子替换断链」是社区公认痛点；Ansible 的 facts + 模板证明「机器事实安装期落盘、模板不含布局猜测」是成熟做法；GitOps 铁律「运行面不得依赖控制面在线」被 symlink 模型违反。

## 决策

1. **落点 = 安装期渲染拷贝**：bootstrap 把模板内容拷贝到落点，模板仍是唯一声明源；例外仅 `~/.local/bin/ldc`（CLI 入口保持符号链接，跟随仓库）。落点映射入 `scripts/lib/common.sh` 单一来源（`dotfiles_map`，安装/断言/预演/分流/快照五方共读，对齐 WDC dotfiles-map.ps1）。
2. **覆盖前轮转备份**：落点与模板内容不同→备份 `.bak`（已存在则 `.bak.N` 递增）再渲染——机器侧内容绝不静默丢弃；同内容幂等跳过；符号链接残形（v0.5 旧安装形态/外来链接）直接替换不备份（链接本体可再造，指向内容不受影响）。
3. **可见性迁移**：verify/status 的 dotfiles 断言由「readlink 相等 + dotfiles/ 与 HEAD 一致」改为「落点内容与模板一致」——断效果不断实现（WDC 坑11 教训）；防写穿断言退役（写穿不再可能）。bashrc 契约自测入 validate（模板不得再硬编码工具布局路径）。
4. **triage 语义平移**：漂移=落点≠模板；吸收=落点内容回写模板并显式路径暂存（禁 git add -A 红线不变）；还原=自模板重渲染。
5. **工具布局事实出模板**：install-user-tools 安装期探测（vp env 脚本、fzf 示例路径）写 `~/.config/ldc/env.sh`，bashrc 模板只 source 该文件——上游换布局只改安装器，模板不再追路径。

## 取舍

- 改模板不再即时生效，须重跑 bootstrap（`ldc sync` 日常路径本就如此；旧模型下未 commit 的模板改动本就会被防写穿断言打 FAIL——收敛语义实际等价）。
- 手改落点会在下次收敛被覆盖——持久改动走 triage 吸收或自留地（`.bashrc.local` / `.gitconfig.local`），覆盖前 .bak 兜底不丢内容。
- 机器与仓库的运行时耦合归零：仓库缺席仅影响 ldc CLI 自身（自描述报错指引恢复）；坑1 恢复配方降级为历史档案。
- 与 ADR-0004「机器派生值不入库、安装期渲染到机器本地」同构：本决策把落点整体视为渲染物，两仓概念统一。
- 漂移方向判定（区分「模板更新了」vs「机器改了落点」，chezmoi persistent state 的最小化版 rendered.sha256）本版不做，留作增强——轮转备份 + triage 逐文件两问已够用。

## WDC 条款（ADR-0007 统筹）

Windows 侧同改渲染拷贝：install-dotfiles.ps1 改 Copy-Item（其轮转备份 Get-BackupPath 语义与本 ADR 一致）、verify 断言改内容比对、triage 平移、pwsh profile / bashrc 的「dotfiles 漂移即时提示」（工单24）改读内容比对。WT/VSCode/gh 的写穿税（坑6/14）与 reparse 双路径痛（工单35）一并消除。双仓共用决策落 LDC 编号、WDC 侧引用不复制；WDC 侧实施在 Windows 侧会话进行（本决策定稿时实施机无 pwsh，pre-commit 硬关不可绕）。

## 拒绝的替代

- **chezmoi/yadm/stow 本体**：命令面已同构，引入只换来多余常驻实体（简洁偏好裁定）。
- **保留 symlink + 防死链守卫**（gitconfig stub include、bashrc source-if-exists）：消 fatal 但治标——写穿税、triage 面、双文件间接层全保留。
- **混合模型**（高危落点拷贝、低危留链接）：双心智模型，triage 面翻倍，无业界先例。
- **hardlink**（stow 社区提案）：跨文件系统失效，rename 式写穿照样断链。
