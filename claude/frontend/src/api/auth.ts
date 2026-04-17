import { post } from '@/utils/http'
import type { AuthResponse } from '@/types/api'

export function register(username: string, password: string): Promise<AuthResponse> {
  return post<AuthResponse>('/api/auth/register', { username, password })
}

export function login(username: string, password: string): Promise<AuthResponse> {
  return post<AuthResponse>('/api/auth/login', { username, password })
}
