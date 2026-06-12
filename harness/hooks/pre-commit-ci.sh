#!/usr/bin/env bash
# pre-commit-ci.sh — 关卡 #2 硬拦截
#
# 在每次 git commit 前自动跑编译和 lint。
# 退出非零则阻止提交。
#
# 配置方式（添加到 .claude/settings.json）：
#
#   "hooks": {
#     "PreToolUse": [{
#       "matcher": "Bash(git commit*)",
#       "command": "bash harness/hooks/pre-commit-ci.sh"
#     }]
#   }
#
# 这是整个 harness 里唯一"硬"的约束。其余全靠提示词（软约束）。

set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
cd "$PROJECT_ROOT"

CONFIG_FILE="harness/config.md"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[harness] ⚠️  未找到 harness/config.md。跳过 CI hook。"
    exit 0
fi

# 从配置中提取命令
BUILD_CMD=$(grep -oP 'build_command:\s*`\K[^`]+' "$CONFIG_FILE" 2>/dev/null || echo "")
LINT_CMD=$(grep -oP 'lint_command:\s*`\K[^`]+' "$CONFIG_FILE" 2>/dev/null || echo "")
LINT_ENABLED=$(grep -oP 'lint_enabled:\s*`\K[^`]+' "$CONFIG_FILE" 2>/dev/null || echo "false")

PASSED=true

# 1. 编译
if [[ -n "$BUILD_CMD" ]]; then
    echo "[harness] 运行：$BUILD_CMD"
    if ! eval "$BUILD_CMD" 2>&1; then
        echo "[harness] ❌ 编译失败。提交被阻止。"
        PASSED=false
    else
        echo "[harness] ✅ 编译通过。"
    fi
fi

# 2. Lint（如启用）
if [[ "$LINT_ENABLED" == "true" && -n "$LINT_CMD" ]]; then
    echo "[harness] 运行：$LINT_CMD"
    if ! eval "$LINT_CMD" 2>&1; then
        echo "[harness] ❌ Lint 失败。提交被阻止。"
        PASSED=false
    else
        echo "[harness] ✅ Lint 通过。"
    fi
fi

# 3. 裁决
if [[ "$PASSED" == "false" ]]; then
    echo ""
    echo "============================================"
    echo "  关卡 #2 失败 — 提交被阻止"
    echo "  请修复以上问题后重试。"
    echo "============================================"
    exit 1
fi

echo "[harness] ✅ 关卡 #2 通过。允许提交。"
exit 0
