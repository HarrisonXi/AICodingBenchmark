# 记账本前端交接文档

## 快速启动

```bash
# 前提：后端已在 localhost:3000 运行
cd frontend
npm install
npm run dev
# 访问 http://localhost:5173
```

---

## 一、页面结构与组件设计

### 页面清单

| 路径 | 页面组件 | 功能 | 鉴权 |
|------|----------|------|:----:|
| `/login` | `LoginPage.vue` | 用户登录 | 否 |
| `/register` | `RegisterPage.vue` | 用户注册 | 否 |
| `/` | `HomePage.vue` | 记录列表、汇总、CRUD 操作 | 是 |

### 组件层级

```
App.vue
├── AppHeader.vue          — 仅登录后显示（标题 + 用户名 + 退出按钮）
└── <router-view>
    ├── LoginPage.vue       — 登录表单 + "去注册"链接
    ├── RegisterPage.vue    — 注册表单 + "去登录"链接
    └── HomePage.vue        — 核心页面
        ├── 汇总卡片（收入/支出/结余）
        ├── RecordItem.vue × N  — 单条记录（分类、金额、日期、备注、编辑/删除）
        ├── RecordForm.vue      — 新增/编辑模态表单
        ├── ConfirmDialog.vue   — 删除确认弹窗
        └── FAB 新增按钮
```

### 组件与 API 调用映射

| 组件 | API 调用 | 触发时机 |
|------|----------|----------|
| `LoginPage` | `POST /api/auth/login` | 提交登录表单 |
| `RegisterPage` | `POST /api/auth/register` | 提交注册表单 |
| `App.vue` | `GET /api/categories` | 应用挂载时 |
| `HomePage` | `GET /api/records` | 页面挂载 / 增删改后刷新 |
| `RecordForm` → `HomePage` | `POST /api/records` | 保存新记录 |
| `RecordForm` → `HomePage` | `PUT /api/records/:id` | 保存编辑 |
| `ConfirmDialog` → `HomePage` | `DELETE /api/records/:id` | 确认删除 |

### 数据流向

```
用户操作 → 组件 emit 事件 → HomePage 调用 api 函数 → http.ts 封装 fetch 请求
                                                      ↓
                                                 自动注入 JWT token
                                                      ↓
                                              Vite dev proxy 转发到后端
                                                      ↓
                                              解析响应 / 处理 401 跳转
```

---

## 二、技术设计与代码规范

### 技术栈

| 类别 | 选型 | 理由 |
|------|------|------|
| 构建 | Vite | Vue 3 标配，HMR 快 |
| UI | 无外部库 | 仅 3 页面，手写 CSS 更轻（总 CSS < 10KB） |
| 状态管理 | Pinia | Vue 3 官方方案，轻量 |
| CSS | Vue scoped styles + CSS 变量 | 零依赖，样式隔离 |
| HTTP | 原生 fetch 封装 | ~50 行代码，无需 axios |
| 路由 | vue-router 4 | 官方路由 + navigation guard |
| 校验 | useFormValidation composable | 3 个简单表单，不需要库 |

### 目录约定

```
src/
  api/         — API 调用函数，每个后端资源一个文件
  stores/      — Pinia store，仅放需要跨组件共享的状态
  composables/ — Vue composable（可复用逻辑）
  components/  — 可复用 UI 组件
  pages/       — 路由页面组件
  types/       — TypeScript 类型定义
  utils/       — 纯函数工具
  styles/      — 全局 CSS（变量 + reset）
  router/      — 路由配置
```

### 状态管理策略

- **auth store**：token + 用户信息，持久化到 localStorage
- **categories store**：分类列表，应用启动时拉取一次，内存缓存
- **records**：不放 store，仅 HomePage 本地 `ref` 管理（只有一个页面用到）

### 金额处理

- 后端存分（整数），前端展示元（两位小数）
- 转换仅在两个位置：`RecordForm`（输入→分）和 `format.ts`（分→展示）
- `yuanToCents()`: `Math.round(parseFloat(value) * 100)`
- `centsToYuan()`: `(cents / 100).toFixed(2)`

### 鉴权机制

1. 登录/注册成功 → token 存入 Pinia + localStorage
2. `http.ts` 每次请求自动读取 token 注入 `Authorization: Bearer` header
3. `router/index.ts` beforeEach 守卫：未登录访问受保护路由 → 跳 `/login`
4. `http.ts` 收到 401 → 清除 token + 强制跳转 `/login`
5. JWT 有效期 7 天，无 refresh token

### 样式规范

- 所有颜色、间距、圆角等统一通过 CSS 变量定义（`styles/variables.css`）
- 组件样式使用 `<style scoped>`，避免全局污染
- 金额颜色：收入 `--color-income`（绿），支出 `--color-expense`（红）
- 最大内容宽度 `--max-width: 640px`，居中显示

### 新增页面的步骤

1. 在 `src/pages/` 新建 `XxxPage.vue`
2. 在 `router/index.ts` 添加路由（设置 meta.requiresAuth）
3. 如需新 API，在 `src/api/` 添加函数
4. 如需共享状态，在 `src/stores/` 添加 store

### 新增 API 调用的步骤

1. 在 `src/types/api.ts` 添加请求/响应类型
2. 在 `src/api/` 对应文件添加函数（使用 `http.ts` 的 get/post/put/del）
3. 在组件中调用，catch `ApiError` 处理错误

### 生产构建

```bash
npm run build    # 输出到 dist/
```

生产环境需配置反向代理将 `/api` 转发到后端服务。

---

## 三、已知限制

1. 后端 `GET /api/records` 无分页，返回全部记录。数据量大时需后端加分页支持。
2. 无 JWT refresh token，7 天后需重新登录。
3. 无密码找回功能。
4. 前端过滤/搜索需自行实现（后端无筛选参数）。
