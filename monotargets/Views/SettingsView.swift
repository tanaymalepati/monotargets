import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var showFolderPicker = false
    @State private var showRestorePicker = false
    @State private var backupStatus: BackupStatus = .idle
    @State private var appeared = false

    enum BackupStatus: Equatable {
        case idle, success(String), error(String)
    }

    private var backupFolderName: String? {
        guard let bookmark = store.backupFolderBookmark else { return nil }
        var isStale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmark,
            options: .withoutUI,
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else { return nil }
        return url.lastPathComponent
    }

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Mono.S.lg) {

                    // App header
                    AppHeaderCard()
                        .padding(.horizontal, Mono.S.md)
                        .padding(.top, Mono.S.sm)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.92)

                    // Backup section
                    SettingsSection(title: "Backup") {
                        SettingsRow(icon: "folder.fill", label: "Backup Folder") {
                            VStack(alignment: .trailing, spacing: 2) {
                                if let name = backupFolderName {
                                    Text(name)
                                        .font(Mono.T.mono(13, .medium))
                                        .foregroundColor(Mono.C.textSec)
                                } else {
                                    Text("Not set")
                                        .font(Mono.T.mono(13, .regular))
                                        .foregroundColor(Mono.C.textDim)
                                }
                            }
                        } action: {
                            showFolderPicker = true
                        }

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        SettingsRow(icon: "arrow.clockwise.circle.fill", label: "Backup Now") {
                            if case .success(let msg) = backupStatus {
                                Text(msg)
                                    .font(Mono.T.mono(11, .regular))
                                    .foregroundColor(Mono.C.positive)
                            }
                        } action: {
                            manualBackup()
                        }

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        SettingsRow(icon: "arrow.down.circle.fill", label: "Restore from JSON") {
                            EmptyView()
                        } action: {
                            showRestorePicker = true
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                    // Backup info card
                    VStack(alignment: .leading, spacing: Mono.S.sm) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Mono.C.textTert)
                            Text("How Backup Works")
                                .font(Mono.T.mono(12, .semibold))
                                .foregroundColor(Mono.C.textTert)
                        }

                        Text("Every transaction and goal change automatically backs up to your chosen folder as vault_latest.json. Timestamped snapshots (vault_backup_YYYYMMDD_HHMMSS.json) are also saved. If the app stops working, your data is always recoverable from these JSON files.")
                            .font(Mono.T.mono(11, .regular))
                            .foregroundColor(Mono.C.textDim)
                            .lineSpacing(4)
                    }
                    .padding(Mono.S.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .monoCard()
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)

                    // Data stats
                    SettingsSection(title: "Data") {
                        StatRow(label: "Transactions", value: "\(store.transactions.count)")
                        MonoDivider().padding(.horizontal, Mono.S.md)
                        StatRow(label: "Goals", value: "\(store.savingsItems.count)")
                        MonoDivider().padding(.horizontal, Mono.S.md)
                        StatRow(label: "Completed Goals", value: "\(store.completedGoals)")
                        MonoDivider().padding(.horizontal, Mono.S.md)
                        StatRow(
                            label: "Total Tracked",
                            value: store.totalBalance.indianFormattedCompact
                        )
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                    // Danger zone
                    SettingsSection(title: "Danger Zone") {
                        DangerButton(icon: "trash.fill", label: "Clear All Data") {
                            // Handled via confirmation
                        }
                        .padding(Mono.S.sm)
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)

                    // Version info
                    VStack(spacing: 4) {
                        Text("VAULT")
                            .font(Mono.T.mono(11, .bold))
                            .foregroundColor(Mono.C.textDim)
                            .tracking(4)
                        Text("v1.0 · Built with SF Mono + SwiftUI")
                            .font(Mono.T.mono(10, .regular))
                            .foregroundColor(Mono.C.textDim.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Mono.S.xl)

                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.2).delay(0.05)) {
                appeared = true
            }
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            handleFolderSelection(result)
        }
        .fileImporter(
            isPresented: $showRestorePicker,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleRestore(result)
        }
    }

    private func handleFolderSelection(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        if let bookmark = BackupService.shared.createBookmark(for: url) {
            store.setBackupFolder(bookmark: bookmark)
            backupStatus = .success("Folder set")
            Haptic.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { backupStatus = .idle }
        }
    }

    private func handleRestore(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        if let vaultData = BackupService.shared.restoreFromURL(url) {
            store.transactions  = vaultData.transactions
            store.savingsItems  = vaultData.savingsItems
            store.save()
            backupStatus = .success("Restored!")
            Haptic.success()
        } else {
            backupStatus = .error("Could not parse file")
            Haptic.error()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { backupStatus = .idle }
    }

    private func manualBackup() {
        guard store.backupFolderBookmark != nil else {
            backupStatus = .error("Set a folder first")
            Haptic.error()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { backupStatus = .idle }
            return
        }
        BackupService.shared.triggerBackup(store: store)
        backupStatus = .success("Backed up!")
        Haptic.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { backupStatus = .idle }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.sm) {
            OverlineLabel(text: title, opacity: 0.45)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                content
            }
            .monoCard()
        }
    }
}

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let label: String
    @ViewBuilder let trailing: Trailing
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            Haptic.light()
        }) {
            HStack(spacing: Mono.S.md) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Mono.C.textSec)
                    .frame(width: 22)

                Text(label)
                    .font(Mono.T.mono(15, .medium))
                    .foregroundColor(Mono.C.text)

                Spacer()

                trailing

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Mono.C.textDim)
            }
            .padding(Mono.S.md)
        }
        .buttonStyle(.plain)
    }
}

struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(Mono.T.mono(14, .regular))
                .foregroundColor(Mono.C.textSec)
            Spacer()
            Text(value)
                .font(Mono.T.mono(14, .semibold))
                .foregroundColor(Mono.C.text)
        }
        .padding(Mono.S.md)
    }
}

// MARK: - App Header Card

struct AppHeaderCard: View {
    var body: some View {
        HStack(spacing: Mono.S.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Mono.G.hero)
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(Mono.C.borderBright.opacity(0.4), lineWidth: 0.6)
                    )

                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(Mono.C.text)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("VAULT")
                    .font(Mono.T.mono(22, .bold))
                    .foregroundColor(Mono.C.text)
                    .tracking(4)

                Text("Savings Tracker")
                    .font(Mono.T.mono(13, .regular))
                    .foregroundColor(Mono.C.textTert)
            }

            Spacer()
        }
        .padding(Mono.S.lg)
        .monoCard(elevated: true)
    }
}
