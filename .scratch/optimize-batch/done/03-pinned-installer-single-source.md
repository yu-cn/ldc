# 工单03：四段钉子安装器收编单一来源

Status: done

## 背景

install-user-tools.sh 的 uv / mise / starship / lazygit 四段「下载 → 落盘验 sha256 → 解压 → install → CHANGED/OK 报数」约 200 行近逐字拷贝，文案已现细微漂移——与本仓「单一来源」文化（ldc_arch / dotfiles_map / root_handoff_cmd 先例）相悖。

## 内容

- common.sh 新增 `pinned_tarball_install <名> <钉子文件> <bin> <url> <解压内路径>:<落点>…`：SKIP/下载/校验/解压/逐件安装/报数全流程单一来源；sha256 缺行为防御性 INFO（validate 已必配）
- common.sh 新增 `LDC_TMP_DIRS` + `ldc_tmp_register` / `ldc_tmp_cleanup`：临时目录登记制
- install-user-tools.sh 四段换调用，资产命名例外（rust triple / x64 / x86_64）注释保留在调用点；字体段 tmp 一并登记
- trap 三件（EXIT/INT/TERM）——中断不在 /tmp 留残

## 验收清单

- [x] validate 全绿（bash -n + shellcheck warning 级）
- [x] 本机 `install-user-tools.sh` 真跑：四件全 SKIP（钉子已就位，行为与收编前一致）
- [x] CI 冒烟双架构下载路径待 push 后由 fresh-container 实证（真实下载面在 CI 不在本机）

## 实录

收编后 install-user-tools.sh 301 → 223 行；mise 段保留 `mise_bin` 变量定义供 node@lts 段引用（收编首稿漏过一次，自查发现补上）。
