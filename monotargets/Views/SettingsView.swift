import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @AppStorage("user_name")           private var userName       = ""
    @AppStorage("currency_code")       private var currencyCode   = "INR"
    @AppStorage("onboarding_done")     private var onboardingDone = true
    @AppStorage("smart_eta_enabled")   private var etaEnabled     = true

    @State private var showFolderPicker    = false
    @State private var showRestorePicker   = false
    @State private var backupStatus: BackupStatus = .idle
    @State private var appeared            = false
    @State private var liveBackupInfo: (count: Int, oldest: Date?, newest: Date?) = (0, nil, nil)
    @State private var showClearConfirm    = false
    @State private var showCurrencyPicker  = false
    @State private var showRerunConfirm    = false
    @State private var showBudgets         = false

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

    private var lastBackupText: String {
        guard let date = BackupService.shared.lastBackupDate else { return "Never" }
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            let fmt = DateFormatter()
            fmt.dateFormat = "h:mm a"
            return "Today, \(fmt.string(from: date))"
        }
        if cal.isDateInYesterday(date) {
            let fmt = DateFormatter()
            fmt.dateFormat = "h:mm a"
            return "Yesterday, \(fmt.string(from: date))"
        }
        return VaultDateFormatter.display.string(from: date)
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

                    // Preferences section
                    SettingsSection(title: "Preferences") {
                        // Name row
                        SettingsRow(icon: "person.fill", label: "Your Name") {
                            Text(userName.isEmpty ? "Not set" : userName)
                                .font(Mono.T.mono(13, .regular))
                                .foregroundColor(userName.isEmpty ? Mono.C.textDim : Mono.C.textSec)
                        } action: {
                            showCurrencyPicker = false
                            // Inline edit via alert-style — handled in sheet below
                            showRerunConfirm = false
                        }

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        // Currency row
                        SettingsRow(icon: "coloncurrencysign.circle.fill", label: "Currency") {
                            if let cur = CurrencyInfo.all.first(where: { $0.code == currencyCode }) {
                                HStack(spacing: 4) {
                                    Text(cur.flag)
                                    Text("\(cur.code) \(cur.symbol)")
                                        .font(Mono.T.mono(13, .medium))
                                        .foregroundColor(Mono.C.textSec)
                                }
                            }
                        } action: {
                            showCurrencyPicker = true
                            Haptic.light()
                        }

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        // Smart ETA toggle
                        HStack(spacing: Mono.S.md) {
                            Image(systemName: "clock.arrow.2.circlepath")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Mono.C.textSec)
                                .frame(width: 22)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smart Goal ETA")
                                    .font(Mono.T.mono(15, .medium))
                                    .foregroundColor(Mono.C.text)
                                Text("Estimated time to fund each goal")
                                    .font(Mono.T.mono(11, .regular))
                                    .foregroundColor(Mono.C.textDim)
                            }

                            Spacer()

                            Toggle("", isOn: $etaEnabled)
                                .tint(Mono.C.text)
                                .labelsHidden()
                                .onChange(of: etaEnabled) { _, _ in Haptic.select() }
                        }
                        .frame(minHeight: 52)
                        .padding(.horizontal, Mono.S.md)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation { etaEnabled.toggle() }
                            Haptic.select()
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                    // Budget section
                    SettingsSection(title: "Budgets") {
                        SettingsRow(icon: "chart.bar.fill", label: "Monthly Budgets") {
                            Text("\(store.budgets.count) set")
                                .font(Mono.T.mono(13, .regular))
                                .foregroundColor(Mono.C.textSec)
                        } action: {
                            showBudgets = true
                            Haptic.light()
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

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

                        // Last backup row (non-tappable info row)
                        HStack(spacing: Mono.S.md) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Mono.C.textSec)
                                .frame(width: 22)
                            Text("Last Backup")
                                .font(Mono.T.mono(15, .medium))
                                .foregroundColor(Mono.C.text)
                                .lineLimit(1)
                                .layoutPriority(1)
                            Spacer()
                            Text(lastBackupText)
                                .font(Mono.T.mono(13, .regular))
                                .foregroundColor(BackupService.shared.lastBackupDate == nil ? Mono.C.textDim : Mono.C.textSec)
                                .lineLimit(1)
                        }
                        .frame(minHeight: 52)
                        .padding(.horizontal, Mono.S.md)

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        // Backup count row
                        HStack(spacing: Mono.S.md) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Mono.C.textSec)
                                .frame(width: 22)
                            Text("Snapshots")
                                .font(Mono.T.mono(15, .medium))
                                .foregroundColor(Mono.C.text)
                                .lineLimit(1)
                                .layoutPriority(1)
                            Spacer()
                            HStack(spacing: 4) {
                                Text("\(liveBackupInfo.count)")
                                    .font(Mono.T.mono(13, .semibold))
                                    .foregroundColor(Mono.C.textSec)
                                Text("/ \(BackupService.maxBackups)")
                                    .font(Mono.T.mono(13, .regular))
                                    .foregroundColor(Mono.C.textDim)
                            }
                        }
                        .frame(minHeight: 52)
                        .padding(.horizontal, Mono.S.md)

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        // Backup Now — standalone CTA button
                        Button {
                            manualBackup()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: {
                                    if case .success(_) = backupStatus { return "checkmark.circle.fill" }
                                    if case .error(_)   = backupStatus { return "exclamationmark.circle.fill" }
                                    return "arrow.clockwise.circle.fill"
                                }())
                                .font(.system(size: 15, weight: .semibold))

                                Text({
                                    if case .success(let m) = backupStatus { return m }
                                    if case .error(let m)   = backupStatus { return m }
                                    return "Backup Now"
                                }())
                                .font(Mono.T.mono(14, .semibold))
                            }
                            .foregroundColor({
                                if case .error(_) = backupStatus { return Mono.C.negative }
                                return Mono.C.bg
                            }())
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                    .fill({
                                        if case .success(_) = backupStatus { return Mono.C.positive }
                                        if case .error(_)   = backupStatus { return Mono.C.negative.opacity(0.12) }
                                        return Mono.C.text
                                    }() as Color)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                            .strokeBorder({
                                                if case .error(_) = backupStatus { return Mono.C.negative.opacity(0.5) }
                                                return Color.clear
                                            }() as Color, lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, Mono.S.md)
                        .padding(.top, Mono.S.sm)
                        .padding(.bottom, Mono.S.md)
                        .animation(.spring(duration: 0.3, bounce: 0.2), value: {
                            if case .idle = backupStatus { return 0 }
                            if case .success(_) = backupStatus { return 1 }
                            return 2
                        }() as Int)

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

                        Text("Every change automatically saves a numbered snapshot to your chosen folder — vault_backup_0.json, vault_backup_1.json, and so on. The number always increases so the highest number is always the freshest backup. The oldest files are removed once 10 snapshots exist.")
                            .font(Mono.T.mono(11, .regular))
                            .foregroundColor(Mono.C.textDim)
                            .lineSpacing(4)
                    }
                    .padding(Mono.S.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .monoCard()
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)

                    // Appearance section
                    SettingsSection(title: "Appearance") {
                        AppearanceToggleRow()
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

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

                    // Account section
                    SettingsSection(title: "Account") {
                        SettingsRow(icon: "arrow.counterclockwise.circle.fill", label: "Re-run Setup") {
                            EmptyView()
                        } action: {
                            showRerunConfirm = true
                            Haptic.medium()
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)

                    // Danger zone
                    SettingsSection(title: "Danger Zone") {
                        DangerButton(icon: "trash.fill", label: "Clear All Data") {
                            showClearConfirm = true
                            Haptic.medium()
                        }
                        .padding(Mono.S.sm)
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)

                    // Version info
                    VStack(spacing: 4) {
                        Text("MONOTARGETS")
                            .font(Mono.T.mono(11, .bold))
                            .foregroundColor(Mono.C.textDim)
                            .tracking(4)
                        Text("v1.0 · Built by tanaymalepati")
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
            refreshBackupInfo()
        }
        .sheet(isPresented: $showBudgets) {
            BudgetManagerView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Mono.C.bg)
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showFolderPicker) {
            DocumentPicker(mode: .folder) { url in
                showFolderPicker = false
                handleFolderSelection(url)
            } onCancel: {
                showFolderPicker = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showClearConfirm) {
            ClearDataConfirmSheet()
                .presentationDetents([.fraction(0.62)])
                .presentationDragIndicator(.hidden)
                .presentationBackground { Color(white: 0.035) }
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selected: $currencyCode)
                .presentationDetents([.fraction(0.72)])
                .presentationDragIndicator(.hidden)
                .presentationBackground { Color(white: 0.035) }
                .presentationCornerRadius(20)
        }
        .confirmationDialog("Re-run Setup?", isPresented: $showRerunConfirm, titleVisibility: .visible) {
            Button("Re-run Setup", role: .destructive) {
                onboardingDone = false
                Haptic.success()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restart the setup flow. Your data won't be deleted.")
        }
        .sheet(isPresented: $showRestorePicker) {
            DocumentPicker(mode: .jsonFile) { url in
                showRestorePicker = false
                handleRestore(url)
            } onCancel: {
                showRestorePicker = false
            }
            .ignoresSafeArea()
        }
    }

    private func handleFolderSelection(_ url: URL) {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }
        if let bookmark = BackupService.shared.createBookmark(for: url) {
            store.setBackupFolder(bookmark: bookmark)
            backupStatus = .success("Folder set ✓")
            Haptic.success()
            refreshBackupInfo()
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { backupStatus = .idle }
        }
    }

    private func handleRestore(_ url: URL) {
        if let vaultData = BackupService.shared.restoreFromURL(url) {
            store.transactions = vaultData.transactions
            store.savingsItems = vaultData.savingsItems
            store.save()
            backupStatus = .success("Restored ✓")
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
        refreshBackupInfo()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { backupStatus = .idle }
    }

    private func refreshBackupInfo() {
        liveBackupInfo = BackupService.shared.liveBackupInfo(bookmark: store.backupFolderBookmark)
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
                    .lineLimit(1)
                    .layoutPriority(1)

                Spacer()

                trailing
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Mono.C.textDim)
            }
            .frame(minHeight: 52)
            .padding(.horizontal, Mono.S.md)
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
                Text("MONOTARGETS")
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

// MARK: - Appearance Toggle

struct AppearanceToggleRow: View {
    @AppStorage("vault_monochrome") private var isMonochrome = false

    var body: some View {
        HStack(spacing: Mono.S.md) {
            Image(systemName: "circle.lefthalf.filled")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Mono.C.textSec)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text("Monochrome Mode")
                    .font(Mono.T.mono(15, .medium))
                    .foregroundColor(Mono.C.text)
                Text(isMonochrome ? "No color accents" : "Green accents on")
                    .font(Mono.T.mono(11, .regular))
                    .foregroundColor(Mono.C.textDim)
            }

            Spacer()

            MonochromeToggle()
        }
        .padding(Mono.S.md)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.spring(duration: 0.3, bounce: 0.3)) {
                isMonochrome.toggle()
            }
            Haptic.select()
        }
    }
}

// MARK: - Currency Picker Sheet

struct CurrencyPickerSheet: View {
    @Binding var selected: String
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Mono.C.borderBright)
                .frame(width: 40, height: 5)
                .padding(.top, 14)
                .padding(.bottom, Mono.S.md)

            HStack {
                Button("Cancel") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
                Spacer()
                Text("Currency")
                    .font(Mono.T.mono(15, .semibold))
                    .foregroundColor(Mono.C.text)
                Spacer()
                Text("Cancel").font(Mono.T.mono(14, .medium)).foregroundColor(.clear)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.md)

            MonoDivider()
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.lg)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(CurrencyInfo.all) { cur in
                    Button {
                        withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                            selected = cur.code
                        }
                        Haptic.select()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { dismiss() }
                    } label: {
                        VStack(spacing: 4) {
                            Text(cur.flag).font(.system(size: 26))
                            Text(cur.symbol)
                                .font(Mono.T.mono(14, .bold))
                                .foregroundColor(selected == cur.code ? Mono.C.bg : Mono.C.text)
                            Text(cur.code)
                                .font(Mono.T.mono(9, .semibold))
                                .foregroundColor(selected == cur.code ? Mono.C.bg.opacity(0.7) : Mono.C.textTert)
                                .tracking(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                .fill(selected == cur.code ? Mono.C.text : Mono.C.surfaceUp)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                        .strokeBorder(selected == cur.code ? .clear : Mono.C.border, lineWidth: 0.5)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, Mono.S.md)

            Spacer(minLength: Mono.S.lg)
        }
    }
}

struct MonochromeToggle: View {
    @AppStorage("vault_monochrome") private var isMonochrome = false

    var body: some View {
        ZStack(alignment: isMonochrome ? .trailing : .leading) {
            Capsule(style: .continuous)
                .fill(isMonochrome ? Mono.C.accent : Mono.C.surfaceTop)
                .frame(width: 50, height: 30)
                .shadow(
                    color: isMonochrome ? Mono.C.accent.opacity(0.55) : .clear,
                    radius: 10, x: 0, y: 0
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            isMonochrome ? Mono.C.accent.opacity(0.4) : Mono.C.border,
                            lineWidth: 0.5
                        )
                )

            Circle()
                .fill(isMonochrome ? Mono.C.bg : Mono.C.textDim)
                .frame(width: 24, height: 24)
                .padding(.horizontal, 3)
                .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
        }
        .animation(.spring(duration: 0.3, bounce: 0.3), value: isMonochrome)
    }
}

// MARK: - Clear Data Confirmation Sheet

struct ClearDataConfirmSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var confirmText = ""

    private let keyword = "monotargets"
    private var isConfirmed: Bool { confirmText == keyword }

    var body: some View {
        VStack(spacing: 0) {

            // Drag handle
            Capsule()
                .fill(Mono.C.borderBright)
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, Mono.S.md)

            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
                Spacer()
                Text("Clear All Data")
                    .font(Mono.T.mono(15, .semibold))
                    .foregroundColor(Mono.C.negative)
                Spacer()
                // Mirror Cancel for centering
                Text("Cancel")
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.lg)

            // Warning icon
            ZStack {
                RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                    .fill(Mono.C.negative.opacity(0.08))
                    .frame(width: 58, height: 58)
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Mono.C.negative)
            }
            .padding(.bottom, Mono.S.md)

            // Warning text
            Text("All transactions, goals, and assignments will be permanently deleted. This cannot be undone.")
                .font(Mono.T.mono(13, .regular))
                .foregroundColor(Mono.C.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Mono.S.xl)
                .padding(.bottom, Mono.S.xl)

            // Confirmation text field
            VStack(alignment: .leading, spacing: 6) {
                Text("Type \"\(keyword)\" to confirm")
                    .font(Mono.T.mono(11, .medium))
                    .foregroundColor(Mono.C.textDim)

                TextField("", text: $confirmText)
                    .font(Mono.T.mono(15, .regular))
                    .foregroundColor(isConfirmed ? Mono.C.negative : Mono.C.text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(Mono.S.md)
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .fill(Mono.C.surfaceUp)
                            .overlay(
                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                    .strokeBorder(
                                        isConfirmed ? Mono.C.negative.opacity(0.7) : Mono.C.border,
                                        lineWidth: isConfirmed ? 1.0 : 0.5
                                    )
                            )
                    )
                    .animation(.spring(duration: 0.25, bounce: 0.2), value: isConfirmed)
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.bottom, Mono.S.lg)

            // Delete button
            Button {
                guard isConfirmed else { Haptic.error(); return }
                store.clearAllData()
                Haptic.success()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 14))
                    Text("Delete Everything")
                        .font(Mono.T.mono(15, .semibold))
                }
                .foregroundColor(isConfirmed ? .white : Mono.C.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(isConfirmed ? Mono.C.negative : Mono.C.surfaceUp)
                        .overlay(
                            RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                .strokeBorder(
                                    isConfirmed ? .clear : Mono.C.border.opacity(0.5),
                                    lineWidth: 0.5
                                )
                        )
                )
                .animation(.spring(duration: 0.3, bounce: 0.2), value: isConfirmed)
            }
            .buttonStyle(.plain)
            .disabled(!isConfirmed)
            .padding(.horizontal, Mono.S.md)
            .padding(.bottom, Mono.S.xl)
        }
    }
}
