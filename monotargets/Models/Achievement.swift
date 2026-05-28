import Foundation

// MARK: - Achievement

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String   // shown when locked (hint)
    let earnedDescription: String  // shown when unlocked
    let icon: String          // SF Symbol
    let xp: Int
    let category: AchievementCategory

    enum AchievementCategory: String, CaseIterable {
        case milestones = "Milestones"
        case streaks    = "Streaks"
        case discipline = "Discipline"
        case speed      = "Speed"
    }

    // Check whether this achievement is earned given current store state
    var checkEarned: (AchievementCheckContext) -> Bool

    // MARK: - All achievements (static catalog)

    static let all: [Achievement] = [

        // ── Milestones ──────────────────────────────────────────────
        Achievement(
            id: "first_goal",
            title: "First Step",
            description: "Create your first savings goal",
            earnedDescription: "You set your first savings goal. The journey begins.",
            icon: "flag.fill",
            xp: 50,
            category: .milestones,
            checkEarned: { ctx in ctx.goalCount >= 1 }
        ),
        Achievement(
            id: "first_fund",
            title: "Money Moves",
            description: "Assign funds to a goal for the first time",
            earnedDescription: "First assign done. Every rupee counts.",
            icon: "arrow.right.circle.fill",
            xp: 75,
            category: .milestones,
            checkEarned: { ctx in ctx.totalAssigns >= 1 }
        ),
        Achievement(
            id: "goal_complete",
            title: "Fully Funded",
            description: "Fund a goal to 100%",
            earnedDescription: "One goal fully funded. That feeling is addictive.",
            icon: "checkmark.seal.fill",
            xp: 200,
            category: .milestones,
            checkEarned: { ctx in ctx.completedGoals >= 1 }
        ),
        Achievement(
            id: "five_goals",
            title: "Goal Collector",
            description: "Create 5 savings goals",
            earnedDescription: "Five goals live. Dreaming big.",
            icon: "list.bullet.circle.fill",
            xp: 150,
            category: .milestones,
            checkEarned: { ctx in ctx.goalCount >= 5 }
        ),
        Achievement(
            id: "lakh_saved",
            title: "Lakh Club",
            description: "Reach ₹1,00,000 total balance",
            earnedDescription: "₹1 lakh in the vault. You made it.",
            icon: "indianrupeesign.circle.fill",
            xp: 300,
            category: .milestones,
            checkEarned: { ctx in ctx.totalBalance >= 100_000 }
        ),
        Achievement(
            id: "three_funded",
            title: "Triple Crown",
            description: "Fund 3 goals to 100%",
            earnedDescription: "Three goals crushed. You're unstoppable.",
            icon: "trophy.fill",
            xp: 500,
            category: .milestones,
            checkEarned: { ctx in ctx.completedGoals >= 3 }
        ),

        // ── Streaks ─────────────────────────────────────────────────
        Achievement(
            id: "streak_7",
            title: "Week Warrior",
            description: "Maintain a 7-day saving streak",
            earnedDescription: "7 days straight. The habit is forming.",
            icon: "flame.fill",
            xp: 100,
            category: .streaks,
            checkEarned: { ctx in ctx.longestStreak >= 7 }
        ),
        Achievement(
            id: "streak_30",
            title: "Monthly Grind",
            description: "Maintain a 30-day saving streak",
            earnedDescription: "30 days of discipline. This is who you are now.",
            icon: "flame.circle.fill",
            xp: 300,
            category: .streaks,
            checkEarned: { ctx in ctx.longestStreak >= 30 }
        ),
        Achievement(
            id: "streak_100",
            title: "Century",
            description: "Maintain a 100-day saving streak",
            earnedDescription: "100 days. Legendary.",
            icon: "bolt.circle.fill",
            xp: 1000,
            category: .streaks,
            checkEarned: { ctx in ctx.longestStreak >= 100 }
        ),

        // ── Discipline ───────────────────────────────────────────────
        Achievement(
            id: "savings_rate_30",
            title: "Saver",
            description: "Achieve a 30%+ savings rate in a month",
            earnedDescription: "You saved 30% of your income. Most people never do this.",
            icon: "chart.line.uptrend.xyaxis",
            xp: 200,
            category: .discipline,
            checkEarned: { ctx in ctx.bestMonthlySavingsRate >= 0.30 }
        ),
        Achievement(
            id: "no_overspend",
            title: "Budget Boss",
            description: "Stay under budget in all categories for a full month",
            earnedDescription: "Not a single overspend. Iron discipline.",
            icon: "lock.shield.fill",
            xp: 250,
            category: .discipline,
            checkEarned: { ctx in ctx.hadPerfectBudgetMonth }
        ),

        // ── Speed ────────────────────────────────────────────────────
        Achievement(
            id: "fast_fund",
            title: "Speed Run",
            description: "Fund a goal to 100% within 30 days of creating it",
            earnedDescription: "Goal funded in under 30 days. Ruthless execution.",
            icon: "hare.fill",
            xp: 400,
            category: .speed,
            checkEarned: { ctx in ctx.hadFastFund }
        ),
    ]
}

// MARK: - Check Context (passed from AppStore)

struct AchievementCheckContext {
    var goalCount: Int
    var totalAssigns: Int
    var completedGoals: Int
    var totalBalance: Double
    var longestStreak: Int
    var bestMonthlySavingsRate: Double
    var hadPerfectBudgetMonth: Bool
    var hadFastFund: Bool
}

// MARK: - XP + Level

struct VaultLevel {
    let number: Int
    let title: String
    let minXP: Int

    static let levels: [VaultLevel] = [
        VaultLevel(number: 1,  title: "Rookie Saver",      minXP: 0),
        VaultLevel(number: 2,  title: "Budget Aware",      minXP: 100),
        VaultLevel(number: 3,  title: "Consistent",        minXP: 300),
        VaultLevel(number: 4,  title: "Disciplined",       minXP: 600),
        VaultLevel(number: 5,  title: "Frugal Mind",       minXP: 1000),
        VaultLevel(number: 6,  title: "Money Mover",       minXP: 1500),
        VaultLevel(number: 7,  title: "Wealth Builder",    minXP: 2200),
        VaultLevel(number: 8,  title: "Compound Effect",   minXP: 3000),
        VaultLevel(number: 9,  title: "Financial Monk",    minXP: 4000),
        VaultLevel(number: 10, title: "Vault Master",      minXP: 5500),
    ]

    static func current(xp: Int) -> VaultLevel {
        levels.last(where: { xp >= $0.minXP }) ?? levels[0]
    }

    static func next(xp: Int) -> VaultLevel? {
        levels.first(where: { xp < $0.minXP })
    }

    static func progressToNext(xp: Int) -> Double {
        let cur  = current(xp: xp)
        guard let nxt = next(xp: xp) else { return 1.0 }
        let range = Double(nxt.minXP - cur.minXP)
        let done  = Double(xp - cur.minXP)
        return range > 0 ? min(done / range, 1.0) : 1.0
    }
}
