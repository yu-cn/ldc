# 12: 承接 WDC 移交三件——默认 shell / wsl.conf / docker 组归位（联动 WDC 工单41）

**What to build:** WDC 工单41（边界最小核心化，主人 2026-11-01 定夺并解除跨仓限制；WDC GLOSSARY「双边最优化」词条化）把 `setup-ubuntu.sh` 薄委托 wrapper 的最后三件「WDC opinion」移交本仓单一实现（ADR-0007 补记 2026-11-01）——根因是 WDC root 直调缺 SUDO_USER 而在包装层保留的临时职责。本单承接：

- ① `scripts/install-packages.sh`（root 阶段唯一脚本）新增「机器形态」段：
  a. **默认 shell = bash**（幂等 chsh；操作对象 `root_target_user()` = SUDO_USER ?: LDC_USER——委托方 WDC root 直调经 `LDC_USER` 显式传入 WSL 默认用户，容器 root 冒烟两者皆空跳过）
  b. **wsl.conf systemd=true**（`is_wsl` 内核探测门控；写入后提示 `wsl --shutdown` 生效语义与原 WDC 实现一致；非 WSL 形态 SKIP）
  c. **docker 组 usermod 归位**（原 SUDO_USER 块扩 LDC_USER 兜底）
- ② **docker 跳过自判定**：common.sh 新增 `docker_skipped()` 单一来源——`LDC_SKIP_DOCKER=1` 外部覆盖优先，否则无 systemd 中间态（`/run/systemd/system` 缺席）自跳；安装面（install-packages 两处）、verify-machine.sh、`root_stage_complete` 四处换面同读。原「WDC 探测 systemd 后透传 LDC_SKIP_DOCKER=1」退役，env 变量保留为外部覆盖语义（CI fresh-container 显式 `LDC_SKIP_DOCKER=1` 行为不变）
- ③ **verify-machine.sh 断言面补齐**：新增「默认 shell = bash」（全形态）与「systemd 生效」（is_wsl 门控）两断言——承接 WDC probe.sh 的 WSL 特有两键（probe.sh 由 WDC 侧随 Phase B 退役）；五组断言扩为六组

**Blocked by:** None（WDC 侧撤除属其 Phase B，工单41 下游——本单先行承接，撤除后双仓迁移验收）

**Status:** done

- [x] ①a 默认 shell chsh 进 install-packages.sh（幂等，root_target_user 判定）
- [x] ①b wsl.conf systemd=true（is_wsl 门控，写入提示 wsl --shutdown 语义）
- [x] ①c docker 组归位（LDC_USER 兜底）
- [x] ② docker_skipped() 单一来源 + 四处换面
- [x] ③ verify 六组断言（shell 全形态 / systemd is_wsl 门控）
- [x] validate.sh 全绿 + 本机 verify --quick 全绿 + fresh-container CI 绿
- [x] ADR-0007 补记（LDC_USER 契约 + 三件移交 + docker_skipped 口径）
- [x] 联动 WDC Phase B 撤除后双仓迁移验收（重跑 bootstrap 全绿 + wdc verify 含委托段全绿）

## Comments

- 2026-11-01（ASUS 会话，联动 WDC 工单41 开单）：承接范围出自 WDC 侧工单41 的保留职责分类表（3 件移交 / 3 件半留 WDC）。设计要点：`LDC_USER` 为新增委托契约（同 LDC_TODO 先例，字面量变更与 WDC setup-ubuntu.sh 同日双改）；`docker_skipped()` 把「无 systemd 中间态」的判定从调用方收进本仓（安装面与 verify 面同口径，杜绝两侧判定漂移）。CI 影响核实：fresh-container.yml 三步显式 `LDC_SKIP_DOCKER: '1'`，自判定对容器路径零行为变化。
- 2026-11-01（ASUS 会话，实施收口）：落地 006c2e5 + 顺手项 188c02e。实施记录两坑：UNC 跨界编辑两次削掉脚本可执行位（100755→100644，git update-index --chmod=+x + chmod 工作区双修后 amend）——后续跨侧编辑 bash 脚本后须核对 mode。真机验收全过：validate exit 0；verify --quick 新 6/6 段双 OK（默认 shell=bash、systemd 生效——is_wsl 门控实弹命中）；bootstrap 重跑幂等（exit 2 = 恰为桌面域单一待办，WSL 形态既定预期语义）。CI 锚点：validate 41318016230 / 41318766810 / 41319159845 绿；fresh-container 41319222742（dispatch 实跑）双架构 smoke + handoff 全绿——容器路径 docker_skipped 走外部覆盖、chsh 无目标用户跳过、verify shell 断言 root /bin/bash 全部按预期。
- 2026-11-01（ASUS 会话，双仓迁移验收）：WDC Phase B 撤除（e8bb745）后 wdc sync 全量 388s 全绿——新委托链逐行实证：`[SKIP] apt-get update - 索引 24h 内已更新（本地判定）`（顺手项实弹命中）、机器形态三件全 SKIP 幂等（ubuntu 已是 bash / wsl.conf 已启用 / docker 组已在组）、「WDC opinion」包装层文案消失；verify 第 5 组只余 LDC 退出码透传 `[OK] WSL LDC verify --quick`，两键断言由 LDC 6/6 段承接。bashrc 重渲染实证：交互 shell 实际导出 FZF_CTRL_T_OPTS 预览参数（断效果断言）。
