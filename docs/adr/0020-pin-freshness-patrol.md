# ADR-0020：版本钉子新鲜度巡检与 sha256 行必配收口

- 日期：2026-11-07
- 状态：已接受（2026-11-07 优化批定夺，工单 optimize-batch 02）

## 背景

LDC 独立自持，唯一的真上游关系在钉子资产一侧：五钉子（uv / mise / starship / lazygit / nerd-fonts）钉的是各工具官方仓库的 release 资产，但「上游出新版了」没有任何提醒面，全靠人记忆。同时 validate 对 sha256 行是「有则查格式、无则放行」，与安装器的「缺行仅 INFO 未校验」叠加，构成「升版本忘更哈希」仍可落地的缝（红线 1 的机械收口缺位）；且 validate 的钉子检查清单漏了 starship-version（四钉在册、实为五钉）。

（勿混同：check-upstream 对账的 wsl-comfort 是参考资源不是上游——ADR-0014 补记 2026-11-07 定性；本决策与那个机制语义不同、互不挂靠。）

## 决策

1. **pin-freshness 周巡检 workflow**（`.github/workflows/pin-freshness.yml`，每周一 05:00 UTC，与 fresh-container 03:00 / dev-standard-guard 04:00 错峰）：GitHub API 查五工具上游的 `releases/latest`，与 `configs/*-version` 钉值不同即在 workflow summary 列明细（不做版本序比较，只报「钉 X / 上游 Y」供人判读）。
   - **只提醒不升级**：钉子升级 = 人的决定 + sha256 同 commit 重算（ADR-0011），自动化升级会绕过重算纪律；
   - **恒 exit 0**：钉子滞后于上游是常态而非事故，不红 badge（对齐 dev-standard-guard 拒绝瞬时红的取舍）。
2. **validate 收紧为「sha256 行必配」**：分架构四钉（uv / mise / starship / lazygit）须双 arch sha256 行齐备、nerd-fonts 须无 arch sha256 行——缺即 FAIL（ADR-0011 的机械收口）；starship-version 补入检查清单。安装器保留缺行 INFO 降级为防御层（validate 在 pre-commit 与 CI 双把关后，正常运行已不可能缺行）。

## 拒绝的替代

- 自动升级 PR / 自动重算哈希：绕过 ADR-0011 的「人审资产真伪」环节，供应链决策不外包给自动化。
- 钉子陈旧即 workflow 红（exit 1）：钉版本的本意就是滞后于上游，红 badge 是噪声（同 dev-standard-guard 拒绝 push 触发的理由）。
- 并入 check-upstream.sh：那个脚本对账的是参考资源 wsl-comfort 的 apt 数组（非上游，ADR-0014 补记），对象与巡检节奏都不同；混在一起会互相绑架。

## 统筹

与 WDC 无联动——钉子同值当前无实例（ADR-0016 后），各仓钉子各管各。
