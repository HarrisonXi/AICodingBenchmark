import { get } from '@/utils/http'
import type { MonthlyStatistics, CategoryBreakdown } from '@/types/api'

export function getMonthlyStatistics(month: string): Promise<MonthlyStatistics> {
  return get<MonthlyStatistics>(`/api/statistics/monthly?month=${month}`)
}

export function getCategoryBreakdown(month: string, isIncome: 0 | 1 = 0): Promise<CategoryBreakdown> {
  return get<CategoryBreakdown>(`/api/statistics/by-category?month=${month}&isIncome=${isIncome}`)
}
