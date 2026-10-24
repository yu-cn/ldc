# 工单 05 — 一致性欠账清理 + 验证面补强

## 背景

v0.1.0 后的优化盘点（P1/P2 打包）：三项一致性欠账 + 三项有实证价值的能力补强。

## 内容

- **P1-1 钉子语义补齐**：starship 加 `configs/starship-version`（钉 1.27.0）+ 版本漂移收敛（GitHub 资产下载，rust 命名例外：amd64→x86_64-unknown-linux-gnu、arm64→aarch64-unknown-linux-musl）；字体加版本戳记 `.ldc-version`（钉子升级即重装，存量机器首次重跑重下一次）
- **P1-2 文档措辞修正**：AGENTS 红线 2 去掉「移除清单」引用（LDC 是只装不删语义，WDC 的 remove-leftovers 不搬）；红线 1 / GLOSSARY 钉子清单补 starship
- **P1-3 HANDOFF.md 退役**：v1 已收官（verify 全绿 + v0.1.0 发布），删除；spec.md 引用改指 docs/adr/
- **P2-4 dotfiles 漂移开终端提示**：bashrc 模板新增段——`~/.ldc` 指向的仓库有 HEAD 且 dotfiles 漂移>0 时黄字一行（`--no-optional-locks` 防抢锁；WDC 工单24 的 Linux 同款）
- **P2-5 validate 关键机制自测扩充**：version_matches 边界（拒 11.3.0/1.27.10 误配）、bashrc_local_extract 抽取（迁入 common.sh 单一来源 + fixture 单测）、ldc 错命令建议（集成，无需 ~/.ldc）
- **P2-6 CI 交接路径腿**：fresh-container 新增 handoff job——非 root 用户 + 需密码 sudo → 断言 bootstrap exit 2 + 交接命令输出（ADR-0004 首次 CI 实证）

## 验收

- [ ] validate 全绿（含四组自测）
- [ ] 本机 bootstrap：starship = 钉子 SKIP、字体首次补戳记重下、漂移提示静默（无漂移时零输出）
- [ ] 漂移提示正例实测：临时改 dotfiles 模板 → 新开 shell 出黄字 → 还原后消失
- [ ] CI：validate 绿 + handoff 腿 exit 2 断言过 + 双架构冒烟不受影响

## 实录（2026-10-24）

- [x] validate 全绿，四组机制自测齐（架构映射 / 版本匹配边界 / 迁移抽取 fixture / CLI 错命令建议）
- [x] 本机 bootstrap exit 0：starship SKIP=钉子 1.27.0（本机恰为最新）；字体首次补戳记重下（stamp=3.5.1，此后钉子不变即 SKIP）
- [x] 漂移提示正反例实测：临时写穿 bashrc 模板 → 新开 shell 黄字「dotfiles 漂移 1 项」→ 还原后静默；另实测中「无漂移」对照出现的提示实为真阳性（自身未提交的模板改动被抓到），机制无误
- [x] CI（run 40055310121）三腿全绿：**handoff: success**（非 root + 需密码 sudo → 断言 exit 2 + 交接命令，ADR-0004 首次 CI 实证）+ 双架构冒烟不受影响
- starship 资产命名第三种约定入档：amd64→x86_64-unknown-linux-gnu、arm64→aarch64-unknown-linux-musl（aarch64 只发 musl 静态包，glibc 直接可用）
- HANDOFF.md 已删（历史在首提）；AGENTS/GLOSSARY 钉子与移除清单措辞已修正
