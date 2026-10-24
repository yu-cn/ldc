# Spec：零前置快速开始（get.sh 远程一键引导）

## 背景

README 快速开始原要求用户先手动装 git 与 curl（`sudo apt install -y git curl`）才能 clone 仓库。
在「用户自行获取仓库」这一步上它们不可替代；仓库就位后，root 阶段本来就会自装引导依赖
（WDC 委托路径的 setup-ubuntu.sh 先 `apt-get install git curl` 再 clone LDC，先例在案）。

## 决策（环境主人 2026-10-25 定夺：方案 A，与 WDC 侧同日对等）

消灭前置步骤本身：新增远程一键引导 `scripts/get.sh`：

- 缺 git/curl → apt 安装（root 直装或 sudo；需密码就地询问；无 sudo 报错并给手动命令）
- 仓库定位：`~/.ldc` 指针有效则复用（重跑 = 收敛语义）；缺省 clone 到 `~/ldc`
  （已存在非仓库目录不代删，对齐 setup-ubuntu.sh ensure_ldc 的「不代删」纪律）
- 转发 `bash bootstrap.sh`（root 交接 / 退出码 0/1/2 语义原样透传）

约束：`curl | bash` 属直接执行网络代码——README 给审阅链接；get.sh 写死上游地址，
fork 用户走手动 clone 两行（README 快速开始补 fork 说明）。

## 已评估并否决的替代

- **真 zip 模式**：仓库非 git 则首次 commit 护栏、ldc sync、写穿漂移断言、git describe
  全部失效，与「仓库是唯一主人」定位相抵（同 WDC 侧否决理由）。
- **纯文档改法**：零代码但手动前置步骤仍在。

WDC 侧同日对等实施 `scripts/get.ps1`（工单见 WDC 仓库 `.scratch/git-free-quickstart/`）。
