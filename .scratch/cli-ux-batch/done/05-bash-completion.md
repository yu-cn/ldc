# 工单05：ldc Tab 补全（bashrc 注册，子命令表单一来源解析）

Status: done

## 背景

无补全注册（bashrc 只加载了系统 bash-completion 与 uv 的补全）。Tab 对 `ldc ` 只做文件名补全。
子命令表在 ldc 脚本 `LDC_COMMANDS` 有单一来源——注册从那里取，绝不在 bashrc 抄列表。

## 内容

- dotfiles/linux/bashrc 补全节加 `_ldc_completions`：`readlink -f ~/.local/bin/ldc` 解析
  脚本真身 → sed 提取 `LDC_COMMANDS='…'` 行 → `compgen -W` 过滤；`complete -F _ldc_completions ldc`
- 解析失败（链接缺失/格式漂移）静默返回空，不干扰补全框架
- 渲染拷贝模型：改模板须 bootstrap 重渲染落点才生效——票内注明收口后重渲染验证
  （本机 ~/.bashrc 是落点渲染物）

## 验收清单

- [ ] `ldc <Tab>` 出全部子命令、`ldc sy<Tab>` 前缀过滤（重渲染后真机）
- [ ] 零硬编码列表（临时改 LDC_COMMANDS 词表，补全跟随）
- [ ] validate 全绿

## 实录

- 模板 bashrc 直载冒烟：`ldc sy<Tab>` → sync；`ldc <Tab>` → 全部 9 词；零硬编码（词表 sed 解析自 LDC_COMMANDS）
- 落点重渲染：随下次 ldc sync/bootstrap 生效（渲染拷贝模型，ADR-0015）；validate 全绿（提交 2db3bfa）
