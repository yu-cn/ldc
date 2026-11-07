# 工单01：Docker 安装面收编厂商 apt 源

Status: done

## 背景

全仓优化审查（2026-11-07）：install-packages.sh 的 docker 安装是最后一个 `curl | sh` 网络管道面；audit 的特殊安装面清单本就按 docker-ce 系包名记账（get.docker.com 底层配的就是 download.docker.com apt 源）——安装方式与记账口径错位。

## 内容

- ADR-0019（先写后动代码）
- install-packages.sh docker 段换 add_vendor_repo 配方：keyring（download.docker.com/linux/<distro>/gpg）+ 源（codename 直取 os-release）+ 一次 apt 事务装 docker-ce / docker-ce-cli / containerd.io / buildx / compose 插件
- marker `download\.docker\.com/linux/(ubuntu|debian)` 判重兼容既有安装（含 deb822 形态）
- verify / plan / audit / README / GLOSSARY 文案换面

## 验收清单

- [x] ADR-0019 落地（含取舍与拒绝的替代）
- [x] validate / verify --quick / plan 本机全绿
- [x] marker 判重逻辑对 get.docker.com 既有机器幂等（have docker 先行 SKIP）
- [ ] CI fresh-container 冒烟（docker 域被 LDC_SKIP_DOCKER 跳过——安装面实证待有 systemd 的真机/后续）

## 实录

安装事务路径由 add_vendor_repo + apt-get 与 gh 段完全同构（该配方已被 gh/VSCode/Chrome 三处在产验证）；docker 安装面本身因 CI 容器无 systemd 不在冒烟覆盖内，此缺口本就存在（get.docker.com 时代同样跳过），留待真机实证后补锚点。
