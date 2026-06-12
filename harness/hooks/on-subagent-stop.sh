#!/usr/bin/env bash
# on-subagent-stop.sh — 记录 Agent 完成日志（可观测性）
#
# 配置方式（添加到 .claude/settings.json）：
#
#   "hooks": {
#     "SubagentStop": [{
#       "command": "bash harness/hooks/on-subagent-stop.sh"
#     }]
#   }

set -euo pipefail

LOG_DIR="docs/harness"
mkdir -p "$LOG_DIR"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Agent 完成" >> "$LOG_DIR/.agent-log"
