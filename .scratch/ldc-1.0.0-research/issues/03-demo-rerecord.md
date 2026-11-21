# 03 demo 重录——三段 `ldc` / `ldc plan` / `ldc exit` 预演

Status: ready-for-agent
Type: task

## 定夺

grilling R1 Q5c + R2 Q3：重录，三段对齐 WDC 终版叙事（快照 / plan / exit 预演），verify 段出镜让位——断言已有 CI badge 与 README 边界段背书，exit 上 demo 才是 1.0.0 完整退出承诺面的宣告。

## 内容

1. `docs/demo.cast` 重录：三段 `ldc`（快照）/ `ldc plan`（干跑预演）/ `ldc exit`（预演口径——非 tty 自动降级预演，零变更安全，录制环境天然落在预演档）
2. agg 转 `docs/demo.gif`（README 嵌播位 caption 同步三段口径）
3. 帧级自检：中文清晰、无腰斩、提示符与配色观感与现版一致（对齐 WDC f53fe1f 终版的验证纪律）

## 验收

- [x] demo.cast / demo.gif 落地，README caption 与三段实际内容一致
- [x] 预演段确认零变更（录制后 `bash scripts/verify-machine.sh --quick` 仍全绿）

## Comments

- 2026-11-22 开票（grilling 收口批）；同日实施收口（待 commit）。上一版 9124d93（2026-11-01，vp→mise 换轨后三段 `ldc`/`ldc plan`/`ldc verify --quick`）。
- 生成配方沿现版：真实命令输出脱敏生成（prompt 固定 `demo@ldc:~$`、`/home/ubuntu`→`/home/demo`、仓库行归一全绿口径、组名脱敏）；逐字打字 50ms/字符，agg v1.9.0 转 GIF。
- 节奏修订一版：首版 exit 预演输出挤在末 0.3s 一闪而过（帧检抓出）——exit 段行流出降速 0.05s/行 + 片尾驻留 1.6s（GIF 循环前读屏时间）；终版 96 帧 / 7.21s / 1.4MB。
- 帧级自检（ffmpeg 抽帧 + 视觉判读）：status 段与 exit 驻留帧两检全过——中文清晰、长行自然换行无截断、提示符/排版正常；状态标签单色与现版观感一致（管线捕获无 ANSI，现版 cast 同款）。
- 录制环境实录：`ldc exit` 走非 tty 自动降级预演（ADR-0024 口径），exit 0 零变更；录后 verify --quick 全绿实证。
