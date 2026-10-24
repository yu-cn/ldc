#!/usr/bin/env bash
# validate.sh — 无副作用校验入口（独立可用，不需要 root）：
#   1. bash -n 全部脚本     2. shellcheck（已装则硬把关；未装警告放行——CI 兜底）
#   3. 清单格式检查（.pkg / .gsettings / 版本钉子 / dotfiles 模板在位）
# pre-commit 钩子与 CI validate.yml 跑的也是本脚本（校验口径单一来源）
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
. "$ROOT/scripts/lib/common.sh"
fail=0

# 受检脚本面：三个根入口 + scripts/ 递归 + 钩子（pre-commit 为 POSIX sh，bash -n 可解析其子集）
sh_files=("$ROOT/bootstrap.sh" "$ROOT/validate.sh" "$ROOT/ldc" "$ROOT/.githooks/pre-commit")
while IFS= read -r f; do
    sh_files+=("$f")
done < <(find "$ROOT/scripts" -type f -name '*.sh' | sort)

phase 'Validate 1/3 · bash 语法检查（bash -n）'
for f in "${sh_files[@]}"; do
    rel=${f#"$ROOT"/}
    if bash -n "$f" 2>/dev/null; then
        step "$rel" OK
    else
        step "$rel" FAIL "$(bash -n "$f" 2>&1 | head -n 1)"
        fail=$((fail + 1))
    fi
done

phase 'Validate 2/3 · shellcheck'
if have shellcheck; then
    for f in "${sh_files[@]}"; do
        rel=${f#"$ROOT"/}
        out=$(shellcheck --severity=warning "$f" 2>&1)
        if [ $? -eq 0 ]; then
            step "$rel" OK
        else
            step "$rel" FAIL "$(printf '%s\n' "$out" | grep -E 'In .* line' | head -n 3 | tr '\n' ' ')"
            fail=$((fail + 1))
        fi
    done
else
    step shellcheck SKIP '未安装——本机警告放行（root 阶段 cli-tools.pkg 装上后自动把关；CI 必查兜底）'
fi

phase 'Validate 3/3 · 清单格式与关键机制自测'
for m in "$ROOT"/configs/*.pkg; do
    rel=${m#"$ROOT"/}
    bad=$(grep -vE '^[[:space:]]*(#|$)' "$m" | grep -vE '^[a-z0-9][a-z0-9+.-]*$' || true)
    if [ -z "$bad" ]; then
        step "$rel" OK
    else
        step "$rel" FAIL "非包名行：$(printf '%s' "$bad" | head -n 1)"
        fail=$((fail + 1))
    fi
done
for m in "$ROOT"/configs/*.gsettings; do
    rel=${m#"$ROOT"/}
    bad=$(grep -vE '^[[:space:]]*(#|$)' "$m" \
          | grep -vE "^[a-zA-Z0-9.-]+[[:space:]]+[a-zA-Z0-9._-]+[[:space:]]+('[^']*'|true|false|\[[^]]*\])[[:space:]]*$" || true)
    if [ -z "$bad" ]; then
        step "$rel" OK
    else
        step "$rel" FAIL "格式应为 schema key value（value 为引号串/布尔/列表）：$(printf '%s' "$bad" | head -n 1)"
        fail=$((fail + 1))
    fi
done
ext_bad=$(grep -vE '^[[:space:]]*(#|$)' "$ROOT/configs/vscode-extensions.txt" \
          | grep -vE '^[A-Za-z0-9][A-Za-z0-9._-]*\.[A-Za-z0-9._-]+$' || true)
if [ -z "$ext_bad" ]; then
    step 'configs/vscode-extensions.txt' OK
else
    step 'configs/vscode-extensions.txt' FAIL "应为 publisher.name 格式：$(printf '%s' "$ext_bad" | head -n 1)"
    fail=$((fail + 1))
fi
for v in vp-version lazygit-version nerd-fonts-version; do
    val=$(head -n1 "$ROOT/configs/$v" | tr -d '[:space:]')
    if [[ $val =~ ^[A-Za-z0-9][A-Za-z0-9.]*$ ]]; then
        step "configs/$v" OK "$val"
    else
        step "configs/$v" FAIL '应为非空单行版本号'
        fail=$((fail + 1))
    fi
done
for f in dotfiles/linux/bashrc dotfiles/linux/gitconfig dotfiles/shared/starship.toml \
         dotfiles/linux/vscode-settings.json dotfiles/linux/vscode-keybindings.json; do
    if [ -f "$ROOT/$f" ]; then
        step "$f" OK
    else
        step "$f" FAIL '模板缺失'
        fail=$((fail + 1))
    fi
done
# 关键机制自测（离线单测；CI 冒烟补真实下载面，这里补逻辑面）
arch_ok=1
[ "$(ldc_arch x86_64)" = amd64 ] || arch_ok=0
[ "$(ldc_arch aarch64)" = arm64 ] || arch_ok=0
[ "$(ldc_arch arm64)" = arm64 ] || arch_ok=0
if ldc_arch riscv64 >/dev/null 2>&1; then arch_ok=0; fi
if [ "$arch_ok" -eq 1 ]; then
    step '架构映射自测（ldc_arch）' OK 'x86_64→amd64 · aarch64/arm64→arm64 · 其余拒绝'
else
    step '架构映射自测（ldc_arch）' FAIL '映射不符预期'
    fail=$((fail + 1))
fi
# version_matches 边界：钉子不得误配更长数字段（1.3.0 ≠ 11.3.0）
vm_ok=1
version_matches 'vp 1.3.0 (commit abc)' '1.3.0' || vm_ok=0
version_matches 'lazygit version=0.66.2, d1a2b3' '0.66.2' || vm_ok=0
if version_matches 'uv 11.3.0' '1.3.0'; then vm_ok=0; fi
if version_matches 'starship 1.27.10' '1.27.0'; then vm_ok=0; fi
if [ "$vm_ok" -eq 1 ]; then
    step '版本匹配自测（version_matches）' OK '命中两例 · 拒绝误配两例'
else
    step '版本匹配自测（version_matches）' FAIL '边界行为不符预期'
    fail=$((fail + 1))
fi
# .bashrc.local 迁移抽取自测：标记块 + nvm 三行块，段间空行（ADR-0003 核心机制）
fx=$(mktemp)
cat > "$fx" <<'FXEOF'
# 原生段（不迁移）
export A=1
# >>> block one >>>
inner1
# <<< block one <<<
export B=2
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export C=3
FXEOF
fx_expect='# >>> block one >>>
inner1
# <<< block one <<<

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"'
if [ "$(bashrc_local_extract "$fx")" = "$fx_expect" ]; then
    step '迁移抽取自测（bashrc_local_extract）' OK '标记块 + nvm 块、段间空行'
else
    step '迁移抽取自测（bashrc_local_extract）' FAIL '抽取结果与预期不符'
    fail=$((fail + 1))
fi
rm -f "$fx"
# ldc 错命令建议（集成）：建议逻辑在仓库定位之前，无需 ~/.ldc 指针
bad_out=$(bash "$ROOT/ldc" syncz 2>&1)
bad_rc=$?
if [ "$bad_rc" -eq 1 ] && printf '%s' "$bad_out" | grep -q '你是想输「sync」吗'; then
    step 'CLI 建议自测（ldc 错命令）' OK 'syncz → sync，退出码 1'
else
    step 'CLI 建议自测（ldc 错命令）' FAIL '建议或退出码不符预期'
    fail=$((fail + 1))
fi

phase 'Validate 汇总'
if [ "$fail" -eq 0 ]; then
    step '无副作用校验' OK '全部通过'
    exit 0
fi
step '无副作用校验' FAIL "$fail 项未通过"
exit 1
