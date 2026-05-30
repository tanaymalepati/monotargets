import SwiftUI

struct SettingsView: View {
    @Environment(AppStore.self)  private var store
    @Environment(AuthState.self) private var authState
    @AppStorage("currency_code")     private var currencyCode = "INR"
    @AppStorage("smart_eta_enabled") private var etaEnabled   = true

    @State private var appeared           = false
    @State private var showCurrencyPicker = false
    @State private var showBudgets        = false
    @State private var showCustomCategories = false
    @State private var showClearConfirm   = false

    private var username: String { UserDefaults.standard.string(forKey: "user_name") ?? "" }

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: Mono.S.lg) {

                    AppHeaderCard()
                        .padding(.horizontal, Mono.S.md)
                        .padding(.top, Mono.S.sm)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.92)

                    // ── Account / Profile ────────────────────────────────────
                    SettingsSection(title: "Account") {
                        NavigationLink {
                            UserProfileView()
                                .environment(store)
                                .environment(authState)
                        } label: {
                            HStack(spacing: Mono.S.md) {
                                ZStack {
                                    Circle()
                                        .fill(Mono.C.accent.opacity(0.15))
                                        .frame(width: 38, height: 38)
                                    Text(String(username.prefix(1)).uppercased())
                                        .font(Mono.T.mono(16, .bold))
                                        .foregroundColor(Mono.C.accent)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("@\(username)")
                                        .font(Mono.T.mono(15, .semibold))
                                        .foregroundColor(Mono.C.text)
                                    HStack(spacing: 4) {
                                        Circle().fill(Mono.C.accent).frame(width: 5, height: 5)
                                        Text("Live sync enabled")
                                            .font(Mono.T.mono(11, .regular))
                                            .foregroundColor(Mono.C.accent)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Mono.C.textDim)
                            }
                            .frame(minHeight: 56)
                            .padding(.horizontal, Mono.S.md)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)

                    // ── Preferences ──────────────────────────────────────────
                    SettingsSection(title: "Preferences") {
                        SettingsRow(icon: "coloncurrencysign.circle.fill", label: "Currency") {
                            if let cur = CurrencyInfo.all.first(where: { $0.code == currencyCode }) {
                                HStack(spacing: 4) {
                                    Text(cur.flag)
                                    Text("\(cur.code) \(cur.symbol)")
                                        .font(Mono.T.mono(13, .medium)).foregroundColor(Mono.C.textSec)
                                }
                            }
                        } action: { showCurrencyPicker = true; Haptic.light() }

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        HStack(spacing: Mono.S.md) {
                            Image(systemName: "clock.arrow.2.circlepath")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Mono.C.textSec).frame(width: 22)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smart Goal ETA").font(Mono.T.mono(15, .medium)).foregroundColor(Mono.C.text)
                                Text("Estimated time to fund each goal")
                                    .font(Mono.T.mono(11, .regular)).foregroundColor(Mono.C.textDim)
                            }
                            Spacer()
                            Toggle("", isOn: $etaEnabled).tint(Mono.C.text).labelsHidden()
                                .onChange(of: etaEnabled) { _, _ in Haptic.select() }
                        }
                        .frame(minHeight: 52).padding(.horizontal, Mono.S.md)
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation { etaEnabled.toggle() }; Haptic.select() }

                        MonoDivider().padding(.horizontal, Mono.S.md)

                        SettingsRow(icon: "tag.fill", label: "Custom Categories") {
                            Text("\(store.customCategories.count) custom")
                                .font(Mono.T.mono(13, .regular)).foregroundColor(Mono.C.textSec)
                        } action: { showCustomCategories = true; Haptic.light() }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)

                    // ── Appearance ───────────────────────────────────────────
                    SettingsSection(title: "Appearance") { AppearanceToggleRow() }
                        .padding(.horizontal, Mono.S.md)
                        .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)

                    // ── Budgets ──────────────────────────────────────────────
                    SettingsSection(title: "Budgets") {
                        SettingsRow(icon: "chart.bar.fill", label: "Monthly Budgets") {
                            Text("\(store.budgets.count) set")
                                .font(Mono.T.mono(13, .regular)).foregroundColor(Mono.C.textSec)
                        } action: { showBudgets = true; Haptic.light() }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 16)

                    // ── Data stats ───────────────────────────────────────────
                    SettingsSection(title: "Data") {
                        StatRow(label: "Transactions", value: "\(store.transactions.count)")
                        MonoDivider().padding(.horizontal, Mono.S.md)
                        StatRow(label: "Goals", value: "\(store.savingsItems.count)")
                        MonoDivider().padding(.horizontal, Mono.S.md)
                        StatRow(label: "Completed Goals", value: "\(store.completedGoals)")
                        MonoDivider().padding(.horizontal, Mono.S.md)
                        StatRow(label: "Total Tracked", value: store.totalBalance.indianFormattedCompact)
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 20)

                    // ── Danger Zone ──────────────────────────────────────────
                    SettingsSection(title: "Danger Zone") {
                        DangerButton(icon: "trash.fill", label: "Clear All Data") {
                            showClearConfirm = true; Haptic.medium()
                        }
                        .padding(Mono.S.sm)
                    }
                    .padding(.horizontal, Mono.S.md)
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 4) {
                        Text("MONOTARGETS")
                            .font(Mono.T.mono(11, .bold)).foregroundColor(Mono.C.textDim).tracking(4)
                        Text("v1.0 · tanaymalepati")
                            .font(Mono.T.mono(10, .regular)).foregroundColor(Mono.C.textDim.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, Mono.S.xl)

                    Spacer(minLength: 60)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.2).delay(0.05)) { appeared = true }
        }
        .sheet(isPresented: $showCustomCategories) {
            CustomCategoriesView()
                .presentationDetents([.large]).presentationDragIndicator(.hidden)
                .presentationBackground(Mono.C.bg).presentationCornerRadius(24)
        }
        .sheet(isPresented: $showBudgets) {
            BudgetManagerView()
                .presentationDetents([.large]).presentationDragIndicator(.hidden)
                .presentationBackground(Mono.C.bg).presentationCornerRadius(24)
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(selected: $currencyCode)
                .presentationDetents([.fraction(0.72)]).presentationDragIndicator(.hidden)
                .presentationBackground { Color(white: 0.035) }.presentationCornerRadius(20)
        }
        .sheet(isPresented: $showClearConfirm) {
            ClearDataConfirmSheet()
                .environment(store).environment(authState)
                .presentationDetents([.fraction(0.62)]).presentationDragIndicator(.hidden)
                .presentationBackground { Color(white: 0.035) }.presentationCornerRadius(20)
        }
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
    @Environment(AppStore.self)  private var store
    @Environment(AuthState.self) private var authState
    @Environment(\.dismiss)      private var dismiss

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
                // Delete from Supabase, clear in-memory, sign out
                Task {
                    try? await SupabaseClient.shared.uploadVaultData(VaultData())
                    await store.clearAll()
                    Haptic.success()
                    dismiss()
                }
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
