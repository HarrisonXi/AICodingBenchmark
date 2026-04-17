import Foundation

// MARK: - 日期工具

enum DateHelper {
    private static let formatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    /// 今天的日期字符串 "YYYY-MM-DD"
    static func today() -> String {
        return formatter.string(from: Date())
    }

    /// Date → "YYYY-MM-DD"
    static func formatDate(_ date: Date) -> String {
        return formatter.string(from: date)
    }

    /// "YYYY-MM-DD" → Date
    static func parseDate(_ string: String) -> Date? {
        return formatter.date(from: string)
    }
}
