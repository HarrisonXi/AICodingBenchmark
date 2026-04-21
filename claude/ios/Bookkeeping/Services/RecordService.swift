import Foundation

// MARK: - 记录 CRUD API

enum RecordService {
    /// 获取记录（支持分页和筛选）
    static func getRecords(
        page: Int = 1,
        pageSize: Int = 20,
        filters: RecordFilters = RecordFilters()
    ) async throws -> PaginatedResponse<BookRecord> {
        var query = "page=\(page)&pageSize=\(pageSize)"
        if let isIncome = filters.isIncome {
            query += "&isIncome=\(isIncome)"
        }
        if let categoryId = filters.categoryId {
            query += "&categoryId=\(categoryId)"
        }
        if let startDate = filters.startDate {
            query += "&startDate=\(startDate)"
        }
        if let endDate = filters.endDate {
            query += "&endDate=\(endDate)"
        }
        return try await APIClient.get(path: "/records?\(query)")
    }

    /// 获取单条记录
    static func getRecord(id: Int) async throws -> BookRecord {
        try await APIClient.get(path: "/records/\(id)")
    }

    /// 创建记录
    static func createRecord(_ payload: CreateRecordPayload) async throws -> BookRecord {
        try await APIClient.post(path: "/records", body: payload)
    }

    /// 更新记录
    static func updateRecord(id: Int, _ payload: CreateRecordPayload) async throws -> BookRecord {
        try await APIClient.put(path: "/records/\(id)", body: payload)
    }

    /// 删除记录
    static func deleteRecord(id: Int) async throws {
        let _: APIClient.DeleteResponse = try await APIClient.delete(path: "/records/\(id)")
    }
}
