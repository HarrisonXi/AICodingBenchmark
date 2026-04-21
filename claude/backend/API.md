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

需要鉴权。返回当前用户的记录，按日期降序排列，支持分页和筛选。

**Query 参数：**

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| page | number | 1 | 页码，≥1 |
| pageSize | number | 20 | 每页条数，1-100 |
| isIncome | 0 \| 1 | — | 按类型筛选：0=支出，1=收入 |
| categoryId | number | — | 按分类 ID 筛选 |
| startDate | string | — | 起始日期 YYYY-MM-DD（含） |
| endDate | string | — | 结束日期 YYYY-MM-DD（含） |

所有筛选条件可组合使用。

**请求示例：**

```bash
# 基本分页
curl 'http://localhost:3000/api/records?page=1&pageSize=10' \
  -H 'Authorization: Bearer <token>'

# 组合筛选：2026年4月的支出记录
curl 'http://localhost:3000/api/records?isIncome=0&startDate=2026-04-01&endDate=2026-04-30' \
  -H 'Authorization: Bearer <token>'

# 按分类筛选
curl 'http://localhost:3000/api/records?categoryId=1&page=1&pageSize=5' \
  -H 'Authorization: Bearer <token>'
```

**成功响应 (200)：**

```json
{
  "data": {
    "items": [
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
    ],
    "pagination": {
      "page": 1,
      "pageSize": 20,
      "total": 2,
      "totalPages": 1
    }
  }
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
    { "id": 1, "name": "餐饮", "icon": "🍽️", "isIncome": 0 },
    { "id": 2, "name": "交通", "icon": "🚗", "isIncome": 0 },
    { "id": 3, "name": "购物", "icon": "🛒", "isIncome": 0 },
    { "id": 4, "name": "娱乐", "icon": "🎮", "isIncome": 0 },
    { "id": 5, "name": "居住", "icon": "🏠", "isIncome": 0 },
    { "id": 6, "name": "医疗", "icon": "💊", "isIncome": 0 },
    { "id": 7, "name": "教育", "icon": "📚", "isIncome": 0 },
    { "id": 8, "name": "其他支出", "icon": "📦", "isIncome": 0 },
    { "id": 9, "name": "工资", "icon": "💰", "isIncome": 1 },
    { "id": 10, "name": "兼职", "icon": "🤝", "isIncome": 1 },
    { "id": 11, "name": "理财", "icon": "📈", "isIncome": 1 },
    { "id": 12, "name": "其他收入", "icon": "💵", "isIncome": 1 }
  ]
}
```

---

### 9. 月度收支汇总

**GET** `/api/statistics/monthly`

需要鉴权。查询指定月份的收入、支出、结余总额。

**Query 参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| month | string | 是 | YYYY-MM 格式 |

**请求示例：**

```bash
curl 'http://localhost:3000/api/statistics/monthly?month=2026-04' \
  -H 'Authorization: Bearer <token>'
```

**成功响应 (200)：**

```json
{
  "data": {
    "month": "2026-04",
    "income": 1000000,
    "expense": 52550,
    "balance": 947450
  }
}
```

**错误响应：**
- 400：month 参数缺失或格式错误

---

### 10. 按分类统计占比

**GET** `/api/statistics/by-category`

需要鉴权。查询指定月份各分类的金额和占比。

**Query 参数：**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| month | string | 是 | YYYY-MM 格式 |
| isIncome | 0 \| 1 | 否 | 默认 0（查支出） |

**请求示例：**

```bash
curl 'http://localhost:3000/api/statistics/by-category?month=2026-04&isIncome=0' \
  -H 'Authorization: Bearer <token>'
```

**成功响应 (200)：**

```json
{
  "data": {
    "month": "2026-04",
    "isIncome": 0,
    "total": 52550,
    "items": [
      { "categoryId": 1, "categoryName": "餐饮", "icon": "🍽️", "amount": 30000, "percentage": 57.09 },
      { "categoryId": 2, "categoryName": "交通", "icon": "🚗", "amount": 22550, "percentage": 42.91 }
    ]
  }
}
```

**字段说明：**
- `total`：该月该类型（收入/支出）的总金额（分）
- `percentage`：该分类占总额的百分比，保留两位小数
- `items`：按金额降序排列

**错误响应：**
- 400：month 参数缺失或格式错误、isIncome 值无效
