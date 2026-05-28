import Foundation

// MARK: - Currency Configuration

struct CurrencyInfo: Identifiable, Hashable {
    let id: String          // same as code
    let code: String
    let symbol: String
    let flag: String
    let name: String
    let useIndianFormat: Bool   // Indian: 1,00,000 = 1 lakh; Western: 100,000

    static let all: [CurrencyInfo] = [
        CurrencyInfo(id: "INR", code: "INR", symbol: "₹",   flag: "🇮🇳", name: "Indian Rupee",      useIndianFormat: true),
        CurrencyInfo(id: "USD", code: "USD", symbol: "$",   flag: "🇺🇸", name: "US Dollar",          useIndianFormat: false),
        CurrencyInfo(id: "EUR", code: "EUR", symbol: "€",   flag: "🇪🇺", name: "Euro",               useIndianFormat: false),
        CurrencyInfo(id: "GBP", code: "GBP", symbol: "£",   flag: "🇬🇧", name: "British Pound",      useIndianFormat: false),
        CurrencyInfo(id: "AED", code: "AED", symbol: "د.إ", flag: "🇦🇪", name: "UAE Dirham",         useIndianFormat: false),
        CurrencyInfo(id: "SGD", code: "SGD", symbol: "S$",  flag: "🇸🇬", name: "Singapore Dollar",   useIndianFormat: false),
        CurrencyInfo(id: "JPY", code: "JPY", symbol: "¥",   flag: "🇯🇵", name: "Japanese Yen",       useIndianFormat: false),
        CurrencyInfo(id: "AUD", code: "AUD", symbol: "A$",  flag: "🇦🇺", name: "Australian Dollar",  useIndianFormat: false),
        CurrencyInfo(id: "CAD", code: "CAD", symbol: "C$",  flag: "🇨🇦", name: "Canadian Dollar",    useIndianFormat: false),
    ]

    static var current: CurrencyInfo {
        let code = UserDefaults.standard.string(forKey: "currency_code") ?? "INR"
        return all.first { $0.code == code } ?? all[0]
    }
}

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

    var westernFormatted: String {
        if self < 0 { return "-" + (-self).westernFormatted }
        if self == 0 { return "0" }
        let s = String(self)
        var result = ""
        var count = 0
        for char in s.reversed() {
            if count > 0 && count % 3 == 0 { result = "," + result }
            result = String(char) + result
            count += 1
        }
        return result
    }
}

// MARK: - Currency-Aware Double Extensions

extension Double {
    // Full formatted with symbol: e.g. ₹1,23,456  /  $123,456
    var currencyFormatted: String {
        let cur = CurrencyInfo.current
        let rounded = (self * 100).rounded() / 100
        let intPart = Int(abs(rounded))
        let decPart = Int(((abs(rounded) - Double(intPart)) * 100).rounded())
        let sign    = rounded < 0 ? "-" : ""
        let numStr  = cur.useIndianFormat ? intPart.indianFormatted : intPart.westernFormatted
        let base    = cur.symbol + sign + numStr
        return decPart > 0 ? base + "." + String(format: "%02d", decPart) : base
    }

    // Without the currency symbol
    var currencyFormattedNoSymbol: String {
        let str    = currencyFormatted
        let symbol = CurrencyInfo.current.symbol
        return str.hasPrefix(symbol) ? String(str.dropFirst(symbol.count)) : str
    }

    // Compact: K / L / M / Cr depending on currency
    var currencyFormattedCompact: String {
        let abs = Swift.abs(self)
        let cur = CurrencyInfo.current
        let p   = self < 0 ? "-\(cur.symbol)" : cur.symbol
        if cur.useIndianFormat {
            switch abs {
            case 1_00_00_000...: return p + String(format: "%.1fCr", abs / 1_00_00_000)
            case 1_00_000...:   return p + String(format: "%.1fL",  abs / 1_00_000)
            case 1_000...:      return p + String(format: "%.1fK",  abs / 1_000)
            default:            return p + Int(abs).indianFormatted
            }
        } else {
            switch abs {
            case 1_000_000_000...: return p + String(format: "%.1fB", abs / 1_000_000_000)
            case 1_000_000...:    return p + String(format: "%.1fM", abs / 1_000_000)
            case 1_000...:        return p + String(format: "%.1fK", abs / 1_000)
            default:              return p + Int(abs).westernFormatted
            }
        }
    }

    // Legacy aliases (kept so old call sites still compile during refactor)
    var indianFormatted: String          { currencyFormatted }
    var indianFormattedNoSymbol: String  { currencyFormattedNoSymbol }
    var indianFormattedCompact: String   { currencyFormattedCompact }
}

// MARK: - Amount Input Formatting

struct AmountFormatter {
    static func format(digits: String) -> String {
        let cleaned = digits.filter { $0.isNumber }
        guard !cleaned.isEmpty else { return "" }
        let value = Int(cleaned) ?? 0
        return CurrencyInfo.current.useIndianFormat
            ? value.indianFormatted
            : value.westernFormatted
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
