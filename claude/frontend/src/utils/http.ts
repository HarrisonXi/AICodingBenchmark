import type { ApiErrorBody } from '@/types/api'

const TOKEN_KEY = 'bookkeeping_token'

export class ApiError extends Error {
  code: string
  status: number

  constructor(status: number, code: string, message: string) {
    super(message)
    this.status = status
    this.code = code
  }
}

function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

async function request<T>(url: string, options: RequestInit = {}): Promise<T> {
  const token = getToken()
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...((options.headers as Record<string, string>) || {}),
  }
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  const res = await fetch(url, { ...options, headers })

  if (!res.ok) {
    // 尝试解析错误响应
    let code = 'UNKNOWN_ERROR'
    let message = `请求失败 (${res.status})`
    try {
      const body: ApiErrorBody = await res.json()
      code = body.error.code
      message = body.error.message
    } catch {
      // 非 JSON 响应，使用默认错误信息
    }

    // 401 自动清除 token 并跳转登录
    if (res.status === 401) {
      localStorage.removeItem(TOKEN_KEY)
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    }

    throw new ApiError(res.status, code, message)
  }

  const json = await res.json()
  return json.data as T
}

export function get<T>(url: string): Promise<T> {
  return request<T>(url)
}

export function post<T>(url: string, body: unknown): Promise<T> {
  return request<T>(url, {
    method: 'POST',
    body: JSON.stringify(body),
  })
}

export function put<T>(url: string, body: unknown): Promise<T> {
  return request<T>(url, {
    method: 'PUT',
    body: JSON.stringify(body),
  })
}

export function del<T>(url: string): Promise<T> {
  return request<T>(url, { method: 'DELETE' })
}
