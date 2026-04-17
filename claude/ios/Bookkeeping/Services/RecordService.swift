import Foundation

// MARK: - 记录 CRUD API

enum RecordService {
    /// 获取全部记录（按日期倒序）
    static func getRecords() async throws -> [BookRecord] {
        try await APIClient.get(path: "/records")
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
