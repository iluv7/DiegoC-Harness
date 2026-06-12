#!/usr/bin/env bash
# on-session-end.sh — 会话结束时检查 PROGRESS.md 状态
#
# 配置方式（添加到 .claude/settings.json）：
#
#   "hooks": {
#     "Stop": [{
#       "command": "bash harness/hooks/on-session-end.sh"
#     }]
#   }

set -euo pipefail

# 查找所有活跃功能的 PROGRESS.md
if compgen -G "docs/harness/*/PROGRESS.md" > /dev/null 2>&1; then
    for progress_file in docs/harness/*/PROGRESS.md; do
        feature_dir=$(dirname "$progress_file")
        feature_name=$(basename "$feature_dir")

        # 检查是否有未完成步骤（🟡 或 ⛔）
        if grep -q '🟡\|⛔' "$progress_file" 2>/dev/null; then
            echo "[harness] ⚠️  功能 '$feature_name' 有未完成步骤。"
            echo "[harness]    运行 /harness-dev 继续。"
        fi
    done
fi

exit 0
