# 工单02：子命令 + -h/--help 落单命令详解

Status: done

## 背景

`ldc verify -h` 的 `-h` 被静默吞（verify 分支不消费 "$@"，直接跑 verify-machine.sh）；
`ldc sync --help` 同理报「不认得参数」。应为「子命令 + -h/--help = 该命令详解」。
wdc 侧同语义联动（wdc 工单04）。

## 内容

- help 印刷（现 case 内联的 topic 分支）重构为 `print_topic_help()` 函数——单一印刷源，
  `ldc help <topic>` 与新拦截共用
- 子命令校验后、仓库定位前加拦截：`cmd` 是实体子命令（非 help/version）且 `$1` 为
  `-h|--help` → `print_topic_help "$cmd"; exit 0`——与 help/version 一样不依赖 ~/.ldc 指针

## 验收清单

- [ ] `ldc verify -h` / `ldc sync --help` 出对应详解
- [ ] `ldc help verify` 行为不变；`ldc -h` 总览不变
- [ ] 无指针环境下子命令 -h 仍可用（不依赖 ~/.ldc）
- [ ] validate 全绿

## 实录

- 烟测：`ldc verify -h` / `ldc log -h` 出对应详解；`ldc help verify` / `ldc -h` 行为不变；print_topic_help 单一印刷源重构后 help 总览含退出码行
- validate 全绿（提交 2db3bfa）
