# 业务层技术方案：{{功能名}}

> 作者：Biz Implementer | 日期：{{date}} | 项目：{{project_name}}

## 概述
{{业务层方案的简要描述}}

---

## Service 接口

### {{ServiceName}}
```{{language}}
type {{ServiceName}} interface {
    {{Method}}({{params}}) ({{returns}}, error)
}
```
- **用途**：{{做什么}}
- **被调用方**：API 层（{{HandlerName}}）

---

## 数据访问接口

### {{DaoName}}
```{{language}}
type {{DaoName}} interface {
    {{Method}}({{params}}) ({{returns}}, error)
}
```
- **用途**：{{访问什么数据}}
- **后端**：{{数据库 / 缓存 / 外部 API}}

---

## 业务逻辑流程

### {{操作名}}
1. **校验**：{{校验步骤}}
2. **业务规则**：{{要应用的规则}}
3. **数据访问**：`{{DaoName}}.{{Method}}({{params}})` → {{预期结果}}
4. **变换**：{{数据变换}}
5. **返回**：{{返回值}}

**错误情况**：
- {{情况 1}} → 返回 `{{错误类型}}`

---

## 数据模型

### {{实体名}}
- **表/集合**：`{{table_name}}`
| 字段 | 类型 | 数据库列 | 约束 | 描述 |
|------|------|---------|------|------|

---

## 文件结构
```
{{biz_layer_pattern}}/...
{{dao_layer_pattern}}/...
```
