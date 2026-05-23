import Foundation

struct VaultData: Codable {
    var transactions: [Transaction]
    var savingsItems: [SavingsItem]
    var backupFolderBookmark: Data?
    var createdAt: Date
    var version: Int

    init(
        transactions: [Transaction] = [],
        savingsItems: [SavingsItem] = [],
        backupFolderBookmark: Data? = nil
    ) {
        self.transactions = transactions
        self.savingsItems = savingsItems
        self.backupFolderBookmark = backupFolderBookmark
        self.createdAt = Date()
        self.version = 1
    }
}
