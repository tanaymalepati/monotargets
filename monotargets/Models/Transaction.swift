import Foundation

struct Transaction: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    var amount: Double
    var type: TransactionType
    var note: String
    var linkedItemID: UUID?
    var category: Category?
    // New expense-tracking fields (all optional — backward compat)
    var payee: String?
    var paymentMethod: PaymentMethod?
    var tags: [String]
    var isRecurring: Bool
    var recurringPeriod: RecurringPeriod?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double,
        type: TransactionType,
        note: String = "",
        linkedItemID: UUID? = nil,
        category: Category? = nil,
        payee: String? = nil,
        paymentMethod: PaymentMethod? = nil,
        tags: [String] = [],
        isRecurring: Bool = false,
        recurringPeriod: RecurringPeriod? = nil
    ) {
        self.id              = id
        self.date            = date
        self.amount          = amount
        self.type            = type
        self.note            = note
        self.linkedItemID    = linkedItemID
        self.category        = category
        self.payee           = payee
        self.paymentMethod   = paymentMethod
        self.tags            = tags
        self.isRecurring     = isRecurring
        self.recurringPeriod = recurringPeriod
    }

    // Backward-compatible decoding
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self,            forKey: .id)
        date            = try c.decode(Date.self,            forKey: .date)
        amount          = try c.decode(Double.self,          forKey: .amount)
        type            = try c.decode(TransactionType.self, forKey: .type)
        note            = try c.decode(String.self,          forKey: .note)
        linkedItemID    = try c.decodeIfPresent(UUID.self,   forKey: .linkedItemID)
        category        = try c.decodeIfPresent(Category.self,       forKey: .category)
        payee           = try c.decodeIfPresent(String.self,         forKey: .payee)
        paymentMethod   = try c.decodeIfPresent(PaymentMethod.self,  forKey: .paymentMethod)
        tags            = try c.decodeIfPresent([String].self,       forKey: .tags)            ?? []
        isRecurring     = try c.decodeIfPresent(Bool.self,           forKey: .isRecurring)     ?? false
        recurringPeriod = try c.decodeIfPresent(RecurringPeriod.self, forKey: .recurringPeriod)
    }

    // MARK: - Transaction Type

    enum TransactionType: String, Codable, CaseIterable {
        case inward   = "inward"
        case outward  = "outward"
        case assign   = "assign"
        case unassign = "unassign"

        var label: String {
            switch self {
            case .inward:   return "Money In"
            case .outward:  return "Money Out"
            case .assign:   return "Assigned"
            case .unassign: return "Unassigned"
            }
        }
        var symbol: String {
            switch self {
            case .inward:   return "arrow.down.circle.fill"
            case .outward:  return "arrow.up.circle.fill"
            case .assign:   return "arrow.right.circle.fill"
            case .unassign: return "arrow.left.circle.fill"
            }
        }
        var isDebit: Bool {
            switch self {
            case .inward, .unassign: return false
            case .outward, .assign:  return true
            }
        }
        var isRedAction: Bool {
            switch self {
            case .outward, .unassign: return true
            case .inward, .assign:    return false
            }
        }
        var affectsBalance: Bool {
            switch self {
            case .inward, .outward:  return true
            case .assign, .unassign: return false
            }
        }
    }

    // MARK: - Category

    enum Category: String, Codable, CaseIterable, Identifiable {
        case salary        = "salary"
        case freelance     = "freelance"
        case food          = "food"
        case transport     = "transport"
        case shopping      = "shopping"
        case entertainment = "entertainment"
        case health        = "health"
        case bills         = "bills"
        case travel        = "travel"
        case education     = "education"
        case investment    = "investment"
        case other         = "other"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .salary:        return "Salary"
            case .freelance:     return "Freelance"
            case .food:          return "Food"
            case .transport:     return "Transport"
            case .shopping:      return "Shopping"
            case .entertainment: return "Fun"
            case .health:        return "Health"
            case .bills:         return "Bills"
            case .travel:        return "Travel"
            case .education:     return "Education"
            case .investment:    return "Investment"
            case .other:         return "Other"
            }
        }

        var icon: String {
            switch self {
            case .salary:        return "briefcase.fill"
            case .freelance:     return "laptopcomputer"
            case .food:          return "fork.knife"
            case .transport:     return "car.fill"
            case .shopping:      return "bag.fill"
            case .entertainment: return "gamecontroller.fill"
            case .health:        return "heart.fill"
            case .bills:         return "bolt.fill"
            case .travel:        return "airplane"
            case .education:     return "graduationcap.fill"
            case .investment:    return "chart.line.uptrend.xyaxis"
            case .other:         return "ellipsis.circle.fill"
            }
        }

        var isIncome: Bool {
            switch self {
            case .salary, .freelance, .investment: return true
            default: return false
            }
        }
    }

    // MARK: - Payment Method

    enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
        case cash       = "cash"
        case card       = "card"
        case upi        = "upi"
        case netBanking = "netBanking"
        case wallet     = "wallet"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .cash:       return "Cash"
            case .card:       return "Card"
            case .upi:        return "UPI"
            case .netBanking: return "Net Banking"
            case .wallet:     return "Wallet"
            }
        }

        var icon: String {
            switch self {
            case .cash:       return "banknote"
            case .card:       return "creditcard.fill"
            case .upi:        return "indianrupeesign.circle.fill"
            case .netBanking: return "building.columns.fill"
            case .wallet:     return "wallet.pass.fill"
            }
        }
    }

    // MARK: - Recurring Period

    enum RecurringPeriod: String, Codable, CaseIterable, Identifiable {
        case daily   = "daily"
        case weekly  = "weekly"
        case monthly = "monthly"
        case yearly  = "yearly"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .daily:   return "Daily"
            case .weekly:  return "Weekly"
            case .monthly: return "Monthly"
            case .yearly:  return "Yearly"
            }
        }

        var icon: String {
            switch self {
            case .daily:   return "sun.max.fill"
            case .weekly:  return "calendar.badge.clock"
            case .monthly: return "calendar"
            case .yearly:  return "calendar.circle.fill"
            }
        }
    }
}

// MARK: - Sample Data

extension Transaction {
    static var samples: [Transaction] {
        let now = Date()
        return [
            Transaction(date: now.addingTimeInterval(-86400 * 0), amount: 85000, type: .inward,  note: "Salary",           category: .salary,  payee: "Employer",  paymentMethod: .netBanking),
            Transaction(date: now.addingTimeInterval(-86400 * 2), amount: 12000, type: .assign,  note: "Assigned to MacBook"),
            Transaction(date: now.addingTimeInterval(-86400 * 4), amount: 3500,  type: .outward, note: "Groceries",         category: .food,    payee: "Zepto",     paymentMethod: .upi,        tags: ["essentials"]),
            Transaction(date: now.addingTimeInterval(-86400 * 7), amount: 50000, type: .inward,  note: "Freelance Project", category: .freelance, payee: "Client",  paymentMethod: .netBanking),
            Transaction(date: now.addingTimeInterval(-86400 * 9), amount: 8000,  type: .assign,  note: "Assigned to Trip Fund"),
        ]
    }
}
