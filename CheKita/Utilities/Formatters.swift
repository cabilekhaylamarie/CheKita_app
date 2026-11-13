import Foundation

enum Fmt {
    private static let currencyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        f.groupingSeparator = ","
        f.groupingSize = 3
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.numberStyle = .decimal
        f.usesGroupingSeparator = false
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 2
        return f
    }()

    private static let longDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMMM d, yyyy"
        return f
    }()

    private static let fileDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// ₱2,450.00
    static func peso(_ value: Double) -> String {
        let v = value.isFinite ? value : 0
        let body = currencyFormatter.string(from: NSNumber(value: abs(v))) ?? String(format: "%.2f", abs(v))
        return (v < 0 ? "-₱" : "₱") + body
    }

    /// Uses three decimals for tiny per-gram costs (₱0.045).
    static func unitCost(_ value: Double) -> String {
        if value > 0 && value < 1 { return "₱" + String(format: "%.3f", value) }
        return peso(value)
    }

    /// 200, 0.5, 1.25 (no trailing zeros)
    static func number(_ value: Double) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    static func percent(_ value: Double) -> String { "\(number(value)) %" }

    static func longDate(_ date: Date) -> String { longDateFormatter.string(from: date) }

    static func fileDate(_ date: Date) -> String { fileDateFormatter.string(from: date) }

    /// Lenient decimal parsing for user input.
    static func parse(_ text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "₱", with: "")
            .replacingOccurrences(of: "%", with: "")
            .trimmed
        guard !cleaned.isEmpty, let value = Double(cleaned), value.isFinite else { return nil }
        return value
    }

    /// Whole, non-negative numbers only.
    static func parseInt(_ text: String) -> Int? {
        guard let value = parse(text), value >= 0, value == value.rounded(), value < 1_000_000_000 else { return nil }
        return Int(value)
    }
}
