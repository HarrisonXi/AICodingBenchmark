import Foundation

/// 创建/更新记录请求体
struct CreateRecordPayload: Encodable {
    let amount: Int       // 单位：分
    let isIncome: Int     // 0 或 1
    let categoryId: Int
    var note: String?
    var date: String?     // "YYYY-MM-DD"
}
