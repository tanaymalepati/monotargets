import Foundation
import Observation

@Observable
final class AppStore {
    var transactions: [Transaction] = []
    var savingsItems: [SavingsItem] = []
    var backupFolderBookmark: Data?

    // Computed balances
    var totalBalance: Double {
        let rawBalance = transactions.reduce(0.0) { sum, t in
            switch t.type {
            case .inward:   return sum + t.amount
            case .outward:  return sum - t.amount
            case .assign, .unassign: return sum
            }
        }
        let completedGoalsTotal = savingsItems.filter { $0.isCompleted }.reduce(0.0) { $0 + $1.assignedAmount }
        return rawBalance - completedGoalsTotal
    }

    var totalAssigned: Double {
        savingsItems.filter { !$0.isCompleted }.reduce(0.0) { $0 + $1.assignedAmount }
    }

    var totalUnassigned: Double {
        max(totalBalance - totalAssigned, 0)
    }

    var completedGoals: Int {
        savingsItems.filter { $0.isCompleted || $0.isFullyFunded }.count
    }

    // MARK: - Persistence

    private var dataURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("vault_data.json")
    }

    init() {
        load()
    }

    private func load() {
        guard
            let data = try? Data(contentsOf: dataURL),
            let decoded = try? JSONDecoder().decode(VaultData.self, from: data)
        else { return }
        transactions          = decoded.transactions
        savingsItems          = decoded.savingsItems
        backupFolderBookmark  = decoded.backupFolderBookmark
    }

    func save() {
        let payload = VaultData(
            transactions: transactions,
            savingsItems: savingsItems,
            backupFolderBookmark: backupFolderBookmark
        )
        if let data = try? JSONEncoder().encode(payload) {
            try? data.write(to: dataURL, options: .atomic)
        }
        BackupService.shared.triggerBackup(store: self)
    }

    // MARK: - Transactions

    func addTransaction(amount: Double, type: Transaction.TransactionType, note: String) {
        let t = Transaction(amount: amount, type: type, note: note)
        transactions.insert(t, at: 0)
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
        save()
    }

    func updateSavingsItem(_ item: SavingsItem) {
        if let idx = savingsItems.firstIndex(where: { $0.id == item.id }) {
            savingsItems[idx] = item
        }
        save()
    }

    func deleteSavingsItem(id: UUID) {
        // Reclaim assigned funds back (they exist as unassigned again)
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

    func markGoalCompleted(id: UUID) {
        guard let idx = savingsItems.firstIndex(where: { $0.id == id }) else { return }
        savingsItems[idx].isCompleted = true
        save()
    }

    func markGoalUncompleted(id: UUID) {
        guard let idx = savingsItems.firstIndex(where: { $0.id == id }) else { return }
        savingsItems[idx].isCompleted = false
        save()
    }

    // MARK: - Backup folder

    func setBackupFolder(bookmark: Data) {
        backupFolderBookmark = bookmark
        save()
    }

    // MARK: - Clear All Data

    func clearAllData() {
        transactions = []
        savingsItems = []
        // Preserve backup folder bookmark so the user doesn't have to re-select it
        save()
    }

    // MARK: - Stats

    func transactionsForItem(_ id: UUID) -> [Transaction] {
        transactions.filter { $0.linkedItemID == id }
    }

    var recentTransactions: [Transaction] {
        Array(transactions.prefix(10))
    }
}
