# /harness-init — 首次初始化

首次使用 DiegoC-Harness 时，初始化当前项目。每个项目只需跑一次。

## 步骤 1：检测状态
检查当前项目的 `harness/config.md` 是否已存在且已填写。

## 步骤 2：引导填写配置

如果不存在或未填写：
1. 在项目根目录创建 `harness/` 目录
2. 读取 `~/.claude/plugins/local/DiegoC-Harness/harness/config.md` 作为模板
3. 引导用户逐项填写。必填：
   - **project_name** — 项目名
   - **language** — Go、Python、TypeScript 等
   - **framework** — Gin、FastAPI、Express 等
   - **build_command** — 编译命令（如 go build ./...）
   - **test_command** — 测试命令（如 go test ./...）
   - **lint_command** — lint 命令（如 golangci-lint run）
   - **api_layer_pattern** — API 层文件 glob（如 internal/api/**）
   - **biz_layer_pattern** — 业务层文件 glob（如 internal/service/**）
   - **dao_layer_pattern** — 数据层文件 glob（如 internal/dao/**）
   - **test_file_suffix** — 测试文件后缀（如 _test.go）

   可选项：proto_command、coverage_threshold、lint_enabled、proto_compile_enabled。

   参考：`~/.claude/plugins/local/DiegoC-Harness/examples/` 下有 Go/Python/Node.js 预配。

## 步骤 3：初始化项目目录
创建 `docs/harness/` 目录。

## 步骤 4：自动配置 Hook 硬拦截

检查并写入 `.claude/settings.json`，追加 `PreToolUse` hook 配置：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Agent",
        "command": "bash ~/.claude/plugins/local/DiegoC-Harness/harness/hooks/pre-spawn-gate-check.sh"
      }
    ]
  }
}
```

如果 `.claude/settings.json` 已存在且已有 hook 配置，则合并而非覆盖。如果该 hook 已配置则跳过。

## 步骤 5：验证
- [ ] `harness/config.md` 所有必填项已填
- [ ] `docs/harness/` 目录存在
- [ ] `.claude/settings.json` 中已配置 Gate check hook

## 步骤 6：完成
告知用户：
```
DiegoC-Harness 就绪！

已自动配置：
  ✓ 项目配置   harness/config.md
  ✓ Gate Hook  .claude/settings.json（每次 spawn Agent 前强制验证 Gate 通过）

接下来：
  /harness-dev "你的需求描述"
```
