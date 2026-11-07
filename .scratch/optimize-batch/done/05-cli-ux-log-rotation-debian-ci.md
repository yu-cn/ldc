# 工单05：CLI 体验与测试面杂项

Status: done

## 背景

审查发现的五处小面：ldc status 的 fetch 无超时（坏网络挂起「秒级快照」）；ldc sync 的 fetch 静默失败可致「按陈旧 origin/main 误判一致」漏拉；get.sh 钉 tag 后的 detached HEAD 机器在 status 误报「落后 N」、sync 在 pull 上失败；logs/ 无限累积；CI 冒烟只有 ubuntu 无 debian 实证腿。

## 内容

- ldc status：fetch 带 5s 超时 + 禁交互，未达按缓存判读并 INFO 标注；detached HEAD 单列「钉版形态」INFO
- ldc sync：fetch 失败 FAIL 中止（不做盲同步）；detached HEAD 跳过仓库同步仅收敛机器；help 文案同步
- get.sh：复用路径显式传 tag 即升级重钉（fetch --tags + checkout；同 tag 重跑 no-op 幂等），不传保持收敛语义
- bootstrap.sh：logs/ 轮转保留最近 20 份
- fresh-container.yml：矩阵扩为双发行版 × 双架构（ubuntu:24.04 amd64/arm64 + debian:12 amd64），artifacts 名按矩阵 tag 区分

## 验收清单

- [x] validate 全绿（含 ldc 建议自测）
- [x] 本机 verify --quick / plan 全绿
- [x] get.sh bash -n / shellcheck 过（其运行路径不在本机复现——远程引导面由 CI clone 腿近似覆盖）
- [ ] debian:12 腿与双发行版冒烟待 push 后首跑实证

## 实录

- **symbolic-ref stdout 污染（实跑抓到）**：`git symbolic-ref -q HEAD` 的 `-q` 只压错误不压输出——成功时把 `refs/heads/main` 打进快照首行。修法 `>/dev/null`（status/sync 两处）。教训：探测类 git 子命令进报告面一律重定向 stdout。
- **detached 模拟方法**：`git clone` 只带已提交状态——测未提交的工作树改动须以工作树脚本 + 假 `HOME`（内放 `.ldc` 指针指向 detached clone）跑，首测用 clone 自身脚本测了个寂寞（跑的还是旧逻辑）。实测输出：`[INFO] 仓库 - 钉版形态（detached at v0.11.0）——升级重跑 get.sh 带新 tag`，不再误报落后。
- deb822 与 .list 双形态源均经 grep -r 判重（add_vendor_repo marker 机制本就覆盖），debian:12 腿无新增处置逻辑。
