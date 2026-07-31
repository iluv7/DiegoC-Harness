#!/usr/bin/env bash
# pre-spawn-gate-check.sh — Agent spawn 前检查 Gate Report 物证
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
# 规则（一条）：
#   查 PROGRESS.md 表格，找到最后一个 ✅ 的步骤。
#   如果该步骤是 Gate → 对应的 Gate Report 文件必须存在。
#   存在则放行，不存在则阻断。
#   如果最后 ✅ 不是 Gate → 放行（Lead 正在做 Gate 或下一步）。
#
# 这不做流程顺序检查（Lead 是否跳过了 Gate），那由 Lead prompt + HITL 负责。

set -euo pipefail

# 将 Gate 步骤名映射为 Gate 编号（如 "*关卡 #1*" → "1"）
extract_gate_num() {
    local step="$1"
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

    # 找最后一个 ✅ 的步骤
    last_done_step=""

    while IFS= read -r line; do
        [[ "$line" =~ 步骤.*Agent.*状态 ]] && continue
        [[ "$line" =~ "------" ]] && continue

        step=$(echo "$line" | awk -F'|' '{print $2}' | xargs 2>/dev/null || true)
        row_status=$(echo "$line" | awk -F'|' '{print $4}' | xargs 2>/dev/null || true)

        [[ -z "$step" ]] && continue

        if echo "$row_status" | grep -q '✅'; then
            last_done_step="$step"
        fi
    done <<< "$table"

    # 规则：最后 ✅ 是 Gate → 必须有 Gate Report
    if [[ -n "$last_done_step" ]] && echo "$last_done_step" | grep -F '*关卡' >/dev/null 2>&1; then
        gate_num=$(extract_gate_num "$last_done_step")
        report_rel=$(gate_report_path "$gate_num")
        report_abs="${feature_dir}/${report_rel}"

        if [[ ! -f "$report_abs" ]]; then
            gate_label=$(echo "$last_done_step" | sed 's/\*//g' | xargs)
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
    echo "  ⛔ Agent spawn 被阻止 — Gate Report 缺失"
    echo "============================================"
    echo ""
    echo "$BLOCK_REASON"
    echo ""
    exit 1
fi

exit 0
