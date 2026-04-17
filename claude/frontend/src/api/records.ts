import { get, post, put, del } from '@/utils/http'
import type { BookRecord, CreateRecordPayload } from '@/types/api'

export function getRecords(): Promise<BookRecord[]> {
  return get<BookRecord[]>('/api/records')
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
