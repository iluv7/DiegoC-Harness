# 示例配置：Python + FastAPI

```markdown
## 项目信息
- project_name: `myapi`
- description: `基于 FastAPI 的 Python REST API 示例`

## 技术栈
- language: `Python`
- framework: `FastAPI`
- package_manager: `pip`（或 `poetry`）

## 命令
- build_command: `pip install -r requirements.txt`（或 `poetry install`）
- test_command: `pytest --cov=. --cov-report=term`
- lint_command: `ruff check .`
- proto_command: ``（不用 protobuf）

## CI 设置
- lint_enabled: `true`
- proto_compile_enabled: `false`
- coverage_threshold: `85`

## 文件匹配模式
- api_layer_pattern: `src/routes/**`
- biz_layer_pattern: `src/services/**`
- dao_layer_pattern: `src/repositories/**`
- test_file_suffix: `_test.py`
- main_entry: `src/main.py`

## 编码约定
- file_naming: `snake_case.py`
- function_naming: `snake_case`
- variable_naming: `snake_case`
- indent: `spaces: 4`
```
