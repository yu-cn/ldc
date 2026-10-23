#!/usr/bin/env bash
# shellcheck disable=SC2088  # 标签文案中的 ~/ 是显示约定不参与展开；真实路径展开一律用 $HOME
# bootstrap.sh — LDC 开发环境唯一入口（GLOSSARY: bootstrap）
# 阶段：预检 → 无副作用校验 → root 阶段(或交接) → user 工具 → 桌面 → dotfiles → 汇总
# 退出码：0 = 全部就绪；1 = 有 FAIL；2 = 有待办手工步骤（root 交接 / 身份未填 / 桌面待登录重跑）
# 环境：LDC_SKIP_DOCKER=1 跳过 docker 域（CI 冒烟）；全程日志 tee 到 logs/bootstrap-<时间戳>.log
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"

main() {
    local pending=0 fails=0 handoff="" desktop_pending=0

    phase '1/7 · 预检'
    if [ ! -r /etc/os-release ]; then
        step '操作系统' FAIL '缺 /etc/os-release（非 Ubuntu/Debian？）'
        return 1
    fi
    # shellcheck disable=SC1091
    . /etc/os-release   # 提供 ID / PRETTY_NAME
    case "${ID:-}" in
        ubuntu|debian) step '操作系统' OK "$PRETTY_NAME（$(uname -m)）" ;;
        *)             step '操作系统' FAIL "仅支持 ubuntu/debian，当前 ID=${ID:-未知}"; return 1 ;;
    esac
    # 架构门禁（ADR-0006）：双架构一等公民，其余架构在预检即失败——而不是等到 lazygit 下载中途炸
    if arch_asset=$(ldc_arch); then
        step '架构' OK "$(uname -m) → ${arch_asset} 资产"
    else
        step '架构' FAIL '受支持架构仅 amd64/arm64（ADR-0006）'
        return 1
    fi
    if ! have curl; then
        step curl FAIL '前置依赖缺失：先 apt 装 curl 再跑 bootstrap'
        return 1
    fi
    step curl OK
    if [ "${BASH_VERSINFO[0]:-0}" -lt 4 ]; then
        step 'bash ≥ 4' FAIL "当前 ${BASH_VERSION}"
        return 1
    fi
    step 'bash ≥ 4' OK "${BASH_VERSION%(*}"

    phase '2/7 · 无副作用校验'
    if ! bash "$ROOT/validate.sh"; then
        step '校验' FAIL 'validate.sh 未通过——修复后重跑'
        return 1
    fi

    phase '3/7 · root 阶段（ADR-0004 sudo 交接）'
    case "$(sudo_probe)" in
        root)
            # 容器/已提权上下文：直接内联执行（CI fresh-container 冒烟路径）
            run_stage 'root 阶段（内联）' "$ROOT/scripts/install-packages.sh" || fails=$((fails + 1))
            ;;
        nopasswd)
            step 'sudo 形态' INFO '免密 sudo——自动执行 root 阶段'
            sudo --preserve-env=LDC_SKIP_DOCKER bash "$ROOT/scripts/install-packages.sh" \
                || fails=$((fails + 1))
            ;;
        interactive)
            # 需密码形态先核销：交接命令已手动跑过（包清单完整）则视为完成，不再重复打扰
            if root_stage_complete; then
                step 'root 阶段' OK '已核销（包清单完整——交接命令此前已执行）'
            else
                handoff=$(root_handoff_cmd)
                step 'root 阶段' PENDING 'sudo 需密码（无法交互输入）——见末尾交接命令'
                pending=$((pending + 1))
            fi
            ;;
        none)
            step 'root 阶段' FAIL '无 sudo 且非 root——无法执行 root 阶段'
            fails=$((fails + 1))
            ;;
    esac

    phase '4/7 · user 工具（uv / vp / starship / lazygit / 字体）'
    run_stage 'user 工具' "$ROOT/scripts/install-user-tools.sh" || fails=$((fails + 1))

    phase '5/7 · 桌面域（gsettings）'
    rc=0
    bash "$ROOT/scripts/apply-desktop.sh" || rc=$?
    case $rc in
        0) : ;;
        2) desktop_pending=1; pending=$((pending + 1)) ;;   # 无会话 SKIP——待办：登录桌面后重跑
        *) step '桌面域' FAIL "退出码 $rc"; fails=$((fails + 1)) ;;
    esac

    phase '6/7 · dotfiles（符号链接 + .bashrc.local + 身份占位）'
    run_stage 'dotfiles' "$ROOT/scripts/install-dotfiles.sh" || fails=$((fails + 1))

    phase '7/7 · 汇总'
    # 身份占位是待办（手工步骤）：不填 git 拒绝提交（护栏），不阻断 bootstrap
    if git_identity_ok; then
        step 'git 身份' OK '已生效'
    else
        step 'git 身份' PENDING '~/.gitidentity 未填（占位已生成）'
        pending=$((pending + 1))
    fi

    # 判定行：step 输出的 [OK|FAIL|PENDING] bootstrap 行即 ldc status 的抓取目标
    if [ "$fails" -gt 0 ]; then
        step 'bootstrap' FAIL "$fails 项失败——见上方各阶段明细（重跑幂等）"
        return 1
    fi
    if [ "$pending" -gt 0 ]; then
        step 'bootstrap' PENDING "$pending 项待办手工步骤（见下）"
        echo
        if [ -n "$handoff" ]; then
            echo '━━ root 阶段交接（sudo 需密码，请手动执行）━━'
            printf '    %s\n' "$handoff"
            echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        fi
        echo '── 待办手工步骤 ──'
        [ -n "$handoff" ] && printf '  · root 阶段：%s\n' "$handoff"
        [ "$desktop_pending" -eq 1 ] && echo '  · 桌面域：登录 GNOME 桌面会话后重跑 bash bootstrap.sh（应用 gsettings）'
        git_identity_ok || echo '  · git 身份：编辑 ~/.gitidentity 填本机 name/email，然后 git add -A && git commit -m "Initial LDC scaffold"'
        return 2
    fi
    step 'bootstrap' OK '全部阶段完成——机器与声明一致'
    return 0
}

mkdir -p "$ROOT/logs"
LOG="$ROOT/logs/bootstrap-$(date +%Y%m%d-%H%M%S).log"
main "$@" 2>&1 | tee "$LOG"
exit "${PIPESTATUS[0]}"
