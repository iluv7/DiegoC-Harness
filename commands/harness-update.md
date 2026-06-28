# /harness-update — 更新 DiegoC-Harness 到最新版

## 你的任务

执行以下步骤更新 DiegoC-Harness 插件。

### 步骤

```bash
cd ~/.claude/plugins/local/DiegoC-Harness && git pull --ff-only
```

如果 git pull 成功，将命令文件同步到 `~/.claude/commands/`：

```bash
cp ~/.claude/plugins/local/DiegoC-Harness/commands/*.md ~/.claude/commands/
```

### 最后

列出本次更新涉及的 commit 和新变化：

```bash
cd ~/.claude/plugins/local/DiegoC-Harness && git log --oneline -5
```

告诉用户插件已更新到最新，如果有新增或修改的文件也简要说明。
