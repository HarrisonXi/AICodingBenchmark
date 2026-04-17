import Foundation

// MARK: - 分类 API + 内存缓存

enum CategoryService {
    private static var cached: [Category]?

    /// 获取全部分类（有缓存直接返回）
    static func fetchCategories() async throws -> [Category] {
        if let cached = cached { return cached }
        let categories: [Category] = try await APIClient.get(path: "/categories")
        cached = categories
        return categories
    }

    /// 支出分类
    static func expenseCategories() -> [Category] {
        return cached?.filter { $0.isIncome == 0 } ?? []
    }

    /// 收入分类
    static func incomeCategories() -> [Category] {
        return cached?.filter { $0.isIncome == 1 } ?? []
    }

    /// 根据 ID 查分类名
    static func categoryName(for id: Int) -> String {
        return cached?.first(where: { $0.id == id })?.name ?? "未知"
    }

    /// 根据 ID 查是否收入
    static func isIncome(for id: Int) -> Bool {
        return cached?.first(where: { $0.id == id })?.isIncome == 1
    }

    /// 清除缓存
    static func clearCache() {
        cached = nil
    }
}
