# 工单03：ldc log N 参数校验

Status: done

## 背景

`ldc log abc` 把 abc 直接喂给 tail 报 tail 的错误（口径泄露给底层工具）。wdc 侧 `-Lines`
是强类型无此问题。

## 内容

- log 分支参数模式校验：非空纯数字（`case $1 in ''|*[!0-9]*)`）→ 报 `ldc: log 参数须为行数（正整数）`，exit 1

## 验收清单

- [ ] `ldc log abc` / `ldc log -5` → ldc 口径报错 exit 1
- [ ] `ldc log` / `ldc log 5` 行为不变
- [ ] validate 全绿

## 实录

- 烟测：`ldc log abc` → ldc 口径报错 exit 1；`ldc log`/`ldc log 5` 不变；validate 全绿（提交 2db3bfa）
