import Foundation

// MARK: - Indian Number Formatting

extension Int {
    var indianFormatted: String {
        if self < 0 { return "-" + (-self).indianFormatted }
        if self == 0 { return "0" }
        let s = String(self)
        guard s.count > 3 else { return s }

        var groups: [String] = []
        groups.append(String(s.suffix(3)))
        var remaining = String(s.dropLast(3))

        while remaining.count > 2 {
            groups.insert(String(remaining.suffix(2)), at: 0)
            remaining = String(remaining.dropLast(2))
        }
        if !remaining.isEmpty { groups.insert(remaining, at: 0) }

        return groups.joined(separator: ",")
    }
}

extension Double {
    var indianFormatted: String {
        let rounded = (self * 100).rounded() / 100
        let intPart = Int(abs(rounded))
        let decPart = Int(((abs(rounded) - Double(intPart)) * 100).rounded())
        let prefix = rounded < 0 ? "-" : ""
        let formatted = prefix + intPart.indianFormatted
        if decPart > 0 {
            return "₹" + formatted + "." + String(format: "%02d", decPart)
        }
        return "₹" + formatted
    }

    var indianFormattedNoSymbol: String {
        let str = indianFormatted
        return str.hasPrefix("₹") ? String(str.dropFirst()) : str
    }

    var indianFormattedCompact: String {
        let abs = Swift.abs(self)
        let prefix = self < 0 ? "-₹" : "₹"
        switch abs {
        case 1_00_00_000...:
            return prefix + String(format: "%.1fCr", abs / 1_00_00_000)
        case 1_00_000...:
            return prefix + String(format: "%.1fL", abs / 1_00_000)
        case 1_000...:
            return prefix + String(format: "%.1fK", abs / 1_000)
        default:
            return prefix + Int(abs).indianFormatted
        }
    }
}

// MARK: - Amount Input Formatting

struct AmountFormatter {
    static func format(digits: String) -> String {
        let cleaned = digits.filter { $0.isNumber }
        guard !cleaned.isEmpty else { return "" }
        let value = Int(cleaned) ?? 0
        return value.indianFormatted
    }

    static func toDouble(from formattedString: String) -> Double {
        let cleaned = formattedString.filter { $0.isNumber || $0 == "." }
        return Double(cleaned) ?? 0
    }

    static func toDoubleFromDigits(_ digits: String) -> Double {
        let cleaned = digits.filter { $0.isNumber }
        return Double(cleaned) ?? 0
    }
}

// MARK: - Date Formatting

struct VaultDateFormatter {
    static let display: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    static let short: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM"
        return f
    }()

    static let yearShort: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd MMM yy"
        return f
    }()

    static let full: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f
    }()

    static let backupTimestamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }()

    static func relativeDate(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date)     { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let days = cal.dateComponents([.day], from: date, to: Date()).day ?? 0
        if days < 7 { return "\(days)d ago" }
        return short.string(from: date)
    }

    static func daysRemaining(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days < 0   { return "Overdue by \(-days)d" }
        if days == 0  { return "Today!" }
        if days == 1  { return "Tomorrow" }
        if days < 30  { return "\(days) days" }
        let months = Calendar.current.dateComponents([.month], from: Date(), to: date).month ?? 0
        if months < 12 { return "\(months) mo" }
        let years = Calendar.current.dateComponents([.year], from: Date(), to: date).year ?? 0
        return "\(years) yr"
    }
}
