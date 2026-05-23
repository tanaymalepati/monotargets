import Foundation

final class BackupService {
    static let shared = BackupService()
    private init() {}

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // MARK: - Trigger

    func triggerBackup(store: AppStore) {
        guard let bookmark = store.backupFolderBookmark else { return }
        var isStale = false
        guard
            let url = try? URL(
                resolvingBookmarkData: bookmark,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        else { return }

        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let payload = VaultData(
            transactions: store.transactions,
            savingsItems: store.savingsItems,
            backupFolderBookmark: nil
        )

        guard let data = try? encoder.encode(payload) else { return }

        let timestamp = VaultDateFormatter.backupTimestamp.string(from: Date())
        let filename = "vault_backup_\(timestamp).json"
        let fileURL = url.appendingPathComponent(filename)
        try? data.write(to: fileURL, options: .atomic)

        // Also write a "latest" snapshot for easy recovery
        let latestURL = url.appendingPathComponent("vault_latest.json")
        try? data.write(to: latestURL, options: .atomic)
    }

    // MARK: - Restore

    func restoreFromURL(_ url: URL) -> VaultData? {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(VaultData.self, from: data)
    }

    // MARK: - Bookmark

    func createBookmark(for url: URL) -> Data? {
        return try? url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
}
