#!/usr/bin/env bash
# pre-spawn-gate-check.sh — Agent spawn 前检查 Gate 是否已通过
#
# 配置方式（添加到 .claude/settings.json）：
#
#   "hooks": {
#     "PreToolUse": [{
#       "matcher": "Agent",
#       "command": "bash harness/hooks/pre-spawn-gate-check.sh"
#     }]
#   }
#
# 两层验证：
#   1. PROGRESS.md 中上一个步骤完成后，紧接着的 Gate 行必须是 ✅
#   2. Gate 标记 ✅ 的同时，对应的 Gate Report 文件必须存在（物证）
#   只 ✅ 没有 Gate Report → 阻断
#   有 Gate Report 没 ✅ → 阻断
#   两者对齐 → 放行
#
# 这是整个 harness 里第二道"硬"约束（第一道是 pre-commit-ci.sh）。

set -euo pipefail

# 将 Gate 步骤名映射为 Gate 编号（如 "*关卡 #1*" → "1"、"*关卡 #2（CI）*" → "2"）
extract_gate_num() {
    local step="$1"
    # 用 sed 提取：匹配 "关卡" 后跟空格、#、然后是数字和点
    printf '%s' "$step" | sed -n 's/.*关卡[[:space:]]*#\([0-9.]*\).*/\1/p' 2>/dev/null
}

# Gate 编号 → Gate Report 文件路径（相对于 feature 目录）
gate_report_path() {
    local gate_num="$1"
    echo "reviews/gate-${gate_num}-report.md"
}

# 查找所有活跃功能的 PROGRESS.md
PROGRESS_FILES=$(find docs/harness -maxdepth 2 -name "PROGRESS.md" 2>/dev/null || true)

if [[ -z "$PROGRESS_FILES" ]]; then
    exit 0
fi

BLOCKED=false
BLOCK_REASON=""

for progress_file in $PROGRESS_FILES; do
    feature_dir=$(dirname "$progress_file")
    feature_name=$(basename "$feature_dir")

    # 提取 Markdown 表格行
    table=$(grep '^|' "$progress_file" 2>/dev/null || true)
    [[ -z "$table" ]] && continue

    # 扫描：跟踪最后一个 ✅（不管是不是 Gate），以及紧接着的待办行
    prev_step=""
    found_last_done=false
    pending_gate=""

    while IFS= read -r line; do
        [[ "$line" =~ 步骤.*Agent.*状态 ]] && continue
        [[ "$line" =~ "------" ]] && continue

        step=$(echo "$line" | awk -F'|' '{print $2}' | xargs 2>/dev/null || true)
        row_status=$(echo "$line" | awk -F'|' '{print $4}' | xargs 2>/dev/null || true)

        [[ -z "$step" ]] && continue

        if echo "$row_status" | grep -q '✅'; then
            prev_step="$step"
            found_last_done=true
            continue
        fi

        # 当前行未完成，上一行是 ✅ → 这就是"第一个待办"
        if $found_last_done; then
            if echo "$step" | grep -F '*关卡' >/dev/null 2>&1; then
                pending_gate="$step"   # Gate 未完成（❌/🟡）
            fi
            found_last_done=false
            break
        fi
    done <<< "$table"

    # --- 情况 1：有待办的 Gate 且未完成 → 阻断 ---
    if [[ -n "$pending_gate" ]]; then
        gate_label=$(echo "$pending_gate" | sed 's/\*//g' | xargs)
        BLOCKED=true
        BLOCK_REASON="功能 '${feature_name}'：'${prev_step}' 已完成，但 **${gate_label}** 尚未通过。
请先完成该 Gate 检查（见 harness/gates.md），在 PROGRESS.md 中将该 Gate 标记为 ✅ 后重试。"
        break
    fi

    # --- 情况 2：上一个完成的是 Gate 本身（已 ✅）→ 验证 Gate Report 物证 ---
    if echo "$prev_step" | grep -F '*关卡' >/dev/null 2>&1; then
        gate_num=$(extract_gate_num "$prev_step")
        report_rel=$(gate_report_path "$gate_num")
        report_abs="${feature_dir}/${report_rel}"

        if [[ ! -f "$report_abs" ]]; then
            gate_label=$(echo "$prev_step" | sed 's/\*//g' | xargs)
            BLOCKED=true
            BLOCK_REASON="功能 '${feature_name}'：${gate_label} 在 PROGRESS.md 中标记为 ✅，但 Gate Report 文件不存在（物证缺失）。
缺少文件：${report_rel}
请先完成 Gate 检查并产出 Gate Report（见 harness/gates.md），再更新 PROGRESS.md。"
            break
        fi
    fi
done

if $BLOCKED; then
    echo ""
    echo "============================================"
    echo "  ⛔ Agent spawn 被阻止 — Gate 未通过"
    echo "============================================"
    echo ""
    echo "$BLOCK_REASON"
    echo ""
    exit 1
fi

exit 0
