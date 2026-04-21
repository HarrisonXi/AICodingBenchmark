import Foundation

// MARK: - 统计相关模型

/// 月度汇总
struct MonthlyStatistics: Decodable {
    let month: String
    let income: Int    // 分
    let expense: Int   // 分
    let balance: Int   // 分
}

/// 分类明细项
struct CategoryBreakdownItem: Decodable {
    let categoryId: Int
    let categoryName: String
    let amount: Int       // 分
    let percentage: Double // 0-100
}

/// 分类明细
struct CategoryBreakdown: Decodable {
    let month: String
    let isIncome: Int
    let total: Int  // 分
    let items: [CategoryBreakdownItem]
}

/// 分页信息
struct Pagination: Decodable {
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int
}

/// 分页响应（泛型）
struct PaginatedResponse<T: Decodable>: Decodable {
    let items: [T]
    let pagination: Pagination
}

/// 记录筛选参数
struct RecordFilters {
    var isIncome: Int?
    var categoryId: Int?
    var startDate: String?
    var endDate: String?
}
