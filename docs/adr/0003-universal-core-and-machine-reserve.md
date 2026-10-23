# 通用核心与机器自留地：`.bashrc.local` 机制

仓库只声明「每台 Ubuntu/Debian 开发机都需要」的配置（判据对齐 WDC ADR-0003：基础构建链、CLI 工具、语言管理器、git、dotfiles 模板）；机器私有内容不进仓库，受「清单外不碰」原则保护。

Linux 侧的独有难题是 `~/.bashrc`：它既有可模板化的通用段（别名、fzf、提示符），又几乎必然积累机器私有段（发行版预置块、厂商脚本块、nvm 等）。解法定为 **`.bashrc.local` 机器自留地**：

- bootstrap 首次接管 `~/.bashrc` 时整文件备份 `.bashrc.bak`，自动抽取全部标记块（`# >>> ... >>>` .. `# <<< ... <<<`）与 nvm 块迁入 `~/.bashrc.local`（已存在则不覆盖），其余差异留在 .bak 由机主自行搬运；
- 模板 bashrc **最末尾** source `.bashrc.local`——机器段后加载，别名/环境可覆盖模板（如本 DGX 的 `gs=nvidia-smi` 覆盖模板 `gs='git st'`，符合机主意图）；
- `.bashrc.local` 由机主维护、永不入仓库；新机器无标记块则创建带注释的空文件。

gitconfig 有同构问题（首个实例：`gh auth login`/`gh auth setup-git` 会把凭据助手写进全局 gitconfig——接管后即写穿符号链接污染模板，且 `/usr/bin/gh` 路径按机而异），解法同构：模板 `[include] path = ~/.gitconfig.local` 引用每机本地文件，bootstrap 首跑创建空自留地，写穿段经 triage 还原后迁入 local。

同一判据的首个落地案例是 **nvm/vp 共存**：按政策安装 vp 管理声明内的 Node，但不卸 nvm、不进任何移除清单——nvm 是机器自留地；本机 node 走 nvm shim（.local 后加载胜出），verify 只断言「node 可用」而不断言其归属。git 身份同理：因机而异属机器数据，模板经 `[include] path = ~/.gitidentity` 引用每机本地身份文件，bootstrap 首跑生成占位，不填则 git 拒绝提交（防错护栏，占位文件把 `name`/`email` 注释掉而非填假值，保证护栏真实生效）。拒绝的替代：模板吸收机器段（仓库被机器噪声污染）；按机器拆 profile / 内置 override 机制（为假想的共享需求做设计，YAGNI）；迁移时自动搬运全部旧内容（旧 bashrc 的通用段与模板重复，全搬则别名互相打架）。
