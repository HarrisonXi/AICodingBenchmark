import Foundation

/// 记账记录
struct BookRecord: Codable {
    let id: Int
    let userId: Int
    let categoryId: Int
    let isIncome: Int   // 0=支出, 1=收入
    let amount: Int     // 单位：分
    let note: String?
    let date: String    // "YYYY-MM-DD"
    let createdAt: String
}
