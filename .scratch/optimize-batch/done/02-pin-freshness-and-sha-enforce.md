# 工单02：钉子新鲜度巡检 + sha256 行必配

Status: done

## 背景

五钉子（uv / mise / starship / lazygit / nerd-fonts）钉的是各工具官方仓库的 release 资产——LDC 唯一的真上游关系；「上游出新版」无提醒面，全靠人记忆。validate 对 sha256 行「有则查格式、无则放行」+ 安装器「缺行仅 INFO」= 「升版本忘更哈希」可落地的缝（红线 1 机械收口缺位）；且检查清单漏 starship-version。

## 内容

- ADR-0020（先写后动代码）
- `.github/workflows/pin-freshness.yml`：每周一 05:00 UTC（与 03:00 冒烟 / 04:00 dev-standard-guard 错峰），GitHub API `releases/latest` 对五钉值，summary 表列「钉 X / 上游 Y」；恒 exit 0
- validate.sh：五钉 sha256 行必配（四分架构钉双 arch 行、nerd-fonts 无 arch 行），starship-version 补入检查清单

## 验收清单

- [x] ADR-0020 落地（含拒绝的替代：不自动升级 / 不红 badge / 不并入 check-upstream）
- [x] validate 本机全绿（现有五钉 sha256 行齐备，收紧后不误伤）
- [x] 故意删一行 sha256 的负路径手测 FAIL（见实录）
- [ ] workflow 首跑待 push 后（schedule / 手动 dispatch）

## 实录

负路径手测：临时从 configs/lazygit-version 删去 arm64 sha256 行 → validate 报 `configs/lazygit-version FAIL 版本行须非空单行、sha256 行必配（双 arch 齐备…）`，恢复后全绿。
另：批次中途主人定性 wsl-comfort 为参考资源非上游（ADR-0014 补记）——本票 ADR-0020 首稿曾以「上游跟进第二维度」挂在 ADR-0014 机制下，已改框架：钉子巡检盯真上游（工具官方仓库），与参考资源对账互不挂靠；check-upstream / 账本 / ldc status 措辞同批换面。
