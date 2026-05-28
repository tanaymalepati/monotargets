import Foundation
import UserNotifications

@Observable
final class AppStore {
    var transactions: [Transaction]         = []
    var savingsItems: [SavingsItem]         = []
    var backupFolderBookmark: Data?

    // MARK: - Gamification State

    var earnedAchievements: [String]        = []   // achievement IDs
    var streakCount: Int                    = 0
    var lastStreakDate: Date?               = nil
    var longestStreak: Int                  = 0
    var budgets: [Budget]                   = []
    var activeChallenges: [ActiveChallenge] = []
    var dismissedWeeklyRecap: Date?         = nil

    /// Achievements newly unlocked in this session — drive the pop-up toast
    var newlyUnlockedAchievements: [Achievement] = []

    // MARK: - Balance Computed

    var totalBalance: Double {
        transactions.reduce(0.0) { sum, t in
            switch t.type {
            case .inward:            return sum + t.amount
            case .outward:           return sum - t.amount
            case .assign, .unassign: return sum
            }
        }
    }

    var totalAssigned:   Double { savingsItems.reduce(0.0) { $0 + $1.assignedAmount } }
    var totalUnassigned: Double { max(totalBalance - totalAssigned, 0) }
    var completedGoals:  Int    { savingsItems.filter { $0.isCompleted || $0.isFullyFunded }.count }

    // MARK: - Vault Score (0–1000)

    /// Weighted composite: savings rate (40%) + goal progress (30%) + streak (20%) + consistency (10%)
    var vaultScore: Int {
        // 1. Savings rate component (max 400 pts)
        let rateScore = min(thisMonthSavingsRate / 0.5, 1.0) * 400

        // 2. Goal progress component (max 300 pts) — average progress across all goals
        let avgProgress: Double
        if savingsItems.isEmpty {
            avgProgress = 0
        } else {
            avgProgress = savingsItems.reduce(0.0) { $0 + $1.progress } / Double(savingsItems.count)
        }
        let goalScore = avgProgress * 300

        // 3. Streak component (max 200 pts) — 30-day streak = full score
        let streakScore = min(Double(streakCount) / 30.0, 1.0) * 200

        // 4. Consistency component (max 100 pts) — transactions in last 30 days
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 86400)
        let recentCount = transactions.filter { $0.date >= thirtyDaysAgo }.count
        let consistencyScore = min(Double(recentCount) / 10.0, 1.0) * 100

        return Int((rateScore + goalScore + streakScore + consistencyScore).rounded())
    }

    // MARK: - XP + Level

    var totalXP: Int {
        earnedAchievements.compactMap { id in
            Achievement.all.first { $0.id == id }
        }.reduce(0) { $0 + $1.xp }
    }

    var currentLevel: VaultLevel { VaultLevel.current(xp: totalXP) }
    var nextLevel: VaultLevel?   { VaultLevel.next(xp: totalXP) }
    var levelProgress: Double    { VaultLevel.progressToNext(xp: totalXP) }

    // MARK: - Monthly Stats

    private func startOfCurrentMonth() -> Date {
        let cal = Calendar.current
        let c   = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: c) ?? Date()
    }

    private func startOfMonth(for date: Date) -> Date {
        let cal = Calendar.current
        let c   = cal.dateComponents([.year, .month], from: date)
        return cal.date(from: c) ?? date
    }

    var thisMonthInflow: Double {
        let start = startOfCurrentMonth()
        return transactions
            .filter { $0.type == .inward && $0.date >= start }
            .reduce(0.0) { $0 + $1.amount }
    }

    var thisMonthOutflow: Double {
        let start = startOfCurrentMonth()
        return transactions
            .filter { $0.type == .outward && $0.date >= start }
            .reduce(0.0) { $0 + $1.amount }
    }

    var thisMonthNet: Double { thisMonthInflow - thisMonthOutflow }

    var thisMonthSavingsRate: Double {
        guard thisMonthInflow > 0 else { return 0 }
        return max(thisMonthNet / thisMonthInflow, 0)
    }

    /// Best savings rate across the last 6 months
    var bestMonthlySavingsRate: Double {
        var best: Double = 0
        let cal = Calendar.current
        for offset in 0..<6 {
            guard let monthStart = cal.date(byAdding: .month, value: -offset, to: startOfCurrentMonth()),
                  let monthEnd   = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }
            let inflow  = transactions.filter { $0.type == .inward  && $0.date >= monthStart && $0.date < monthEnd }.reduce(0.0) { $0 + $1.amount }
            let outflow = transactions.filter { $0.type == .outward && $0.date >= monthStart && $0.date < monthEnd }.reduce(0.0) { $0 + $1.amount }
            guard inflow > 0 else { continue }
            let rate = max((inflow - outflow) / inflow, 0)
            best = max(best, rate)
        }
        return best
    }

    // MARK: - Category Breakdown

    var thisMonthSpendByCategory: [(Transaction.Category, Double)] {
        let start = startOfCurrentMonth()
        var totals: [Transaction.Category: Double] = [:]
        for t in transactions where t.type == .outward && t.date >= start {
            let cat = t.category ?? .other
            totals[cat, default: 0] += t.amount
        }
        return totals
            .sorted { $0.value > $1.value }
            .map { ($0.key, $0.value) }
    }

    // MARK: - 8-Week Sparkline

    /// Net savings (inflow − outflow) per week for the last 8 weeks
    var eightWeekSparkline: [Double] {
        let cal = Calendar.current
        let today = Date()
        return (0..<8).reversed().map { weekOffset -> Double in
            guard
                let weekStart = cal.date(byAdding: .weekOfYear, value: -weekOffset, to: cal.startOfDay(for: today)),
                let weekEnd   = cal.date(byAdding: .weekOfYear, value: 1, to: weekStart)
            else { return 0 }
            let inflow  = transactions.filter { $0.type == .inward  && $0.date >= weekStart && $0.date < weekEnd }.reduce(0.0) { $0 + $1.amount }
            let outflow = transactions.filter { $0.type == .outward && $0.date >= weekStart && $0.date < weekEnd }.reduce(0.0) { $0 + $1.amount }
            return max(inflow - outflow, 0)
        }
    }

    // MARK: - 12-Month Projection

    var twelveMonthProjection: Double {
        guard thisMonthInflow > 0 else { return totalBalance }
        let monthlySave = thisMonthNet
        return totalBalance + (monthlySave * 12)
    }

    // MARK: - Weekly Recap Gate

    /// Show recap card only on Mondays and if not already dismissed this week
    var showWeeklyRecap: Bool {
        let cal = Calendar.current
        guard cal.component(.weekday, from: Date()) == 2 else { return false }   // 2 = Monday
        guard let dismissed = dismissedWeeklyRecap else { return true }
        let weekStart = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        let dismissedWeek = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: dismissed)
        return weekStart.weekOfYear != dismissedWeek.weekOfYear ||
               weekStart.yearForWeekOfYear != dismissedWeek.yearForWeekOfYear
    }

    func dismissWeeklyRecap() {
        dismissedWeeklyRecap = Date()
        save()
    }

    // MARK: - Smart Goal ETA

    func goalETA(for itemID: UUID) -> String? {
        guard let item = savingsItems.first(where: { $0.id == itemID }),
              !item.isFullyFunded, item.remaining > 0
        else { return nil }

        let sixtyDaysAgo = Date().addingTimeInterval(-60 * 86400)
        let recentAssigns = transactions.filter {
            $0.type == .assign && $0.linkedItemID == itemID && $0.date > sixtyDaysAgo
        }
        guard !recentAssigns.isEmpty else { return nil }

        let total = recentAssigns.reduce(0.0) { $0 + $1.amount }
        let monthlyRate = total / 2.0

        guard monthlyRate > 0 else { return nil }

        let months = item.remaining / monthlyRate
        if months < 1   { return "< 1 month away" }
        if months < 1.5 { return "~1 month away" }
        if months < 12  { return "~\(Int(months.rounded())) months away" }
        let years = Int((months / 12).rounded())
        return "~\(years) yr\(years == 1 ? "" : "s") away"
    }

    // MARK: - Streak Management

    func checkAndUpdateStreak() {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())

        if let last = lastStreakDate {
            let lastDay = cal.startOfDay(for: last)
            if lastDay == today {
                // Already updated today — no-op
                return
            }
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            if lastDay == yesterday {
                // Continued streak
                streakCount += 1
            } else {
                // Missed a day — reset
                streakCount = 1
            }
        } else {
            // First ever save activity
            streakCount = 1
        }
        lastStreakDate = today
        longestStreak  = max(longestStreak, streakCount)
    }

    // MARK: - Achievements

    func evalAchievements() {
        let ctx = buildCheckContext()
        var newlyEarned: [Achievement] = []

        for ach in Achievement.all {
            guard !earnedAchievements.contains(ach.id) else { continue }
            if ach.checkEarned(ctx) {
                earnedAchievements.append(ach.id)
                newlyEarned.append(ach)
            }
        }

        if !newlyEarned.isEmpty {
            newlyUnlockedAchievements.append(contentsOf: newlyEarned)
        }
    }

    private func buildCheckContext() -> AchievementCheckContext {
        AchievementCheckContext(
            goalCount:             savingsItems.count,
            totalAssigns:          transactions.filter { $0.type == .assign }.count,
            completedGoals:        completedGoals,
            totalBalance:          totalBalance,
            longestStreak:         longestStreak,
            bestMonthlySavingsRate: bestMonthlySavingsRate,
            hadPerfectBudgetMonth: hadPerfectBudgetMonth,
            hadFastFund:           hadFastFundAchievement
        )
    }

    func dismissUnlockedAchievement(_ id: String) {
        newlyUnlockedAchievements.removeAll { $0.id == id }
    }

    // MARK: - Budget

    func setBudget(for category: Transaction.Category, limit: Double) {
        if let idx = budgets.firstIndex(where: { $0.category == category }) {
            budgets[idx].monthlyLimit = limit
        } else {
            budgets.append(Budget(category: category, monthlyLimit: limit))
        }
        save()
    }

    func removeBudget(for category: Transaction.Category) {
        budgets.removeAll { $0.category == category }
        save()
    }

    func spent(in category: Transaction.Category) -> Double {
        let start = startOfCurrentMonth()
        return transactions
            .filter { $0.type == .outward && $0.category == category && $0.date >= start }
            .reduce(0.0) { $0 + $1.amount }
    }

    func budgetUsedFraction(for category: Transaction.Category) -> Double {
        guard let budget = budgets.first(where: { $0.category == category }),
              budget.monthlyLimit > 0 else { return 0 }
        return min(spent(in: category) / budget.monthlyLimit, 1.0)
    }

    /// True if every budgeted category stayed under limit for the current month
    var hadPerfectBudgetMonth: Bool {
        guard !budgets.isEmpty else { return false }
        return budgets.allSatisfy { budget in
            spent(in: budget.category) <= budget.monthlyLimit
        }
    }

    // MARK: - Challenges

    func joinChallenge(_ type: ActiveChallenge.ChallengeType, linkedGoalID: UUID? = nil) {
        guard !activeChallenges.contains(where: { $0.type == type && !$0.isCompleted }) else { return }
        let challenge = ActiveChallenge(type: type, linkedGoalID: linkedGoalID)
        activeChallenges.append(challenge)
        save()
    }

    func leaveChallenge(id: UUID) {
        activeChallenges.removeAll { $0.id == id }
        save()
    }

    /// Progress fraction 0–1 for an active challenge
    func challengeProgress(for challenge: ActiveChallenge) -> Double {
        let elapsed = Date().timeIntervalSince(challenge.startDate)
        let duration = Double(challenge.type.durationDays) * 86400
        return min(elapsed / max(duration, 1), 1.0)
    }

    /// Check if any active challenge has expired; mark as completed
    func checkChallengeExpiry() {
        let now = Date()
        for idx in activeChallenges.indices {
            let deadline = activeChallenges[idx].startDate
                .addingTimeInterval(Double(activeChallenges[idx].type.durationDays) * 86400)
            if now >= deadline && !activeChallenges[idx].isCompleted {
                activeChallenges[idx].isCompleted = true
            }
        }
        save()
    }

    // MARK: - Goal Boost

    func activateBoost(for itemID: UUID, target: Double) {
        guard let idx = savingsItems.firstIndex(where: { $0.id == itemID }) else { return }
        savingsItems[idx].boostTarget   = target
        savingsItems[idx].boostDeadline = Date().addingTimeInterval(7 * 86400)
        save()
    }

    func clearBoost(for itemID: UUID) {
        guard let idx = savingsItems.firstIndex(where: { $0.id == itemID }) else { return }
        savingsItems[idx].boostTarget   = nil
        savingsItems[idx].boostDeadline = nil
        save()
    }

    // MARK: - Fast Fund Achievement Helper

    /// True if any goal was funded to 100% within 30 days of creation
    private var hadFastFundAchievement: Bool {
        for item in savingsItems where item.isFullyFunded {
            let assignTxns = transactions.filter {
                $0.linkedItemID == item.id && $0.type == .assign
            }
            guard assignTxns.last != nil else { continue }   // earliest = last in reversed array
            // Check if total assigns completed the goal within 30 days of creation
            let totalAssignedInThirtyDays = assignTxns
                .filter { $0.date <= item.createdAt.addingTimeInterval(30 * 86400) }
                .reduce(0.0) { $0 + $1.amount }
            if totalAssignedInThirtyDays >= item.targetAmount { return true }
        }
        return false
    }

    // MARK: - Persistence

    private var dataURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("vault_data.json")
    }

    init() { load() }

    private func load() {
        guard
            let data    = try? Data(contentsOf: dataURL),
            let decoded = try? JSONDecoder().decode(VaultData.self, from: data)
        else { return }
        transactions         = decoded.transactions
        savingsItems         = decoded.savingsItems
        backupFolderBookmark = decoded.backupFolderBookmark

        // Gamification
        earnedAchievements   = decoded.earnedAchievements
        streakCount          = decoded.streakCount
        lastStreakDate        = decoded.lastStreakDate
        longestStreak         = decoded.longestStreak
        budgets              = decoded.budgets
        activeChallenges     = decoded.activeChallenges
        dismissedWeeklyRecap = decoded.dismissedWeeklyRecap
    }

    func save() {
        let payload = VaultData(
            transactions:         transactions,
            savingsItems:         savingsItems,
            backupFolderBookmark: backupFolderBookmark,
            earnedAchievements:   earnedAchievements,
            streakCount:          streakCount,
            lastStreakDate:       lastStreakDate,
            longestStreak:        longestStreak,
            budgets:              budgets,
            activeChallenges:     activeChallenges,
            dismissedWeeklyRecap: dismissedWeeklyRecap
        )
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: dataURL, options: .atomic)
        }
        BackupService.shared.triggerBackup(store: self)
    }

    // MARK: - Transactions

    func addTransaction(
        amount:          Double,
        type:            Transaction.TransactionType,
        note:            String,
        category:        Transaction.Category?        = nil,
        payee:           String?                      = nil,
        paymentMethod:   Transaction.PaymentMethod?   = nil,
        tags:            [String]                     = [],
        isRecurring:     Bool                         = false,
        recurringPeriod: Transaction.RecurringPeriod? = nil
    ) {
        let t = Transaction(
            amount:          amount,
            type:            type,
            note:            note,
            category:        category,
            payee:           payee,
            paymentMethod:   paymentMethod,
            tags:            tags,
            isRecurring:     isRecurring,
            recurringPeriod: recurringPeriod
        )
        transactions.insert(t, at: 0)
        checkAndUpdateStreak()
        evalAchievements()
        save()
    }

    func deleteTransaction(id: UUID) {
        transactions.removeAll { $0.id == id }
        save()
    }

    // MARK: - Savings Items

    func createSavingsItem(_ item: SavingsItem) {
        var new = item
        new.sortOrder = savingsItems.count
        savingsItems.append(new)
        evalAchievements()
        save()
    }

    func updateSavingsItem(_ item: SavingsItem) {
        if let idx = savingsItems.firstIndex(where: { $0.id == item.id }) {
            savingsItems[idx] = item
        }
        save()
    }

    func deleteSavingsItem(id: UUID) {
        cancelReminder(for: id)
        savingsItems.removeAll { $0.id == id }
        transactions.removeAll { $0.linkedItemID == id }
        save()
    }

    // MARK: - Assign / Unassign

    func assignFunds(to itemID: UUID, amount: Double) {
        guard amount > 0, amount <= totalUnassigned else { return }
        guard let idx = savingsItems.firstIndex(where: { $0.id == itemID }) else { return }

        savingsItems[idx].assignedAmount += amount
        let note = "Assigned to \(savingsItems[idx].name)"
        let t = Transaction(amount: amount, type: .assign, note: note, linkedItemID: itemID)
        transactions.insert(t, at: 0)

        if savingsItems[idx].isFullyFunded && !savingsItems[idx].isCompleted {
            savingsItems[idx].isCompleted = true
        }
        checkAndUpdateStreak()
        evalAchievements()
        save()
    }

    func unassignFunds(from itemID: UUID, amount: Double) {
        guard let idx = savingsItems.firstIndex(where: { $0.id == itemID }) else { return }
        let actual = min(amount, savingsItems[idx].assignedAmount)
        guard actual > 0 else { return }

        savingsItems[idx].assignedAmount -= actual
        savingsItems[idx].isCompleted = false
        let note = "Unassigned from \(savingsItems[idx].name)"
        let t = Transaction(amount: actual, type: .unassign, note: note, linkedItemID: itemID)
        transactions.insert(t, at: 0)
        save()
    }

    // MARK: - Backup folder

    func setBackupFolder(bookmark: Data) {
        backupFolderBookmark = bookmark
        save()
    }

    // MARK: - Clear All Data

    func clearAllData() {
        savingsItems.forEach { cancelReminder(for: $0.id) }
        transactions         = []
        savingsItems         = []
        earnedAchievements   = []
        streakCount          = 0
        lastStreakDate        = nil
        longestStreak         = 0
        budgets              = []
        activeChallenges     = []
        dismissedWeeklyRecap = nil
        UserDefaults.standard.removeObject(forKey: "onboarding_done")
        UserDefaults.standard.removeObject(forKey: "user_name")
        save()
    }

    // MARK: - Stats / Queries

    func transactionsForItem(_ id: UUID) -> [Transaction] {
        transactions.filter { $0.linkedItemID == id }
    }

    var recentTransactions: [Transaction] { Array(transactions.prefix(10)) }

    // MARK: - Reminders (Local Notifications)

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleReminder(for item: SavingsItem) {
        guard let day = item.monthlyReminderDay else {
            cancelReminder(for: item.id)
            return
        }
        cancelReminder(for: item.id)

        let content = UNMutableNotificationContent()
        content.title = "Savings reminder — \(item.name)"
        content.body  = "You're at \(Int(item.progress * 100))% — add to \(item.name) today."
        content.sound = .default

        var dc = DateComponents()
        dc.day    = min(max(day, 1), 28)
        dc.hour   = 10
        dc.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let request = UNNotificationRequest(
            identifier: notificationID(for: item.id),
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelReminder(for itemID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationID(for: itemID)])
    }

    private func notificationID(for itemID: UUID) -> String {
        "goal_reminder_\(itemID.uuidString)"
    }
}
