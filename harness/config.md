# Agent Team Harness — 配置

> 每个项目填一次这个文件。这是**唯一**存放技术栈细节的地方。
> 所有 Agent 定义和流水线阶段都引用这份配置 —— 绝不硬编码语言或工具。

---

## 项目信息

- **project_name**：`myservice`
- **description**：`基于 Chi 框架的 Go 微服务`

---

## 技术栈

- **language**：`Go`
- **framework**：`Chi`
- **package_manager**：`go mod`

---

## 命令

以下命令在项目根目录执行。

- **build_command**：`go build ./...`
- **test_command**：`go test ./... -cover`
- **lint_command**：`golangci-lint run ./...`
- **proto_command**：`""`

---

## CI 设置

- **lint_enabled**：`true`
- **proto_compile_enabled**：`false`
- **coverage_threshold**：`80`（百分比）

---

## 文件匹配模式

使用 glob 风格的模式。这些定义了 Agent 之间的文件归属边界。

- **api_layer_pattern**：`internal/api/**`
  _API handler/控制器/路由代码所在位置。归 API Implementer 负责。_

- **biz_layer_pattern**：`internal/service/**`
  _业务逻辑（service）代码所在位置。归 Biz Implementer 负责。_

- **dao_layer_pattern**：`internal/dao/**`
  _数据访问代码所在位置。归 Biz Implementer 负责。_

- **test_file_suffix**：`_test.go`
  _测试文件的后缀。_

- **main_entry**：`cmd/server/main.go`
  _应用入口文件。_

---

## 编码约定

- **file_naming**：`snake_case.go`
- **function_naming**：`PascalCase（公开）/ camelCase（私有）`
- **variable_naming**：`camelCase`
- **indent**：`tabs`

---

## HITL（人机协作）

- **hitl_enabled**：`false`
  _每道 Gate 完成后是否暂停等待人类审阅。`true` = 每道 Gate 后暂停，人类批准后才继续；`false` = Lead 自行裁决，Gate 直接通过。默认为 `false`。_

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
