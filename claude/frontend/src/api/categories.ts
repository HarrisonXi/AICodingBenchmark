import { get } from '@/utils/http'
import type { Category } from '@/types/api'

export function getCategories(): Promise<Category[]> {
  return get<Category[]>('/api/categories')
}
