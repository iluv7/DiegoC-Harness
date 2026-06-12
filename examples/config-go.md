# 示例配置：Go + Gin

```markdown
## 项目信息
- project_name: `myservice`
- description: `基于 Gin 框架的 Go 微服务示例`

## 技术栈
- language: `Go`
- framework: `Gin`
- package_manager: `go mod`

## 命令
- build_command: `go build ./...`
- test_command: `go test ./... -cover`
- lint_command: `golangci-lint run ./...`
- proto_command: `buf generate`

## CI 设置
- lint_enabled: `true`
- proto_compile_enabled: `true`
- coverage_threshold: `80`

## 文件匹配模式
- api_layer_pattern: `internal/api/**`
- biz_layer_pattern: `internal/service/**`
- dao_layer_pattern: `internal/dao/**`
- test_file_suffix: `_test.go`
- main_entry: `cmd/server/main.go`

## 编码约定
- file_naming: `snake_case.go`
- function_naming: `PascalCase（公开）/ camelCase（私有）`
- variable_naming: `camelCase`
- indent: `tabs`
```
