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
for v in mise-version uv-version lazygit-version nerd-fonts-version; do
    val=$(head -n1 "$ROOT/configs/$v" | tr -d '[:space:]')
    if [[ $val =~ ^[A-Za-z0-9][A-Za-z0-9.]*$ ]]; then
        # ADR-0011：sha256 行（若有）格式——`sha256 <hex>` 或 `sha256 amd64|arm64 <hex>`
        bad=$(grep -vE '^[[:space:]]*(#|$)|^[A-Za-z0-9][A-Za-z0-9.]*[[:space:]]*$|^sha256( (amd64|arm64))? [0-9a-f]{64}[[:space:]]*$' "$ROOT/configs/$v" || true)
        if [ -z "$bad" ]; then
            step "configs/$v" OK "$val"
        else
            step "configs/$v" FAIL "sha256 行应为 sha256 [amd64|arm64] <64位hex>：$(printf '%s' "$bad" | head -n 1)"
            fail=$((fail + 1))
        fi
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
version_matches 'mise 2026.10.25 (commit abc)' '2026.10.25' || vm_ok=0
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
# docker daemon 声明文件与合并语义：依赖 jq（base-linux 包，root 阶段安装）——
# validate 可能跑在裸机（bootstrap 第 2 阶段先于 root），未装时降级放行（CI root 腿兜底）
if ! have jq; then
    step 'daemon 声明与合并自测' SKIP 'jq 未装（root 阶段后自动启用；CI 兜底）'
else
    if jq empty "$ROOT/configs/docker-daemon.json" >/dev/null 2>&1; then
        step 'configs/docker-daemon.json' OK '合法 JSON'
    else
        step 'configs/docker-daemon.json' FAIL '非法 JSON'
        fail=$((fail + 1))
    fi
    # 受保护合并语义自测：声明叶键胜出（max-file 覆盖）、机器自有键保留（mirrors/labels）
    dj_ex='{"registry-mirrors":["https://m.example"],"log-opts":{"max-file":"5","labels":"x"}}'
    dj_dec='{"log-driver":"json-file","log-opts":{"max-size":"50m","max-file":"3"},"live-restore":true}'
    dj_want='{"registry-mirrors":["https://m.example"],"log-driver":"json-file","log-opts":{"max-size":"50m","max-file":"3","labels":"x"},"live-restore":true}'
    if [ "$(jq -n -cS --argjson a "$dj_ex" --argjson b "$dj_dec" '$a * $b')" = "$(printf '%s' "$dj_want" | jq -cS .)" ]; then
        step 'daemon 合并自测（受保护合并）' OK '声明叶胜出 · 机器键保留'
    else
        step 'daemon 合并自测（受保护合并）' FAIL '合并语义不符预期'
        fail=$((fail + 1))
    fi
fi
# ADR-0015 渲染模型自测：dotfiles_entry_state 状态判定（render ok/absent/drift/残形 · link ok/drift）
ds_ok=1
ds_dir=$(mktemp -d)
printf 'a\n' > "$ds_dir/t"
printf 'a\n' > "$ds_dir/same"
printf 'b\n' > "$ds_dir/diff"
[ "$(dotfiles_entry_state "$ds_dir/t" "$ds_dir/same" render)" = ok ] || ds_ok=0
[ "$(dotfiles_entry_state "$ds_dir/t" "$ds_dir/diff" render)" = drift ] || ds_ok=0
[ "$(dotfiles_entry_state "$ds_dir/t" "$ds_dir/none" render)" = absent ] || ds_ok=0
ln -s "$ds_dir/t" "$ds_dir/lnk"
[ "$(dotfiles_entry_state "$ds_dir/t" "$ds_dir/lnk" render)" = drift ] || ds_ok=0   # 渲染模型不容符号链接残形
[ "$(dotfiles_entry_state "$ds_dir/t" "$ds_dir/lnk" link)" = ok ] || ds_ok=0
ln -sf /nonexistent "$ds_dir/lnk2"
[ "$(dotfiles_entry_state "$ds_dir/t" "$ds_dir/lnk2" link)" = drift ] || ds_ok=0
printf 'c\n' > "$ds_dir/reg"
[ "$(dotfiles_entry_state "$ds_dir/t" "$ds_dir/reg" link)" = drift ] || ds_ok=0
rm -rf "$ds_dir"
if [ "$ds_ok" -eq 1 ]; then
    step '落点状态自测（dotfiles_entry_state）' OK 'render ok/absent/drift/残形 · link ok/drift'
else
    step '落点状态自测（dotfiles_entry_state）' FAIL '状态判定不符预期'
    fail=$((fail + 1))
fi
# 渲染账本与方向判定自测（ADR-0015 补注）：set/get 往返、单行覆写、多条目共存、四方向分类——
# 在 HOME 隔离的子壳里跑（账本路径随 $HOME 展开），不影响真实账本
rs_home=$(mktemp -d)
rs_verdict=$(
    HOME="$rs_home"
    unset XDG_STATE_HOME
    ok=1
    t="$HOME/t"; x="$HOME/x"
    printf 'v1\n' > "$t"
    render_state_set "$t" "$(content_hash "$t")"
    [ "$(render_state_get "$t")" = "$(content_hash "$t")" ] || ok=0
    printf 'x\n' > "$x"
    render_state_set "$x" "$(content_hash "$x")"                      # 多条目共存
    printf 'v2\n' > "$t"
    render_state_set "$t" "$(content_hash "$t")"                      # 单行覆写
    [ "$(render_state_get "$x")" = "$(content_hash "$x")" ] || ok=0
    [ "$(render_state_get "$t")" = "$(content_hash "$t")" ] || ok=0
    tt="$HOME/tt"; xx="$HOME/xx"
    printf 'base\n' > "$tt"; printf 'base\n' > "$xx"
    render_state_set "$xx" "$(content_hash "$xx")"                    # R = hash(base)
    printf 'new\n' > "$tt"
    [ "$(drift_direction "$tt" "$xx")" = template-update ] || ok=0    # 落点未动 → 模板更新
    printf 'base\n' > "$tt"; printf 'hack\n' > "$xx"
    [ "$(drift_direction "$tt" "$xx")" = machine ] || ok=0            # 模板未动 → 机器侧改动
    printf 'newer\n' > "$tt"
    [ "$(drift_direction "$tt" "$xx")" = both ] || ok=0               # 双方都动 → 双向
    printf 'ghost\n' > "$HOME/gy"
    [ "$(drift_direction "$tt" "$HOME/gy")" = unknown ] || ok=0       # 无记录 → unknown
    [ "$ok" -eq 1 ] && echo PASS || echo FAIL
)
rm -rf "$rs_home"
if [ "$rs_verdict" = PASS ]; then
    step '渲染账本自测（render_state/drift_direction）' OK 'set/get 往返 · 覆写共存 · 四方向分类'
else
    step '渲染账本自测（render_state/drift_direction）' FAIL '账本或方向判定不符预期'
    fail=$((fail + 1))
fi
# 落点映射自测：dotfiles_map 引用的每个模板必须真实存在（防映射与仓库漂移）
map_bad=''
while IFS='|' read -r _name tmpl _target _gate _mode; do
    [ -f "$ROOT/$tmpl" ] || map_bad+=" $tmpl"
done < <(dotfiles_map)
if [ -z "$map_bad" ]; then
    step '落点映射自测（dotfiles_map）' OK '全部模板在位'
else
    step '落点映射自测（dotfiles_map）' FAIL "模板缺失：$map_bad"
    fail=$((fail + 1))
fi
# bashrc 事实外置契约自测（ADR-0015）：模板只经 env.sh 取工具布局事实——不得再硬编码
# vp env 候选路径（vp 已退役，防回潮）/ fzf 示例路径（上游换布局只改安装器，改回来即违约）
br_ok=1
grep -q '.config/ldc/env.sh' "$ROOT/dotfiles/linux/bashrc" || br_ok=0
grep -q 'vite-plus/env' "$ROOT/dotfiles/linux/bashrc" && br_ok=0
grep -q 'doc/fzf/examples' "$ROOT/dotfiles/linux/bashrc" && br_ok=0
if [ "$br_ok" -eq 1 ]; then
    step 'bashrc 事实外置契约自测（ADR-0015）' OK '仅 source env.sh，无硬编码工具路径'
else
    step 'bashrc 事实外置契约自测（ADR-0015）' FAIL '模板又硬编码了工具布局路径（应走 env.sh 事实文件）'
    fail=$((fail + 1))
fi
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
