import Foundation

struct Transaction: Identifiable, Codable, Hashable {
    let id: UUID
    let date: Date
    var amount: Double
    var type: TransactionType
    var note: String
    var linkedItemID: UUID?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        amount: Double,
        type: TransactionType,
        note: String = "",
        linkedItemID: UUID? = nil
    ) {
        self.id = id
        self.date = date
        self.amount = amount
        self.type = type
        self.note = note
        self.linkedItemID = linkedItemID
    }

    enum TransactionType: String, Codable, CaseIterable {
        case inward    = "inward"
        case outward   = "outward"
        case assign    = "assign"
        case unassign  = "unassign"

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

        // Semantic color: red = money leaving goals or wallet; green = money entering
        var isRedAction: Bool {
            switch self {
            case .outward, .unassign: return true
            case .inward, .assign:    return false
            }
        }

        var affectsBalance: Bool {
            switch self {
            case .inward, .outward: return true
            case .assign, .unassign: return false
            }
        }
    }
}

// MARK: - Sample Data

extension Transaction {
    static var samples: [Transaction] {
        let now = Date()
        return [
            Transaction(date: now.addingTimeInterval(-86400 * 0), amount: 85000, type: .inward,  note: "Salary"),
            Transaction(date: now.addingTimeInterval(-86400 * 2), amount: 12000, type: .assign,  note: "Assigned to MacBook"),
            Transaction(date: now.addingTimeInterval(-86400 * 4), amount: 3500,  type: .outward, note: "Groceries"),
            Transaction(date: now.addingTimeInterval(-86400 * 7), amount: 50000, type: .inward,  note: "Freelance Project"),
            Transaction(date: now.addingTimeInterval(-86400 * 9), amount: 8000,  type: .assign,  note: "Assigned to Trip Fund"),
        ]
    }
}
