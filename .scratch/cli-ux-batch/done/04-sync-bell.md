# 工单04：ldc sync 完成 BEL 通知

Status: done

## 背景

ldc sync 带 sudo、全量分钟级——切走窗口不盯梢，结束无感知。wdc 侧同批同款（wdc 工单06）。

## 内容

- sync 收尾（快速路径 OK/FAIL、全量 verify 后）`printf '\a'`——终端原生提示（响铃/闪烁），零依赖
- 不加开关：BEL 噪声面可忽略；有抱怨再收（YAGNI）

## 验收清单

- [ ] 快速路径与全量两路收尾都响（真机终端）
- [ ] FAIL 路径也响（失败更需要注意力回收）
- [ ] validate 全绿

## 实录

- trap EXIT 方案：快速路径/全量/FAIL/PENDING 全部收尾路径覆盖；真机交互终端验收随下次真实 sync（机制面 printf \a 已验证输出 BEL 字节）
- validate 全绿（提交 2db3bfa）
