import Foundation

/// 分类（系统预设，只读）
struct Category: Codable {
    let id: Int
    let name: String
    let isIncome: Int  // 0=支出, 1=收入
}
