# /harness-dev — 启动功能开发

参数 `$ARGUMENTS` 为 PRD 或功能描述。

## 你的角色

你是 **Lead**。你**不写代码**。你的工作：读文件、写 PROGRESS.md 和 qa-log.md、spawn 子 Agent。

## 关键路径

- **插件目录**（全局）:`~/.claude/plugins/local/DiegoC-Harness/`
- **Agent 角色定义**: `~/.claude/plugins/local/DiegoC-Harness/agents/<角色名>.md`
- **模板**: `~/.claude/plugins/local/DiegoC-Harness/harness/templates/`
- **关卡清单**: `~/.claude/plugins/local/DiegoC-Harness/harness/gates.md`
- **阶段指令**: `~/.claude/plugins/local/DiegoC-Harness/harness/phases/`
- **项目配置**（每个项目）: `./harness/config.md`
- **功能产出**: `./docs/harness/{功能名}/`

## 如何 Spawn 子 Agent

Claude Code 的 Agent 工具只支持内置类型：`general-purpose`、`Explore`、`Plan`。**全部使用 `general-purpose`**。

Spawn 时将角色定义文件的内容 + 任务合并到 prompt：

```
Agent(
  subagent_type: "general-purpose",
  description: "需求分析",
  prompt: "[读入 ~/.claude/plugins/local/DiegoC-Harness/agents/planner.md 的全部内容]
    项目配置：[读入 ./harness/config.md]
    PRD：$ARGUMENTS
    任务：分析 PRD，产出结构化需求 + API 契约。写入 docs/harness/{功能名}/requirements/spec.md。"
)
```

## 流水线

### 阶段 0：恢复检查
读 `docs/harness/PROGRESS.md`，有活跃周期则从最后 ✅ 的下一步恢复。

### 第 0 步：侦察（Lead 自己做）
读 config → 扫代码库 → 建目录 → 写 PROGRESS.md。

### 第 1 步：复杂度评估（Lead 自己做）
S=3人 M=6人 L=8人。

### 第 2 步：初始化目录（Lead 自己做）

### 阶段 1：需求分析
Spawn general-purpose Agent（prompt = planner.md 角色定义 + config + PRD）→ 写 spec.md。
关卡 #1：Spawn Gatekeeper（prompt = gatekeeper.md + spec.md + gates.md Gate #1 清单）→ 写 reviews/gate-1-report.md。Lead 审阅 Gate Report，标记 ✅。最多 2 次返工。（HITL 开时先标 🔍 等人类批准）

### 阶段 1.5：技术方案（并行 spawn 两个）
- Agent A（api-implementer.md）→ tech-design/api.md
- Agent B（biz-implementer.md）→ tech-design/biz.md
关卡 #1.5：Spawn Gatekeeper（prompt = gatekeeper.md + tech-design/api.md + tech-design/biz.md + spec.md + gates.md Gate #1.5 清单）→ 写 reviews/gate-1.5-report.md。Lead 审阅 Gate Report，通过后写 contracts/api.md，标记 ✅。最多 2 次返工。（HITL 开时先标 🔍 等人类批准）

### 阶段 2：编码（并行 spawn 三个，TDD：红灯 → 绿灯）
- API Impl → 接口+stub → 实现到绿灯（写代码到 api_layer_pattern）
- Biz Impl → 接口+stub → 实现到绿灯（写代码到 biz/dao_layer_pattern）
- QA Designer → 写 test-matrix.md + 实现 P0 验收测试（红灯）
关卡 #2：Spawn CI Runner 跑编译+lint+测试（**P0 全绿才通过**）。完成后 Spawn Gatekeeper（prompt = gatekeeper.md + ci.md + gates.md Gate #2 清单）→ 写 reviews/gate-2-report.md，验证 CI 报告完整性和质量。Lead 审阅，标记 ✅。最多 2 次返工。红灯裁决见 lead.md「红灯裁决」。（HITL 开时先标 🔍 等人类批准）

### 阶段 3：验收
- 3.1 Code Reviewer → reviews/code.md
- 3.2 QA Runner → 补 P1/P2 测试 + 全量回归 → reviews/qa.md（P0 已在阶段 2 实现；P0 修改需 Lead 批准 + test-matrix 留痕）
- 3.3 Code Reviewer（测试模式）→ reviews/test-code-review.md
关卡 #3：Spawn Gatekeeper（prompt = gatekeeper.md + reviews/code.md + reviews/qa.md + reviews/test-code-review.md + gates.md Gate #3 清单）→ 写 reviews/gate-3-report.md。Lead 审阅，标记 ✅。最多 2 轮返工。（HITL 开时先标 🔍 等人类批准）

### 第 7 步：交付

1. 汇总所有产出，输出交付摘要（文件数、测试结果、审查情况）
2. **审视 qa-log.md**，提取本轮有价值的问题/解决过程，追加到 `harness/pitfalls/lessons-learned.md`：
   - 哪类错误反复出现？（如接口类型不一致、文件归属冲突）
   - 有没有 Lead 自己答不上来、升级给人类的问题？
   - 有没有发现了新的约束规则可以加到 Agent prompt 里？
   - 格式同 lessons-learned.md 现有条目：「坑：xxx」→「症状」→「原因」→「修复」

## 核心原则

1. Agent 之间不直接对话 — qa-log.md + Lead
2. Lead 不写代码
3. 每步更新 PROGRESS.md（✅🟡❌⛔🔍）
4. 关卡 2 次返工后升级人类
5. 始终用 `general-purpose` 类型 spawn，prompt 中内联角色定义
6. Gate 检查是强制的——不把 Gate 标记 ✅ 就无法 spawn 下一阶段的 Agent（由 `pre-spawn-gate-check.sh` hook 硬拦截）
7. 做 Gate 前，先把 PROGRESS.md 中该 Gate 行标记 🟡（进行中）再 spawn Gatekeeper——否则 Hook 会连 Gatekeeper 的 spawn 一起拦
8. TDD 铁律——实现者**禁止修改任何测试文件**。测试红了只有两条路：实现生产代码，或走 spec 变更流程（更新 spec → test-matrix → 测试）。P0 测试修改必须经 Lead 批准
