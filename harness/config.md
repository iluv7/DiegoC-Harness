# Agent Team Harness — 配置

> 每个项目填一次这个文件。这是**唯一**存放技术栈细节的地方。
> 所有 Agent 定义和流水线阶段都引用这份配置 —— 绝不硬编码语言或工具。

---

## 项目信息

- **project_name**：`{{你的项目名称}}`
- **description**：`{{项目简介}}`

---

## 技术栈

- **language**：`{{Go | Python | TypeScript | Java | Rust | ...}}`
- **framework**：`{{Gin | FastAPI | Express | Spring | Actix | ...}}`
- **package_manager**：`{{go mod | pip | npm | maven | cargo | ...}}`

---

## 命令

以下命令在项目根目录执行。

- **build_command**：`{{例如：go build ./... | npm run build | cargo build}}`
- **test_command**：`{{例如：go test ./... | pytest | npm test | cargo test}}`
- **lint_command**：`{{例如：golangci-lint run | flake8 | eslint . | clippy}}`
- **proto_command**：`{{不用 protobuf 就留空，或者填 buf generate}}`

---

## CI 设置

- **lint_enabled**：`{{true | false}}`
- **proto_compile_enabled**：`{{true | false}}`
- **coverage_threshold**：`{{例如：80}}`（百分比）

---

## 文件匹配模式

使用 glob 风格的模式。这些定义了 Agent 之间的文件归属边界。

- **api_layer_pattern**：`{{例如：internal/api/** | src/routes/** | api/**}}`
  _API handler/控制器/路由代码所在位置。归 API Implementer 负责。_

- **biz_layer_pattern**：`{{例如：internal/service/** | src/services/** | service/**}}`
  _业务逻辑（service）代码所在位置。归 Biz Implementer 负责。_

- **dao_layer_pattern**：`{{例如：internal/dao/** | src/repositories/** | repository/**}}`
  _数据访问代码所在位置。归 Biz Implementer 负责。_

- **test_file_suffix**：`{{例如：_test.go | .test.ts | _test.py | Test.java}}`
  _测试文件的后缀。_

- **main_entry**：`{{例如：cmd/server/main.go | src/index.ts | main.py}}`
  _应用入口文件。_

---

## 编码约定

- **file_naming**：`{{例如：snake_case.go | kebab-case.ts | PascalCase.java}}`
- **function_naming**：`{{例如：PascalCase（公开）/ camelCase（私有） | snake_case}}`
- **variable_naming**：`{{例如：camelCase | snake_case}}`
- **indent**：`{{tabs | spaces: 2 | spaces: 4}}`

---

## Agent 自定义（可选）

给特定 Agent 添加额外指令。不想加就留空。

- **planner_extra**：`""`
- **api_implementer_extra**：`""`
- **biz_implementer_extra**：`""`
- **qa_designer_extra**：`""`
- **ci_runner_extra**：`""`
- **code_reviewer_extra**：`""`
- **qa_runner_extra**：`""`
