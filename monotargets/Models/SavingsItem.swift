import Foundation

struct SavingsItem: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date
    var name: String
    var itemDescription: String
    var icon: String
    var targetAmount: Double
    var assignedAmount: Double
    var targetDate: Date?
    var isCompleted: Bool
    var sortOrder: Int
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        name: String,
        itemDescription: String = "",
        icon: String = "square.stack.3d.up",
        targetAmount: Double,
        assignedAmount: Double = 0,
        targetDate: Date? = nil,
        isCompleted: Bool = false,
        sortOrder: Int = 0,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.itemDescription = itemDescription
        self.icon = icon
        self.targetAmount = targetAmount
        self.assignedAmount = assignedAmount
        self.targetDate = targetDate
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.isFavorite = isFavorite
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self,   forKey: .id)
        createdAt      = try c.decode(Date.self,   forKey: .createdAt)
        name           = try c.decode(String.self, forKey: .name)
        itemDescription = try c.decode(String.self, forKey: .itemDescription)
        icon           = try c.decode(String.self, forKey: .icon)
        targetAmount   = try c.decode(Double.self, forKey: .targetAmount)
        assignedAmount = try c.decode(Double.self, forKey: .assignedAmount)
        targetDate     = try c.decodeIfPresent(Date.self, forKey: .targetDate)
        isCompleted    = try c.decode(Bool.self,   forKey: .isCompleted)
        sortOrder      = try c.decode(Int.self,    forKey: .sortOrder)
        isFavorite     = try c.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }

    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return min(assignedAmount / targetAmount, 1.0)
    }

    var remaining: Double {
        max(targetAmount - assignedAmount, 0)
    }

    var isFullyFunded: Bool {
        assignedAmount >= targetAmount
    }

    var daysUntilTarget: Int? {
        guard let date = targetDate else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        return days
    }

    var targetDateStatus: TargetDateStatus {
        guard let days = daysUntilTarget else { return .noDate }
        if isCompleted { return .completed }
        if days < 0    { return .overdue }
        if days <= 30  { return .soon }
        return .onTrack
    }

    enum TargetDateStatus {
        case noDate, onTrack, soon, overdue, completed
    }
}

// MARK: - Sample Data

extension SavingsItem {
    static var samples: [SavingsItem] {
        [
            SavingsItem(
                name: "MacBook Pro",
                itemDescription: "M4 Pro 16-inch for work",
                icon: "laptopcomputer",
                targetAmount: 250000,
                assignedAmount: 82000,
                targetDate: Calendar.current.date(byAdding: .month, value: 6, to: Date())
            ),
            SavingsItem(
                name: "Europe Trip",
                itemDescription: "Two weeks in Italy & France",
                icon: "airplane",
                targetAmount: 180000,
                assignedAmount: 41000,
                targetDate: Calendar.current.date(byAdding: .month, value: 9, to: Date())
            ),
            SavingsItem(
                name: "Emergency Fund",
                itemDescription: "6 months of expenses",
                icon: "shield.fill",
                targetAmount: 300000,
                assignedAmount: 195000,
                targetDate: nil
            ),
        ]
    }
}
