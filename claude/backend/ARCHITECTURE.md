# 记账 App 后端 — 技术架构文档

## 技术选型

| 组件 | 选择 | 理由 |
|------|------|------|
| 运行时 | Node.js + TypeScript | 项目约束 |
| Web 框架 | Express 4 | 最成熟稳定的 Node.js 框架，中间件生态丰富 |
| ORM | Drizzle ORM | 类型安全、轻量、SQL-like API，原生支持 SQLite |
| 数据库 | SQLite (better-sqlite3) | 项目约束；同步 API 简化代码逻辑 |
| 输入校验 | Zod | TypeScript-first，可与 Drizzle 共享类型 |
| 鉴权 | jsonwebtoken + bcryptjs | JWT 标准实现 + 纯 JS bcrypt 无需编译 |
| 开发工具 | tsx watch | 快速 TypeScript 执行 + 热重载 |

## 项目结构

```
backend/
├── src/
│   ├── index.ts              # 入口：初始化数据库，启动服务器
│   ├── app.ts                # Express 应用：中间件注册 + 路由挂载
│   ├── config.ts             # 配置：从环境变量读取 PORT、JWT_SECRET 等
│   ├── db/
│   │   ├── schema.ts         # Drizzle 表定义（users, categories, records）
│   │   ├── index.ts          # 数据库连接 + 建表 + 初始化
│   │   └── seed.ts           # 分类种子数据
│   ├── middleware/
│   │   ├── auth.ts           # JWT 鉴权中间件 + AuthRequest 类型
│   │   └── validate.ts       # Zod 校验中间件工厂
│   ├── routes/
│   │   ├── auth.ts           # /api/auth — 注册、登录
│   │   ├── records.ts        # /api/records — 记账 CRUD（支持分页、筛选）
│   │   ├── categories.ts     # /api/categories — 分类查询
│   │   └── statistics.ts     # /api/statistics — 月度汇总、分类占比
│   └── utils/
│       └── errors.ts         # AppError 类 + 全局错误处理中间件
├── package.json
├── tsconfig.json
└── .env                      # 环境变量
```

## 数据库设计

### ER 关系

```
users 1──N records N──1 categories
```

### 表结构

**users** — 用户表
- `id` INTEGER PK — 自增主键
- `username` TEXT UNIQUE — 用户名（3-32 字符）
- `password_hash` TEXT — bcrypt 加密密码
- `created_at` TEXT — 创建时间 ISO 格式

**categories** — 分类表（系统预设，只读）
- `id` INTEGER PK — 自增主键
- `name` TEXT UNIQUE — 分类名
- `icon` TEXT — 分类图标（emoji 字符串）
- `is_income` INTEGER — 0=支出, 1=收入

**records** — 记账记录表
- `id` INTEGER PK — 自增主键
- `user_id` INTEGER FK → users.id — 所属用户
- `category_id` INTEGER FK → categories.id — 所属分类
- `is_income` INTEGER — 0=支出, 1=收入
- `amount` INTEGER — 金额（分为单位，避免浮点精度问题）
- `note` TEXT — 备注（可空）
- `date` TEXT — 记账日期 YYYY-MM-DD
- `created_at` TEXT — 创建时间 ISO 格式

### 设计决策

1. **金额用分为单位（整数）**：避免 JavaScript 浮点精度问题，前端显示时除以 100
2. **isIncome 用 0/1 而非字符串**：存储高效，SQLite 没有原生布尔类型
3. **日期用 TEXT 而非 INTEGER**：YYYY-MM-DD 格式可直接比较排序，可读性好
4. **时间戳用 ISO 字符串**：跨时区兼容，人类可读

## 代码规范

### 命名约定

- 文件名：`kebab-case.ts`
- TypeScript 变量/函数：`camelCase`
- 数据库列名：`snake_case`（Drizzle schema 中通过列名映射）
- 常量：`camelCase`（config 对象属性）

### 错误处理模式

```typescript
// 路由中使用 try-catch + next(err) 转发到全局处理器
router.post('/', (req, res, next) => {
  try {
    // 业务逻辑
    // 已知错误直接 res.status().json()
    // 未知错误 throw 或 next(err)
  } catch (err) {
    next(err);
  }
});
```

### 中间件使用

```typescript
// Zod 校验中间件 — 放在路由处理函数之前
router.post('/register', validate(registerSchema), handler);

// JWT 鉴权 — 可以按路由或按 Router 级别挂载
router.use(authMiddleware);  // Router 级别，该 Router 下所有路由都需要鉴权
```

### 统一响应格式

- 成功：`{ "data": ... }`
- 失败：`{ "error": { "code": "...", "message": "..." } }`
- 所有接口一致使用此格式，前端可统一处理

## 开发指南

### 启动项目

```bash
cd backend
npm install
npm run dev    # 开发模式（热重载）
```

首次启动自动建表并插入种子数据。

### 添加新路由

1. 在 `src/routes/` 下创建新路由文件
2. 定义 Zod schema 做输入校验
3. 使用 `validate()` 中间件
4. 需要鉴权的路由使用 `authMiddleware`
5. 在 `src/app.ts` 中注册路由

### 添加新表

1. 在 `src/db/schema.ts` 中添加 Drizzle 表定义
2. 在 `src/db/index.ts` 的 `initDatabase()` 中添加 CREATE TABLE 语句
3. 如需种子数据，在 `src/db/seed.ts` 中添加

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| PORT | 3000 | 服务端口 |
| JWT_SECRET | default-secret | JWT 签名密钥（生产环境必须更换） |

## 分类管理 + 统计 + 分页

- `GET /api/records` 支持分页参数（`page`, `pageSize`）和筛选（`startDate`, `endDate`, `categoryId`, `isIncome`）
- `GET /api/statistics/monthly` 按月查询收入/支出/结余
- `GET /api/statistics/by-category` 按分类查询占比
- 分类表增加 `icon` 字段（emoji 标识）
