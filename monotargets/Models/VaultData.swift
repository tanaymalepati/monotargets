import Foundation

struct VaultData: Codable {
    var transactions: [Transaction]
    var savingsItems: [SavingsItem]
    var backupFolderBookmark: Data?
    var createdAt: Date
    var version: Int

    // Gamification state
    var earnedAchievements: [String]          // achievement IDs
    var streakCount: Int                      // current daily streak
    var lastStreakDate: Date?                 // last date streak was updated
    var longestStreak: Int                   // all-time best streak
    var budgets: [Budget]                    // per-category monthly limits
    var activeChallenges: [ActiveChallenge]  // currently joined challenges
    var dismissedWeeklyRecap: Date?          // date of last dismissed recap

    init(
        transactions: [Transaction] = [],
        savingsItems: [SavingsItem] = [],
        backupFolderBookmark: Data? = nil,
        earnedAchievements: [String] = [],
        streakCount: Int = 0,
        lastStreakDate: Date? = nil,
        longestStreak: Int = 0,
        budgets: [Budget] = [],
        activeChallenges: [ActiveChallenge] = [],
        dismissedWeeklyRecap: Date? = nil
    ) {
        self.transactions          = transactions
        self.savingsItems          = savingsItems
        self.backupFolderBookmark  = backupFolderBookmark
        self.createdAt             = Date()
        self.version               = 2
        self.earnedAchievements    = earnedAchievements
        self.streakCount           = streakCount
        self.lastStreakDate        = lastStreakDate
        self.longestStreak         = longestStreak
        self.budgets               = budgets
        self.activeChallenges      = activeChallenges
        self.dismissedWeeklyRecap  = dismissedWeeklyRecap
    }

    // Backward-compatible decoding
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        transactions         = try c.decode([Transaction].self,  forKey: .transactions)
        savingsItems         = try c.decode([SavingsItem].self,  forKey: .savingsItems)
        backupFolderBookmark = try c.decodeIfPresent(Data.self,  forKey: .backupFolderBookmark)
        createdAt            = try c.decodeIfPresent(Date.self,  forKey: .createdAt)   ?? Date()
        version              = try c.decodeIfPresent(Int.self,   forKey: .version)     ?? 1
        earnedAchievements   = try c.decodeIfPresent([String].self,          forKey: .earnedAchievements)  ?? []
        streakCount          = try c.decodeIfPresent(Int.self,               forKey: .streakCount)         ?? 0
        lastStreakDate       = try c.decodeIfPresent(Date.self,              forKey: .lastStreakDate)
        longestStreak        = try c.decodeIfPresent(Int.self,               forKey: .longestStreak)       ?? 0
        budgets              = try c.decodeIfPresent([Budget].self,          forKey: .budgets)             ?? []
        activeChallenges     = try c.decodeIfPresent([ActiveChallenge].self, forKey: .activeChallenges)    ?? []
        dismissedWeeklyRecap = try c.decodeIfPresent(Date.self,              forKey: .dismissedWeeklyRecap)
    }
}

// MARK: - Budget

struct Budget: Identifiable, Codable, Hashable {
    let id: UUID
    var category: Transaction.Category
    var monthlyLimit: Double

    init(id: UUID = UUID(), category: Transaction.Category, monthlyLimit: Double) {
        self.id           = id
        self.category     = category
        self.monthlyLimit = monthlyLimit
    }
}

// MARK: - Active Challenge

struct ActiveChallenge: Identifiable, Codable, Hashable {
    let id: UUID
    var type: ChallengeType
    var startDate: Date
    var isCompleted: Bool
    var linkedGoalID: UUID?    // for Double Down challenge

    init(id: UUID = UUID(), type: ChallengeType, startDate: Date = Date(), linkedGoalID: UUID? = nil) {
        self.id           = id
        self.type         = type
        self.startDate    = startDate
        self.isCompleted  = false
        self.linkedGoalID = linkedGoalID
    }

    enum ChallengeType: String, Codable, CaseIterable {
        case fiftyTwoWeek = "fiftyTwoWeek"
        case noSpendWeek  = "noSpendWeek"
        case doubleDown   = "doubleDown"
        case roundUp      = "roundUp"

        var title: String {
            switch self {
            case .fiftyTwoWeek: return "52-Week Challenge"
            case .noSpendWeek:  return "No-Spend Week"
            case .doubleDown:   return "Double Down"
            case .roundUp:      return "Round-Up"
            }
        }
        var subtitle: String {
            switch self {
            case .fiftyTwoWeek: return "Save ₹100 more each week for a year"
            case .noSpendWeek:  return "Zero discretionary spending for 7 days"
            case .doubleDown:   return "2× your normal monthly assign rate"
            case .roundUp:      return "Round every expense up, save the difference"
            }
        }
        var icon: String {
            switch self {
            case .fiftyTwoWeek: return "calendar.badge.checkmark"
            case .noSpendWeek:  return "lock.shield.fill"
            case .doubleDown:   return "bolt.fill"
            case .roundUp:      return "arrow.up.circle.fill"
            }
        }
        var durationDays: Int {
            switch self {
            case .fiftyTwoWeek: return 364
            case .noSpendWeek:  return 7
            case .doubleDown:   return 30
            case .roundUp:      return 30
            }
        }
    }
}
