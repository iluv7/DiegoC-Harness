#!/usr/bin/env bash
# Agent Team Harness — 一键安装脚本
set -euo pipefail

PLUGIN_DIR="${HOME}/.claude/plugins/local/DiegoC-Harness"
COMMANDS_DIR="${HOME}/.claude/commands"
REPO_URL="https://github.com/iluv7/DiegoC-Harness.git"

echo "=== Agent Team Harness 安装 ==="
echo ""

# 1. 克隆插件（放支持文件：agents、phases、templates 等）
mkdir -p "$(dirname "$PLUGIN_DIR")"
if [[ -d "$PLUGIN_DIR" ]]; then
    echo "[1/2] 更新已有安装..."
    cd "$PLUGIN_DIR" && git pull
else
    echo "[1/2] 克隆仓库..."
    git clone "$REPO_URL" "$PLUGIN_DIR"
fi

# 2. 把命令链到 ~/.claude/commands/（Claude Code 自动发现）
echo "[2/2] 注册命令..."
mkdir -p "$COMMANDS_DIR"
cp "$PLUGIN_DIR/commands/"*.md "$COMMANDS_DIR/"

echo ""
echo "安装完成！重启 Claude Code 即可使用："
echo "  /harness-init    — 初始化项目"
echo "  /harness-dev     — 启动功能开发"
