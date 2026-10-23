# 工单 02 — 双架构一等公民（amd64 / arm64）

## 背景

用户常用机器横跨两种架构：DGX Spark（arm64）与多台 amd64 Linux；WDC 实测过的 WSL Ubuntu 亦属 amd64 Linux。盘点结论：全仓库架构敏感点仅 `ldc_arch()` 一处（lazygit 是唯一按架构选资产的下载），uv/vp/starship/gh 源/get.docker.com 自探测，字体 zip 与 apt 包名架构无关——缺的是「显式承诺 + 验证面」，不是代码改造。

## 内容

- `ldc_arch()` 可传参自测；bootstrap 预检加架构门禁（不支持架构第一步即 FAIL）
- verify 第 4 组加「架构受支持」断言（组名改「语言栈与架构」）
- validate 加架构映射离线自测（x86_64→amd64 · aarch64/arm64→arm64 · riscv64 拒绝）
- CI fresh-container 改双架构矩阵（ubuntu-latest=amd64 + ubuntu-24.04-arm，工件按架构命名，fail-fast 关）
- ADR-0006 新增；ADR-0001 补「WSL 属 amd64 目标但一个发行版只归一个管理器」边界；README/GLOSSARY/AGENTS 同步口径

## 验收

- [ ] validate.sh 全绿（含新增架构映射自测）
- [ ] 本机（aarch64）bootstrap 预检出现「架构 OK …arm64 资产」，exit 2 两族待办不变
- [ ] verify --quick：架构断言 OK，FAIL 仍 11 项两族
- [ ] amd64 面由 CI 矩阵覆盖（推送后首跑判读）

## 实录（2026-10-24）

- [x] validate 全绿，含新增「架构映射自测（ldc_arch）」：x86_64→amd64 · aarch64/arm64→arm64 · riscv64 拒绝
- [x] 本机（aarch64）bootstrap 预检出「[OK] 架构 - aarch64 → arm64 资产」，exit 2 两族待办不变（root 交接 + 身份）
- [x] verify --quick：第 4 组更名「语言栈与架构」，架构断言 OK；FAIL 仍 11 项两族（身份 1 + root 待交接 10）
- [ ] CI 双架构矩阵待推送后首跑判读（本机无法代跑；arm64 腿用 ubuntu-24.04-arm，公开仓库免费）

盘点确认：架构敏感点仅 `ldc_arch()` 一处；uv/vp/starship 安装器、gh 源（dpkg --print-architecture）、get.docker.com 均自探测；字体 zip 与 apt 包名架构无关。
