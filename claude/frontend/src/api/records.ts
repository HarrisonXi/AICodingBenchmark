import { get, post, put, del } from '@/utils/http'
import type { BookRecord, CreateRecordPayload, PaginatedResponse } from '@/types/api'

export function getRecords(params?: {
  page?: number
  pageSize?: number
  isIncome?: 0 | 1
  categoryId?: number
  startDate?: string
  endDate?: string
}): Promise<PaginatedResponse<BookRecord>> {
  const query = new URLSearchParams()
  if (params?.page != null) query.set('page', String(params.page))
  if (params?.pageSize != null) query.set('pageSize', String(params.pageSize))
  if (params?.isIncome != null) query.set('isIncome', String(params.isIncome))
  if (params?.categoryId != null) query.set('categoryId', String(params.categoryId))
  if (params?.startDate) query.set('startDate', params.startDate)
  if (params?.endDate) query.set('endDate', params.endDate)
  const qs = query.toString()
  return get<PaginatedResponse<BookRecord>>(`/api/records${qs ? '?' + qs : ''}`)
}

export function getRecord(id: number): Promise<BookRecord> {
  return get<BookRecord>(`/api/records/${id}`)
}

export function createRecord(data: CreateRecordPayload): Promise<BookRecord> {
  return post<BookRecord>('/api/records', data)
}

export function updateRecord(id: number, data: Partial<CreateRecordPayload>): Promise<BookRecord> {
  return put<BookRecord>(`/api/records/${id}`, data)
}

export function deleteRecord(id: number): Promise<{ message: string }> {
  return del<{ message: string }>(`/api/records/${id}`)
}
