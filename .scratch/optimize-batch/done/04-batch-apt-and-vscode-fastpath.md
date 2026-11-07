# 工单04：包安装合批 + VSCode 扩展 fast-path

Status: done

## 背景

pkg_install 原逐包 `apt-get install`——新机收敛 ~20 次独立事务（红线 11 说的是不重写 apt 能力，合批恰是**用** apt 的事务能力）。VSCode 扩展原每次收敛对全部 30 件逐个 `--install-extension`，已装件也走一遍 marketplace 往返。

## 内容

- pkg_install：已装件逐包报 SKIP 不变；缺失件合并单次 `apt-get install`；整批失败退回逐包定位元凶（部分成功件按已装报）；返回值由「任一失败 1」改为「失败件数」（调用方 fail 计数粒度不降）
- install-packages.sh 三处调用（核心清单 / 可选包组 / 桌面应用）换 mapfile 整批传入
- VSCode 扩展：先 `code --list-extensions` 差集（与 verify/plan 的 comm 口径同源）只装缺失件

## 验收清单

- [x] validate 全绿（shellcheck warning 级）
- [x] 幂等语义不破：本机重跑全部 SKIP、零 CHANGED（CI 二遍幂等关卡同口径）
- [x] WDC 委托契约不动（install-packages.sh 入口参数 / 退出码 / 独立可跑不变）

## 实录

无事故。注意点：空清单防御（`[ "${#pkgs[@]}" -gt 0 ]`）留给可选组——理论上 .pkg 可只有注释。
