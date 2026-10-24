# 双仓统一开发规范：CONTRIBUTING（对外）+ dev-standard（对内）

用户要求为 LDC 与 WDC 构建科学、统一、高效的开发规范。盘点发现三处不对称：提交规范 LDC 刚入档（Conventional Commits 1.0.0）而 WDC 只有实践无文字；CONTRIBUTING（对外贡献指南）WDC 有而 LDC 无；内部流程（工单 / ADR / 发布 / 质量关卡）两仓都有成熟实践但散在 AGENTS、ADR、工单实录里，无单一文件可引用。

解法：三层文档各司其职——**AGENTS.md 保持 agent 契约**（红线 / 自查 / 指针）；**CONTRIBUTING.md 面对外部贡献者**（fork 用法 / PR 路径 / CI 说明）；**`docs/dev-standard.md` 承载内部开发规范**（分支提交 / 工单 / ADR / 关卡 / 发布 / 双仓统筹 / 供应链），双仓同源拷贝、**主作者位在 LDC**——与 dotfiles/linux 主作者位同款统筹模式（ADR-0007），不一致以 LDC 为准。规范来源原则写进文档头：只显性化已验证实践，每条规则有 ADR / 事故 / 惯例支撑，新流程先过 ADR。

拒绝的替代：合并进大 AGENTS.md（agent 契约与主人流程混装，且 WDC 的 AGENTS 是指针式结构，强行统一要重构两仓入口文档）；标准只放一仓另一仓放链接（跨仓链接漂移，离线 clone 不可读——同源拷贝 + 主作者位是已验证的统筹模式）；只统一提交格式不管其余（工单 / 发布 / 统筹的对称缺口同样是债）。

WDC 侧落地：同步 dev-standard.md 拷贝 + CONTRIBUTING 补指针 + AGENTS 补指引；提交遵循本文规范（docs: 前缀）。本仓 AGENTS 的提交约定条目同步改指本文（原条目并入，避免双源）。
