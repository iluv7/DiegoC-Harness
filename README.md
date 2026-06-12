# Agent Team Harness（智能体团队流水线）

> **纯提示词驱动的多 Agent 协作开发流水线**，Claude Code 插件。
> 8 个 Agent 角色，7 个步骤，4 道质量关卡。**不挑技术栈**。

## 安装

### 方式 A：一键脚本

```bash
curl -fsSL https://raw.githubusercontent.com/iluv7/DiegoC-Harness/main/install.sh | bash
```

脚本干两件事：
1. 克隆仓库到 `~/.claude/plugins/local/DiegoC-Harness/`（存放支持文件）
2. 把命令文件拷到 `~/.claude/commands/`（Claude Code 自动发现）

### 方式 B：手动

```bash
# 1. 克隆
git clone https://github.com/iluv7/DiegoC-Harness.git ~/.claude/plugins/local/DiegoC-Harness

# 2. 注册命令（Claude Code 只自动发现 ~/.claude/commands/）
mkdir -p ~/.claude/commands
cp ~/.claude/plugins/local/DiegoC-Harness/commands/*.md ~/.claude/commands/
```

**重启 Claude Code** 后 `/harness-init` 和 `/harness-dev` 全局可用。

## 使用

### 1. 项目初始化（一次）

在任意项目目录下，进入 Claude Code 敲：

```
/harness-init
```

引导你创建 `harness/config.md`（语言、框架、编译命令、文件路径）。

### 2. 开发功能

```
/harness-dev "你的 PRD 或功能描述"
```

Lead 按 7 步 4 关卡自动拉起子 Agent：需求分析 → 技术方案 → 编码 → CI → 审查 → 测试 → 交付。

### 3. 中断恢复

会话断了？重新敲 `/harness-dev`，从 `PROGRESS.md` 中断点恢复。

## 项目里会多什么

```
你的项目/
├── harness/config.md          ← 技术栈配置（填一次，30 行）
└── docs/harness/{功能名}/     ← 功能开发产出
```

命令、Agent 定义、模板全在 `~/.claude/` 下，项目零污染。

## 8 个 Agent 角色

| 角色 | 做什么 | 写代码？ |
|------|--------|:---:|
| **Lead** | 总协调，不写代码，验关卡 | ✗ |
| **Planner** | 读 PRD → 结构化需求 + API 契约 | ✗ |
| **API Implementer** | API/handler/路由 + 请求校验 | ✓ |
| **Biz Implementer** | 业务逻辑 + 数据访问 | ✓ |
| **QA Designer** | 设计测试矩阵 | ✗ |
| **CI Runner** | 跑编译 + lint | ✗ |
| **Code Reviewer** | 静态审查 + 测试审查 | ✗ |
| **QA Runner** | 写测试 + 跑测试 + 出报告 | ✓ |

## 技术栈适配

所有差异集中在 `harness/config.md`。Agent 定义和流水线**不硬编码任何语言或工具**。`examples/` 下有 Go/Python/Node.js 预配。

## 可选：CI Hook

项目 `.claude/settings.json`：

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash(git commit*)",
      "command": "bash ~/.claude/plugins/local/DiegoC-Harness/harness/hooks/pre-commit-ci.sh"
    }]
  }
}
```

## 许可证

MIT
