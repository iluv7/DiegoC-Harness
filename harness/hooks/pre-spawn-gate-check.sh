#!/usr/bin/env bash
# pre-spawn-gate-check.sh — Agent spawn 前检查 Gate 是否真正通过
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
# 规则（两条，缺一不可）：
#   1. Gate 不能跳过：最后一个 ✅ 之后紧跟未完成的 Gate → 阻断。
#      - Gate 行 🟡（进行中）放行——否则连 Gatekeeper 自己都无法 spawn
#      - Gate 行 🔍：HITL 开启（hitl_enabled: true）→ 硬拦，等人类审阅；
#        HITL 关闭 → 视同 ✅（防死锁）
#   2. Gate 必须真的通过：最后一个 ✅ 是 Gate 时，对应 Gate Report
#      必须存在（物证），且结论行精确为 `**结论**：ALL PASS`。
#      物证缺失或结论不是 ALL PASS 则阻断。

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

# 只接受 Gatekeeper 按模板输出的精确结论，避免正文中出现
# "ALL PASS" 或 "NOT ALL PASS" 时被误判为通过。允许中英文冒号及行尾空白。
report_is_all_pass() {
    local report="$1"
    grep -Eq '^\*\*结论\*\*(：|:)[[:space:]]*ALL PASS[[:space:]]*$' "$report"
}

# 读项目 config.md 中的 hitl_enabled，默认 false。
# 格式：- hitl_enabled: `true`（或 false）。
# 用 grep -E 而非 grep -P / sed 交替（macOS BSD 工具不支持）。
is_hitl_enabled() {
    local feature_dir="$1"
    local project_root config_file val
    # feature_dir 形如 docs/harness/<功能名>，上溯三层回到项目根目录
    project_root=$(cd "$feature_dir/../../.." 2>/dev/null && pwd || true)
    config_file="${project_root}/harness/config.md"
    if [[ -f "$config_file" ]]; then
        val=$(grep 'hitl_enabled' "$config_file" 2>/dev/null | head -1 \
            | grep -oE '`(true|false)`' | head -1 | tr -d '`' || true)
        if [[ "$val" == "true" ]]; then
            echo "true"
            return
        fi
    fi
    echo "false"
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
    hitl_enabled=$(is_hitl_enabled "$feature_dir")

    # 提取 Markdown 表格行
    table=$(grep '^|' "$progress_file" 2>/dev/null || true)
    [[ -z "$table" ]] && continue

    # 扫描：跟踪最后一个 ✅（不管是不是 Gate），以及紧随其后的待办 Gate
    prev_step=""
    found_last_done=false
    pending_gate=""
    pending_gate_status=""

    while IFS= read -r line; do
        [[ "$line" =~ 步骤.*Agent.*状态 ]] && continue
        [[ "$line" =~ "------" ]] && continue

        step=$(echo "$line" | awk -F'|' '{print $2}' | xargs 2>/dev/null || true)
        row_status=$(echo "$line" | awk -F'|' '{print $4}' | xargs 2>/dev/null || true)

        [[ -z "$step" ]] && continue

        # 🟡 = Gate 进行中 → 放行（Lead 正要 spawn Gatekeeper 或返工）
        if echo "$row_status" | grep -q '🟡'; then
            continue
        fi

        if echo "$row_status" | grep -q '✅'; then
            prev_step="$step"
            found_last_done=true
            continue
        fi

        # 🔍 = Gate 完成待人类审阅。HITL 关闭时视同 ✅ 直接放行
        if echo "$row_status" | grep -q '🔍'; then
            if [[ "$hitl_enabled" != "true" ]]; then
                prev_step="$step"
                found_last_done=true
                continue
            fi
        fi

        # 当前行未完成，上一行是 ✅ → 这就是"第一个待办"
        if $found_last_done; then
            if echo "$step" | grep -F '*关卡' >/dev/null 2>&1; then
                pending_gate="$step"        # Gate 未完成
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
            # Gate 已完成，等待人类审阅（此时 hitl_enabled 必为 true，否则上面已视同 ✅）
            BLOCKED=true
            BLOCK_REASON="功能 '${feature_name}'：${gate_label} 报告已产出，**等待人类审阅**。
请审阅 Gate Report 后告诉 Lead 是否批准（批准后 Lead 会将状态改为 ✅ 并继续流水线）。"
        else
            # Gate 未开始或在执行中
            BLOCKED=true
            BLOCK_REASON="功能 '${feature_name}'：'${prev_step}' 已完成，但 **${gate_label}** 尚未通过。
请先完成该 Gate 检查（见 harness/gates.md），在 PROGRESS.md 中将该 Gate 标记为 ✅ 后重试。
如果正在执行该 Gate（需要 spawn Gatekeeper 或返工），请先将该 Gate 行状态标记为 🟡。"
        fi
        break
    fi

    # --- 情况 2：上一个完成的是 Gate 本身（已 ✅）→ 验证物证 + ALL PASS 结论 ---
    if echo "$prev_step" | grep -F '*关卡' >/dev/null 2>&1; then
        gate_num=$(extract_gate_num "$prev_step")
        report_rel=$(gate_report_path "$gate_num")
        report_abs="${feature_dir}/${report_rel}"
        gate_label=$(echo "$prev_step" | sed 's/\*//g' | xargs)

        if [[ ! -f "$report_abs" ]]; then
            BLOCKED=true
            BLOCK_REASON="功能 '${feature_name}'：${gate_label} 在 PROGRESS.md 中标记为 ✅，但 Gate Report 文件不存在（物证缺失）。
缺少文件：${report_rel}
请先完成 Gate 检查并产出 Gate Report（见 harness/gates.md），再更新 PROGRESS.md。"
            break
        fi

        if ! report_is_all_pass "$report_abs"; then
            BLOCKED=true
            BLOCK_REASON="功能 '${feature_name}'：${gate_label} 在 PROGRESS.md 中标记为 ✅，但 Gate Report 结论行不是 \`**结论**：ALL PASS\`。
报告文件：${report_rel}
Gate 未真正通过——请按 Gate Report 的 FAIL 项返工后重新审查，不要将未通过的 Gate 标记为 ✅。"
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
