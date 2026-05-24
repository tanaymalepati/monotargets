import Foundation

final class BackupService {
    static let shared = BackupService()
    private init() {}

    static let maxBackups = 10
    private let lastBackupKey   = "vault_lastBackupDate"
    private let backupCountKey  = "vault_backupCount"
    private let backupIndexKey  = "vault_backupIndex"   // ever-increasing counter

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .iso8601
        return e
    }()

    // MARK: - Persistent counter

    /// The next index to use for a new backup file.
    private var nextIndex: Int {
        UserDefaults.standard.integer(forKey: backupIndexKey)
    }

    private func consumeNextIndex() -> Int {
        let idx = nextIndex
        UserDefaults.standard.set(idx + 1, forKey: backupIndexKey)
        return idx
    }

    // MARK: - Last backup info (UserDefaults, no folder access needed)

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

        // ── 2. Write numbered snapshot (number always increases)
        let idx = consumeNextIndex()
        let snapshotURL = folderURL.appendingPathComponent("vault_backup_\(idx).json")
        try? data.write(to: snapshotURL, options: .atomic)

        // ── 3. Record the backup date and updated count
        UserDefaults.standard.set(Date(), forKey: lastBackupKey)
        let newCount = backupFileCount(in: folderURL)
        UserDefaults.standard.set(newCount, forKey: backupCountKey)
    }

    // MARK: - Prune

    private func pruneOldBackups(in folderURL: URL) {
        let files = backupFiles(in: folderURL)
        guard files.count >= Self.maxBackups else { return }
        // Delete lowest-numbered files (oldest), keeping room for the one about to be written
        let toDelete = files.prefix(files.count - Self.maxBackups + 1)
        for url in toDelete {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Returns backup files sorted oldest → newest (lowest number first).
    private func backupFiles(in folderURL: URL) -> [URL] {
        let all = (try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
        return all
            .compactMap { url -> (URL, Int)? in
                let stem = url.deletingPathExtension().lastPathComponent
                guard
                    url.pathExtension == "json",
                    stem.hasPrefix("vault_backup_"),
                    let n = Int(stem.dropFirst("vault_backup_".count))
                else { return nil }
                return (url, n)
            }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
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
