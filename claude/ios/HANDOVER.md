# 记账本 iOS 客户端交接文档

## 快速启动

```bash
# 前提：后端已在 localhost:3000 运行
cd ios
open Bookkeeping.xcodeproj
# Xcode 中选择模拟器 → CMD+R 运行
```

---

## 一、项目结构与模块设计

### 技术栈

| 类别 | 选型 | 理由 |
|------|------|------|
| 语言 | Swift 5 | iOS 原生开发标准语言 |
| UI 框架 | UIKit | 需求指定，成熟稳定 |
| 架构 | MVC | 4 个页面，UIKit 原生模式足够 |
| 布局 | 纯代码 Auto Layout | 无 Storyboard/XIB，代码可审查 |
| 网络 | URLSession 封装 | ~80 行，对标前端 http.ts，无第三方依赖 |
| Token 存储 | Keychain | 安全存储 JWT，不用 UserDefaults |
| 依赖管理 | 无 | 零第三方依赖，全部使用 Apple 原生框架 |
| 最低版本 | iOS 15 | 使用 async/await |

### 目录结构

```
Bookkeeping/
  AppDelegate.swift              — 应用入口（标准模板）
  SceneDelegate.swift            — 窗口管理 + 根导航切换

  Models/
    AuthResponse.swift           — 登录/注册 API 响应模型
    Category.swift               — 分类模型
    BookRecord.swift             — 记账记录模型
    CreateRecordPayload.swift    — 创建/更新请求体
    APIErrorBody.swift           — API 错误响应信封

  Services/
    APIClient.swift              — HTTP 客户端核心（自动注入 token、401 拦截）
    AuthService.swift            — 登录/注册 API 调用
    RecordService.swift          — 记录 CRUD API 调用
    CategoryService.swift        — 分类 API 调用 + 内存缓存
    KeychainHelper.swift         — Keychain 安全存储封装
    AuthManager.swift            — 认证状态管理单例

  Utils/
    AmountFormatter.swift        — 金额单位转换（分 ↔ 元）
    DateHelper.swift             — 日期格式化（YYYY-MM-DD）
    UIHelpers.swift              — Auto Layout 扩展 + UI 工厂方法

  Controllers/
    LoginViewController.swift    — 登录页
    RegisterViewController.swift — 注册页
    RecordListViewController.swift — 记录列表主页（含 RecordCell）
    RecordFormViewController.swift — 新增/编辑记录表单页（含 CategoryCell）

  Assets.xcassets/               — 图标和颜色资源
  Info.plist                     — 应用配置
```

### 页面清单

| 页面 | 控制器 | 功能 | 需要登录 |
|------|--------|------|:--------:|
| 登录 | `LoginViewController` | 用户名密码登录 | 否 |
| 注册 | `RegisterViewController` | 用户名密码注册 | 否 |
| 记录列表 | `RecordListViewController` | 汇总卡片 + 记录列表 + CRUD | 是 |
| 记录表单 | `RecordFormViewController` | 新增/编辑记录 | 是 |

### 组件与 API 调用映射

| 控制器 | API 调用 | 触发时机 |
|--------|----------|----------|
| `LoginViewController` | `POST /api/auth/login` | 点击登录按钮 |
| `RegisterViewController` | `POST /api/auth/register` | 点击注册按钮 |
| `SceneDelegate` | `GET /api/categories` | 应用启动时 |
| `RecordListViewController` | `GET /api/records` | viewWillAppear / CRUD 后 |
| `RecordListViewController` | `DELETE /api/records/:id` | 左滑删除确认 |
| `RecordFormViewController` | `POST /api/records` | 新增保存 |
| `RecordFormViewController` | `PUT /api/records/:id` | 编辑保存 |

### 数据流向

```
用户操作 → ViewController 调用 Service 函数 → APIClient 封装 URLSession 请求
                                                 ↓
                                            自动注入 JWT token
                                                 ↓
                                         请求 http://localhost:3000/api
                                                 ↓
                                         解析响应 / 处理 401 跳转
```

---

## 二、技术设计与代码规范

### 认证流程

1. 启动 → `AuthManager.loadFromKeychain()` 恢复 token
2. 有 token → 进入记录列表页；无 token → 进入登录页
3. 登录/注册成功 → `AuthManager.setAuth()` 存 Keychain → 切换到列表页
4. 每次请求 → `APIClient` 自动从 `AuthManager.shared.token` 读取并注入 `Authorization` header
5. 收到 401 → `APIClient` 调用 `AuthManager.handleUnauthorized()` → 发送通知 →`SceneDelegate` 切到登录页
6. 手动退出 → `AuthManager.logout()` → 切到登录页

### 网络层设计（APIClient.swift）

对标前端 `http.ts`，约 80 行：

- 泛型 `request<T: Decodable>` 核心方法
- 自动注入 Bearer token
- 统一解包 `{ "data": T }` 响应信封
- 统一解析 `{ "error": { "code", "message" } }` 错误信封
- 401 拦截 → 调用 `AuthManager.handleUnauthorized()`
- 便捷方法：`get`, `post`, `put`, `delete`

### 分类管理策略

- `CategoryService.fetchCategories()` 应用启动时调用一次，内存缓存
- 提供 `expenseCategories()` / `incomeCategories()` 过滤方法
- 提供 `categoryName(for:)` 按 ID 查名称

### 金额处理

- 后端存分（整数），iOS 展示元（两位小数）
- `AmountFormatter.centsToYuan(_:)`: `String(format: "%.2f", Double(cents) / 100.0)`
- `AmountFormatter.yuanToCents(_:)`: `Int(round(value * 100))`
- 转换仅在两个位置：`RecordFormViewController`（输入→分）和 `RecordCell`/汇总（分→展示）

### 表单校验规则

| 页面 | 字段 | 规则 |
|------|------|------|
| 登录 | 用户名/密码 | 非空 |
| 注册 | 用户名 | 非空，3-32 字符 |
| 注册 | 密码 | 非空，6-64 字符 |
| 记录表单 | 金额 | 非空，正数 |
| 记录表单 | 分类 | 必选 |
| 记录表单 | 备注 | 可选，≤200 字（UITextField delegate 限制） |

### 错误处理

- 网络/解码错误 → 显示"网络错误，请稍后重试"
- API 业务错误 → 直接显示后端返回的 `message`
- 401 → APIClient 自动拦截，清 token 并跳转登录页

### 安全存储

- JWT token → Keychain（`KeychainHelper`，使用 Security 框架）
- 用户 ID/用户名 → UserDefaults（非敏感信息，仅展示用）
- Info.plist 配置了 `NSAllowsArbitraryLoads`，因为后端使用 HTTP

### 代码规范

- 纯代码布局，无 Storyboard/XIB
- 使用 `UIFactory` 工厂方法创建常用 UI 组件（减少重复代码）
- 使用 `UIView` 扩展简化 Auto Layout（`pinToEdges`, `centerIn`, `setSize`）
- ViewController 结构统一：UI 元素声明 → viewDidLoad → setupUI → setupActions → 校验 → 操作
- 异步操作使用 Swift async/await + Task
- 请求中禁用按钮并显示 loading 文案，防止重复提交

---

## 三、新增页面步骤

1. 在 `Controllers/` 新建 `XxxViewController.swift`
2. 在 Xcode 项目导航器中添加文件引用
3. 如需新 API，在 `Services/` 添加函数
4. 如需新模型，在 `Models/` 添加 Codable 结构体

### 新增 API 调用步骤

1. 在 `Models/` 添加请求/响应 Codable 结构体
2. 在 `Services/` 中新建或修改 Service 文件
3. 使用 `APIClient.get/post/put/delete` 便捷方法
4. 在 ViewController 中 `Task { }` 块内调用，catch `APIClient.APIError` 处理错误

---

## 四、已知限制

1. 后端 `GET /api/records` 无分页，数据量大时需加分页支持
2. JWT 无 refresh token，7 天后需重新登录
3. 无密码找回
4. 无离线缓存（每次需联网获取数据）
5. `NSAllowsArbitraryLoads` 仅适用开发环境，生产需配置 HTTPS
6. 未添加 XCTest 单元测试（建议为 AmountFormatter、DateHelper 添加）
