import Foundation

// MARK: - 统计 API

enum StatisticsService {
    /// 获取月度汇总
    static func getMonthlyStatistics(month: String) async throws -> MonthlyStatistics {
        try await APIClient.get(path: "/statistics/monthly?month=\(month)")
    }

    /// 获取分类明细
    static func getCategoryBreakdown(month: String, isIncome: Int = 0) async throws -> CategoryBreakdown {
        try await APIClient.get(path: "/statistics/by-category?month=\(month)&isIncome=\(isIncome)")
    }
}
