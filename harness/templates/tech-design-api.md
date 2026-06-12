# API 层技术方案：{{功能名}}

> 作者：API Implementer | 日期：{{date}} | 项目：{{project_name}}

## 概述
{{API 层方案的简要描述}}

---

## 文件结构
```
{{api_layer_pattern}}/
├── {{file1}}
├── {{file2}}
│   ├── {{subfile1}}
│   └── {{subfile2}}
└── {{file3}}
```

---

## Handler 签名

### {{HandlerName}}
- **路由**：`{{METHOD}} {{path}}`
- **描述**：{{做什么}}
- **请求类型**：`{{RequestType}}`
- **响应类型**：`{{ResponseType}}`
- **校验规则**：
  - {{规则 1}}
  - {{规则 2}}
- **调用 Biz**：`{{BizService}}.{{Method}}({{params}}) → ({{returns}}, error)`
- **错误映射**：
  - Biz 错误 X → HTTP 400
  - Biz 错误 Y → HTTP 404
  - 其他错误 → HTTP 500

<!-- 每个 handler 重复 -->

---

## 路由注册
- **文件**：{{在哪里注册路由}}
- **分组/前缀**：{{路由前缀}}
- **中间件**：
  - {{中间件 1}} — {{用途}}

---

## 错误响应格式
```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "人类可读的信息",
    "details": {}
  }
}
```
