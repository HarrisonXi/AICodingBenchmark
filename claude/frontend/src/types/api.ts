// 用户认证响应
export interface AuthResponse {
  id: number
  username: string
  token: string
}

// 分类
export interface Category {
  id: number
  name: string
  isIncome: number // 0=支出, 1=收入
}

// 记账记录
export interface BookRecord {
  id: number
  userId: number
  categoryId: number
  isIncome: number // 0=支出, 1=收入
  amount: number // 单位：分
  note: string | null
  date: string // YYYY-MM-DD
  createdAt: string // ISO datetime
}

// 创建记录请求
export interface CreateRecordPayload {
  amount: number // 单位：分
  isIncome: 0 | 1
  categoryId: number
  note?: string
  date?: string // YYYY-MM-DD
}

// API 错误响应
export interface ApiErrorBody {
  error: {
    code: string
    message: string
  }
}
