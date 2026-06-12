# 阶段 2：编码实现（并行）

三个 Agent 并行工作：
- API Implementer：写 API 层代码
- Biz Implementer：写业务层代码
- QA Designer：设计测试矩阵（不写代码）

## API Implementer：写生产代码
**输入**：角色定义 + config.md + spec.md + tech-design/api.md + contracts/api.md
**任务**：按技术方案实现 API 层，写入匹配 `api_layer_pattern` 的文件
**规则**：遵循编码规范、实现全部 handler、严格按 contracts/api.md 调 Biz 接口、处理错误

## Biz Implementer：写生产代码
**输入**：角色定义 + config.md + spec.md + tech-design/biz.md + contracts/api.md
**任务**：按技术方案实现业务层，写入匹配 `biz_layer_pattern` 和 `dao_layer_pattern` 的文件
**规则**：实现全部 service/DAO 接口、业务逻辑不能只有 happy path、正确处理和传播错误

## QA Designer：设计测试矩阵
**输入**：角色定义 + spec.md
**任务**：设计测试用例，写入 `test-matrix.md`。不要写测试代码。
**规则**：覆盖正常路径 + 边界情况 + 错误条件 + 边界值，至少 30% 负向测试

## 关卡 #2：CI 检查

三个 Agent 都完成后，spawn CI Runner 跑编译 + lint。

如果失败：解析错误 → 确定归属（API 还是 Biz）→ 写入 qa-log.md → 要求修正（最多 2 次）
