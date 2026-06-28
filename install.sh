#!/usr/bin/env bash
# DiegoC-Harness — 一键安装/更新脚本
set -euo pipefail

PLUGIN_DIR="${HOME}/.claude/plugins/local/DiegoC-Harness"
COMMANDS_DIR="${HOME}/.claude/commands"
REPO_URL="https://github.com/iluv7/DiegoC-Harness.git"
MODE="${1:-install}"

echo "=== DiegoC-Harness 安装/更新 ==="
echo ""

# 1. 插件目录（git clone 或 git pull）
mkdir -p "$(dirname "$PLUGIN_DIR")"
if [[ -d "$PLUGIN_DIR/.git" ]]; then
    echo "[1/2] 更新插件..."
    cd "$PLUGIN_DIR"
    git pull --ff-only
else
    if [[ -d "$PLUGIN_DIR" ]]; then
        echo "[1/2] 检测到旧版安装（非 git），备份并重新克隆..."
        mv "$PLUGIN_DIR" "${PLUGIN_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    fi
    echo "[1/2] 克隆插件..."
    git clone "$REPO_URL" "$PLUGIN_DIR"
fi

# 2. 注册命令（Claude Code 自动发现 ~/.claude/commands/*.md）
echo "[2/2] 注册命令..."
mkdir -p "$COMMANDS_DIR"
cp "$PLUGIN_DIR/commands/"*.md "$COMMANDS_DIR/"

echo ""
echo "完成！可用命令："
echo "  /harness-init    — 初始化项目（自动配置 Hook）"
echo "  /harness-dev     — 启动功能开发"
echo "  /harness-update  — 更新插件到最新版"
echo ""
echo "重启 Claude Code 生效。"
