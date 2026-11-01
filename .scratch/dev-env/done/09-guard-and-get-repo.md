# 09: 批量打磨——get.sh 仓库覆盖 / 同源守护 / 版本对齐入册

**What to build:** 对齐 WDC 工单38（批次评估 2026-10-26，主人定夺「全都按建议来」）：① get.sh 支持 `LDC_REPO` 覆盖引导地址——fork 用户一条命令对齐手动路径（README 现说 fork 走手动路径，门面与体验不匹配）；补 `LDC_TAG` env 钉版（与既有位置参数同义，跨仓形态对齐 WDC get.ps1 的 env 口径）。② CI 新增 dev-standard 双仓同源守护工作流——主作者位在本仓（LDC），每周拉姊妹仓 WDC 的拷贝去 CR 归一比对，漂移即红；刻意不挂 push（双仓协同编辑必有先后，瞬时红污染 badge），漂移窗口 ≤7 天足够（成因是忘同步，非紧急事故；本批起 WDC 侧 .gitattributes 也钉了该文件 LF 消行尾假红）。③ dev-standard §5 补「双仓版本对齐」约定：双仓联动变更（委托契约 / 同源规范 / 同值钉子）发版时两仓版本号对齐收口——LDC_TODO 契约变更两仓同批积压 Unreleased 的实录定规矩。

**Blocked by:** None

**Status:** done

- [x] get.sh：LDC_REPO / LDC_TAG；README fork 段与求稳行同步
- [x] CI：dev-standard-guard 工作流（每周 + 手动 dispatch，去 CR 归一比对姊妹仓 WDC）
- [x] dev-standard §5：双仓版本对齐一行（主作者位本仓先改，WDC 同步拷贝随其工单38）
- [x] CHANGELOG Unreleased 记账
- [x] CI 绿锚点回填（validate / dev-standard-guard）

## Comments

- 2026-10-26（LETH 会话，CI 锚点）：push 后 validate 绿 run 40351916163（3e90a65）；dev-standard-guard 手动 dispatch 首跑绿 run 40352203611（8s）——本仓拷贝与姊妹仓 WDC main 逐字一致（含 §5 新条）实证，WDC 侧对跑 40352211960 同绿。