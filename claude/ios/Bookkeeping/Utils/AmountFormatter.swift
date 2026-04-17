import Foundation

// MARK: - 金额转换（分 ↔ 元）

enum AmountFormatter {
    /// 分转元显示字符串，保留两位小数
    static func centsToYuan(_ cents: Int) -> String {
        return String(format: "%.2f", Double(cents) / 100.0)
    }

    /// 元字符串转分（四舍五入）
    static func yuanToCents(_ yuan: String) -> Int? {
        guard let value = Double(yuan), value > 0 else { return nil }
        return Int(round(value * 100))
    }
}
