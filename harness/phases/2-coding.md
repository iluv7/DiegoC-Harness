# 阶段 2：编码实现（并行，TDD：红灯 → 绿灯）

三个 Agent 并行工作：
- API Implementer：写 API 层代码
- Biz Implementer：写业务层代码
- QA Designer：设计测试矩阵 + 实现 P0 验收测试（红灯）

## TDD 铁律（对所有实现者生效）

**禁止修改任何测试文件**（匹配 `test_file_suffix`）。测试红了只有两条路：

1. 继续实现生产代码直到绿灯
2. 测试与 spec/契约矛盾 → 写 qa-log.md 升级 Lead，走 spec 变更流程（更新 spec → test-matrix → 测试，由 Lead 裁决）

绝不自己改测试改绿。P0 测试是 spec 验收标准的可执行形式，改测试 = 改契约，必须留痕。

## API Implementer：写生产代码
**输入**：角色定义 + config.md + spec.md + tech-design/api.md + contracts/api.md
**任务**：
1. 按 `contracts/api.md` 定义接口 + 最小 stub（让 QA Designer 的 P0 测试能编译）
2. 跑 `{test_command}`，红灯 → 逐项实现 handler 直到绿灯
3. 实现 API 契约中定义的**全部** handler
**规则**：遵循编码规范、严格按 contracts/api.md 调 Biz 接口、处理错误、禁止改测试

## Biz Implementer：写生产代码
**输入**：角色定义 + config.md + spec.md + tech-design/biz.md + contracts/api.md
**任务**：
1. 按 `contracts/api.md` 定义 service/DAO 接口 + 最小 stub
2. 跑 `{test_command}`，红灯 → 逐项实现到绿灯
3. 业务逻辑必须处理所有边界情况（不能只有 happy path），正确处理和传播错误
**规则**：禁止改测试、service 接口与 `contracts/api.md` 一致

## QA Designer：测试矩阵 + P0 测试（红灯）
**输入**：角色定义 + spec.md + contracts/api.md
**任务**：
1. 设计测试用例，写入 `test-matrix.md`（覆盖 P0/P1/P2）
2. **把每个 P0 用例实现为测试代码**（红灯）
**规则**：只写 P0 测试；不写生产代码；测试与 spec 矛盾 → 写 qa-log.md 升级 Lead，不猜、不静默改测试；至少 30% 负向测试

## 关卡 #2：CI 检查（红灯 → 绿灯循环）

三个 Agent 完成后，spawn CI Runner 跑编译 + lint + `{test_command}`。

- **编译失败** → 确定归属（API 还是 Biz，大多是测试引用的接口/stub 未定义）→ 写 qa-log.md → 要求补接口（最多 2 次）
- **编译通过但 P0 红灯** → 实现未完成，写 qa-log.md 要求实现者继续实现到绿灯（最多 2 次）
- **P0 全绿 + 编译 0 + lint 0** → 通过关卡 #2
- **测试与 spec 矛盾** → 不是实现者的问题，升级 Lead 走 spec 变更流程
