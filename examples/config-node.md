# 示例配置：TypeScript + Express

```markdown
## 项目信息
- project_name: `myapp`
- description: `基于 Express + TypeScript 的 Node.js REST API 示例`

## 技术栈
- language: `TypeScript`
- framework: `Express`
- package_manager: `npm`（或 `yarn` / `pnpm`）

## 命令
- build_command: `npm run build`（或 `tsc`）
- test_command: `npm test`（或 `jest --coverage`）
- lint_command: `npm run lint`（或 `eslint . --ext .ts`）
- proto_command: ``（不用 protobuf）

## CI 设置
- lint_enabled: `true`
- proto_compile_enabled: `false`
- coverage_threshold: `80`

## 文件匹配模式
- api_layer_pattern: `src/routes/**`
- biz_layer_pattern: `src/services/**`
- dao_layer_pattern: `src/repositories/**`
- test_file_suffix: `.test.ts`
- main_entry: `src/index.ts`

## 编码约定
- file_naming: `kebab-case.ts`
- function_naming: `camelCase`
- variable_naming: `camelCase`
- indent: `spaces: 2`
```
