import Foundation

final class BackupService {
    static let shared = BackupService()
    private init() {}

    static let maxBackups = 10
    private let lastBackupKey = "vault_lastBackupDate"
    private let backupCountKey = "vault_backupCount"

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // MARK: - Last backup info (stored in UserDefaults, readable without folder access)

    var lastBackupDate: Date? {
        UserDefaults.standard.object(forKey: lastBackupKey) as? Date
    }

    var storedBackupCount: Int {
        UserDefaults.standard.integer(forKey: backupCountKey)
    }

    // MARK: - Trigger

    func triggerBackup(store: AppStore) {
        guard let bookmark = store.backupFolderBookmark else { return }
        var isStale = false
        guard
            let folderURL = try? URL(
                resolvingBookmarkData: bookmark,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        else { return }

        let accessed = folderURL.startAccessingSecurityScopedResource()
        defer { if accessed { folderURL.stopAccessingSecurityScopedResource() } }

        let payload = VaultData(
            transactions: store.transactions,
            savingsItems: store.savingsItems,
            backupFolderBookmark: nil
        )
        guard let data = try? encoder.encode(payload) else { return }

        // ── 1. Rotate: delete oldest backups if at or above the limit
        pruneOldBackups(in: folderURL)

        // ── 2. Write timestamped snapshot
        let timestamp = VaultDateFormatter.backupTimestamp.string(from: Date())
        let snapshotURL = folderURL.appendingPathComponent("vault_backup_\(timestamp).json")
        try? data.write(to: snapshotURL, options: .atomic)

        // ── 3. Overwrite the always-fresh "latest" file
        let latestURL = folderURL.appendingPathComponent("vault_latest.json")
        try? data.write(to: latestURL, options: .atomic)

        // ── 4. Record the backup date and updated count
        let now = Date()
        UserDefaults.standard.set(now, forKey: lastBackupKey)
        let newCount = backupFileCount(in: folderURL)
        UserDefaults.standard.set(newCount, forKey: backupCountKey)
    }

    // MARK: - Prune

    private func pruneOldBackups(in folderURL: URL) {
        let files = backupFiles(in: folderURL)
        guard files.count >= Self.maxBackups else { return }
        // Delete oldest files (name sort = chronological because of YYYYMMDD_HHMMSS format)
        let toDelete = files.prefix(files.count - Self.maxBackups + 1)
        for url in toDelete {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Returns timestamped backup files sorted oldest → newest.
    private func backupFiles(in folderURL: URL) -> [URL] {
        let all = (try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
        return all
            .filter { $0.lastPathComponent.hasPrefix("vault_backup_") && $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func backupFileCount(in folderURL: URL) -> Int {
        backupFiles(in: folderURL).count
    }

    // MARK: - Live count (requires folder access)

    func liveBackupInfo(bookmark: Data?) -> (count: Int, oldest: Date?, newest: Date?) {
        guard let bookmark else { return (0, nil, nil) }
        var isStale = false
        guard
            let folderURL = try? URL(
                resolvingBookmarkData: bookmark,
                options: .withoutUI,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        else { return (0, nil, nil) }

        let accessed = folderURL.startAccessingSecurityScopedResource()
        defer { if accessed { folderURL.stopAccessingSecurityScopedResource() } }

        let files = backupFiles(in: folderURL)
        guard !files.isEmpty else { return (0, nil, nil) }

        let attrs = { (u: URL) -> Date? in
            (try? FileManager.default.attributesOfItem(atPath: u.path))?[.modificationDate] as? Date
        }
        return (files.count, attrs(files.first!), attrs(files.last!))
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
        try? url.bookmarkData(
            options: .minimalBookmark,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
    }
}
