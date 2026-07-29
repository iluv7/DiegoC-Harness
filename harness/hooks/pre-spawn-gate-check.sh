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
#   1. PROGRESS.md 中上一个步骤完成后，紧接着的 Gate 行必须是 ✅（或 🟡 执行中）
#   2. Gate 标记 ✅ 的同时，对应的 Gate Report 文件必须存在（物证）
#   只 ✅ 没有 Gate Report → 阻断
#   有 Gate Report 没 ✅ → 阻断
#   两者对齐 → 放行
#
# 🟡（进行中）不阻断：Lead 在 spawn Gatekeeper 前先标记 🟡，Hook 放行。
# ❌ 或没有状态 → 阻断：有人试图跳过 Gate 直接进下一步。
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

# 读取项目 config.md 中的 hitl_enabled 值
# 参数: feature_dir (如 docs/harness/my-feature)
# 返回: "true" 或 "false"（默认 false）
is_hitl_enabled() {
    local feature_dir="$1"
    local project_root
    project_root=$(cd "$feature_dir/../.." 2>/dev/null && pwd || true)
    local config_file="${project_root}/harness/config.md"
    if [[ -f "$config_file" ]]; then
        local val
        val=$(grep -oP 'hitl_enabled.*?`\K(true|false)' "$config_file" 2>/dev/null | head -1 || true)
        if [[ "$val" == "true" ]]; then
            echo "true"
            return
        fi
    fi
    echo "false"
}

BLOCKED=false
BLOCK_REASON=""

for progress_file in $PROGRESS_FILES; do
    feature_dir=$(dirname "$progress_file")
    feature_name=$(basename "$feature_dir")
    hitl_enabled=$(is_hitl_enabled "$feature_dir")

    # 提取 Markdown 表格行
    table=$(grep '^|' "$progress_file" 2>/dev/null || true)
    [[ -z "$table" ]] && continue

    # 扫描：跟踪最后一个已完成步骤，以及紧接着的待办行
    # 已完成 = ✅ / 🔍(HITL关) / 🟡(Gate执行中)
    prev_step=""
    prev_status=""
    found_last_done=false
    pending_gate=""
    pending_gate_status=""

    while IFS= read -r line; do
        [[ "$line" =~ 步骤.*Agent.*状态 ]] && continue
        [[ "$line" =~ "------" ]] && continue

        step=$(echo "$line" | awk -F'|' '{print $2}' | xargs 2>/dev/null || true)
        row_status=$(echo "$line" | awk -F'|' '{print $4}' | xargs 2>/dev/null || true)

        [[ -z "$step" ]] && continue

        # ✅ = 已完成，放行
        if echo "$row_status" | grep -q '✅'; then
            prev_step="$step"
            prev_status="$row_status"
            found_last_done=true
            continue
        fi

        # 🟡 = Gate 执行中，放行。Lead 在 spawn Gatekeeper 前先标记 🟡
        if echo "$row_status" | grep -q '🟡'; then
            prev_step="$step"
            prev_status="$row_status"
            found_last_done=true
            continue
        fi

        # 🔍 = Gate 完成待人类审阅。HITL 关闭时等同于 ✅
        if echo "$row_status" | grep -q '🔍'; then
            if [[ "$hitl_enabled" != "true" ]]; then
                prev_step="$step"
                prev_status="$row_status"
                found_last_done=true
                continue
            fi
        fi

        # 当前行未完成，上一行是已完成 → 这就是"第一个待办"
        if $found_last_done; then
            if echo "$step" | grep -F '*关卡' >/dev/null 2>&1; then
                pending_gate="$step"
                pending_gate_status="$row_status"
            fi
            found_last_done=false
            break
        fi
    done <<< "$table"

    # --- 情况 1：有待办的 Gate 且未完成 → 根据状态区分阻断原因 ---
    if [[ -n "$pending_gate" ]]; then
        gate_label=$(echo "$pending_gate" | sed 's/\*//g' | xargs)
        if echo "$pending_gate_status" | grep -q '🔍'; then
            # Gate 已完成，等待人类审阅（此时 hitl_enabled 必为 true，否则上面已跳过）
            BLOCKED=true
            BLOCK_REASON="功能 '${feature_name}'：${gate_label} 报告已产出，**等待人类审阅**。
请审阅 Gate Report 后告诉 Lead 是否批准（批准后 Lead 会将状态改为 ✅ 并继续流水线）。"
        else
            # Gate 未开始（❌ 或空）— 但 🟡 不会走到这里，因为上面已跳过
            BLOCKED=true
            BLOCK_REASON="功能 '${feature_name}'：'${prev_step}' 已完成，但 **${gate_label}** 尚未开始。
请先完成该 Gate 检查（见 harness/gates.md）。提示：Lead 应先将 Gate 行标记为 🟡，再 spawn Gatekeeper。"
        fi
        break
    fi

    # --- 情况 2：上一个完成的是 Gate 本身 → 验证 Gate Report 物证 ---
    if echo "$prev_step" | grep -F '*关卡' >/dev/null 2>&1; then
        # 🟡 = Gate 执行中，Gatekeeper 还未产出报告，跳过物证检查
        if echo "$prev_status" | grep -q '🟡'; then
            :
        else
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
