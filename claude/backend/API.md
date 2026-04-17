# 记账 App 后端 API 文档

## 基本信息

- **Base URL**: `http://localhost:3000/api`
- **Content-Type**: `application/json`
- **认证方式**: JWT Bearer Token（通过 `Authorization: Bearer <token>` 请求头传递）
- **金额单位**: 分（整数），如 2550 表示 25.50 元
- **日期格式**: `YYYY-MM-DD`

## 通用响应格式

```json
// 成功
{ "data": { ... } }

// 失败
{ "error": { "code": "ERROR_CODE", "message": "错误描述" } }
```

## 错误码

| HTTP 状态码 | 错误码 | 说明 |
|------------|--------|------|
| 400 | VALIDATION_ERROR | 请求参数校验失败 |
| 401 | UNAUTHORIZED | 未登录或 Token 无效/过期 |
| 403 | FORBIDDEN | 无权操作该资源 |
| 404 | NOT_FOUND | 资源不存在 |
| 409 | CONFLICT | 资源冲突（如用户名已存在） |
| 500 | INTERNAL_ERROR | 服务器内部错误 |

---

## 接口列表

### 1. 用户注册

**POST** `/api/auth/register`

无需鉴权。

**请求体：**

| 字段 | 类型 | 必填 | 校验 |
|------|------|------|------|
| username | string | 是 | 3-32 字符 |
| password | string | 是 | 6-64 字符 |

**请求示例：**

```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H 'Content-Type: application/json' \
  -d '{"username":"alice","password":"123456"}'
```

**成功响应 (200)：**

```json
{
  "data": {
    "id": 1,
    "username": "alice",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**错误响应：**
- 400：参数校验失败
- 409：用户名已存在

---

### 2. 用户登录

**POST** `/api/auth/login`

无需鉴权。

**请求体：**

| 字段 | 类型 | 必填 |
|------|------|------|
| username | string | 是 |
| password | string | 是 |

**请求示例：**

```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"alice","password":"123456"}'
```

**成功响应 (200)：**

```json
{
  "data": {
    "id": 1,
    "username": "alice",
    "token": "eyJhbGciOiJIUzI1NiIs..."
  }
}
```

**错误响应：**
- 401：用户名或密码错误

---

### 3. 创建记账记录

**POST** `/api/records`

需要鉴权。

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| amount | integer | 是 | 金额（分），必须 > 0 |
| isIncome | 0 \| 1 | 是 | 0=支出，1=收入 |
| categoryId | integer | 是 | 分类 ID |
| note | string | 否 | 备注，最多 200 字符 |
| date | string | 否 | YYYY-MM-DD，默认今天 |

**请求示例：**

```bash
curl -X POST http://localhost:3000/api/records \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <token>' \
  -d '{"amount":2550,"isIncome":0,"categoryId":1,"note":"午餐","date":"2026-04-15"}'
```

**成功响应 (200)：**

```json
{
  "data": {
    "id": 1,
    "userId": 1,
    "categoryId": 1,
    "isIncome": 0,
    "amount": 2550,
    "note": "午餐",
    "date": "2026-04-15",
    "createdAt": "2026-04-15T10:30:00.000Z"
  }
}
```

---

### 4. 获取记账记录列表

**GET** `/api/records`

需要鉴权。返回当前用户的所有记录，按日期降序排列。

**请求示例：**

```bash
curl http://localhost:3000/api/records \
  -H 'Authorization: Bearer <token>'
```

**成功响应 (200)：**

```json
{
  "data": [
    {
      "id": 2,
      "userId": 1,
      "categoryId": 9,
      "isIncome": 1,
      "amount": 1000000,
      "note": "4月工资",
      "date": "2026-04-15",
      "createdAt": "2026-04-15T10:35:00.000Z"
    },
    {
      "id": 1,
      "userId": 1,
      "categoryId": 1,
      "isIncome": 0,
      "amount": 2550,
      "note": "午餐",
      "date": "2026-04-14",
      "createdAt": "2026-04-14T10:30:00.000Z"
    }
  ]
}
```

---

### 5. 获取单条记账记录

**GET** `/api/records/:id`

需要鉴权。只能查看自己的记录。

**请求示例：**

```bash
curl http://localhost:3000/api/records/1 \
  -H 'Authorization: Bearer <token>'
```

**成功响应 (200)：**

```json
{
  "data": {
    "id": 1,
    "userId": 1,
    "categoryId": 1,
    "isIncome": 0,
    "amount": 2550,
    "note": "午餐",
    "date": "2026-04-15",
    "createdAt": "2026-04-15T10:30:00.000Z"
  }
}
```

**错误响应：**
- 403：非本人记录
- 404：记录不存在

---

### 6. 更新记账记录

**PUT** `/api/records/:id`

需要鉴权。只能更新自己的记录。所有字段均为可选（部分更新）。

**请求体：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| amount | integer | 否 | 金额（分），必须 > 0 |
| isIncome | 0 \| 1 | 否 | 0=支出，1=收入 |
| categoryId | integer | 否 | 分类 ID |
| note | string | 否 | 备注，最多 200 字符 |
| date | string | 否 | YYYY-MM-DD |

**请求示例：**

```bash
curl -X PUT http://localhost:3000/api/records/1 \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer <token>' \
  -d '{"amount":3000,"note":"晚餐"}'
```

**成功响应 (200)：** 返回更新后的完整记录。

**错误响应：**
- 400：参数校验失败
- 403：非本人记录
- 404：记录不存在

---

### 7. 删除记账记录

**DELETE** `/api/records/:id`

需要鉴权。只能删除自己的记录。

**请求示例：**

```bash
curl -X DELETE http://localhost:3000/api/records/1 \
  -H 'Authorization: Bearer <token>'
```

**成功响应 (200)：**

```json
{ "data": { "message": "deleted" } }
```

**错误响应：**
- 403：非本人记录
- 404：记录不存在

---

### 8. 获取分类列表

**GET** `/api/categories`

无需鉴权。返回系统预设的所有分类。

**请求示例：**

```bash
curl http://localhost:3000/api/categories
```

**成功响应 (200)：**

```json
{
  "data": [
    { "id": 1, "name": "餐饮", "isIncome": 0 },
    { "id": 2, "name": "交通", "isIncome": 0 },
    { "id": 3, "name": "购物", "isIncome": 0 },
    { "id": 4, "name": "娱乐", "isIncome": 0 },
    { "id": 5, "name": "居住", "isIncome": 0 },
    { "id": 6, "name": "医疗", "isIncome": 0 },
    { "id": 7, "name": "教育", "isIncome": 0 },
    { "id": 8, "name": "其他支出", "isIncome": 0 },
    { "id": 9, "name": "工资", "isIncome": 1 },
    { "id": 10, "name": "兼职", "isIncome": 1 },
    { "id": 11, "name": "理财", "isIncome": 1 },
    { "id": 12, "name": "其他收入", "isIncome": 1 }
  ]
}
```
