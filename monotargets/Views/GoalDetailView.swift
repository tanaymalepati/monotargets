import SwiftUI

struct GoalDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let itemID: UUID

    @State private var showAssign = false
    @State private var showUnassign = false
    @State private var showEdit = false
    @State private var appeared = false
    @State private var itemToDelete: SavingsItem?
    @AppStorage("vault_monochrome") private var isMonochrome = false
    @State private var showDeleteZone = false
    @State private var celebrateComplete = false

    private var item: SavingsItem? {
        store.savingsItems.first { $0.id == itemID }
    }

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            if let item {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Mono.S.lg) {
                        // Hero section
                        GoalDetailHero(item: item)
                            .padding(.horizontal, Mono.S.md)
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.93)

                        // Action buttons
                        Group {
                            if item.isFullyFunded {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Fully Funded!")
                                        .font(Mono.T.mono(13, .semibold))
                                }
                                .foregroundColor(Mono.C.bg)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                        .fill(Mono.C.text)
                                )
                            } else if item.assignedAmount > 0 {
                                // Side-by-side Unassign (red) + Assign (green)
                                HStack(spacing: Mono.S.sm) {
                                    Button {
                                        showUnassign = true
                                        Haptic.medium()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.left.circle.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text("Unassign")
                                                .font(Mono.T.mono(14, .semibold))
                                        }
                                        .foregroundColor(isMonochrome ? Mono.C.negative : Mono.C.red)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                                .fill(Mono.C.surfaceUp)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                                        .strokeBorder(
                                                            isMonochrome ? Mono.C.negative.opacity(0.4) : Mono.C.red.opacity(0.85),
                                                            lineWidth: 1.0
                                                        )
                                                )
                                                .shadow(
                                                    color: isMonochrome ? .clear : Mono.C.red.opacity(0.28),
                                                    radius: 10, x: -4, y: 0
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        showAssign = true
                                        Haptic.medium()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.right.circle.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                            Text("Assign")
                                                .font(Mono.T.mono(14, .semibold))
                                        }
                                        .foregroundColor(isMonochrome ? Mono.C.text : Mono.C.accent)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                                .fill(Mono.C.surfaceUp)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                                            .strokeBorder(
                                                            isMonochrome ? Mono.C.borderBright : Mono.C.accent.opacity(0.85),
                                                            lineWidth: 1.0
                                                        )
                                                )
                                                .shadow(
                                                    color: isMonochrome ? .clear : Mono.C.accent.opacity(0.22),
                                                    radius: 10, x: 4, y: 0
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            } else {
                                // No funds assigned yet — full-width green Assign
                                ActionButton(
                                    icon: "arrow.right.circle.fill",
                                    label: "Assign Funds",
                                    filled: true,
                                    isAccent: true
                                ) {
                                    showAssign = true
                                    Haptic.medium()
                                }
                            }
                        }
                        .padding(.horizontal, Mono.S.md)
                        .opacity(appeared ? 1 : 0)

                        // Stats grid
                        GoalStatsGrid(item: item)
                            .padding(.horizontal, Mono.S.md)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)

                        // Goal Boost section
                        if !item.isFullyFunded {
                            GoalBoostSection(item: item)
                                .padding(.horizontal, Mono.S.md)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 20)
                        }

                        // Transaction history for this goal
                        if !store.transactionsForItem(itemID).isEmpty {
                            GoalTransactionHistory(itemID: itemID)
                                .padding(.horizontal, Mono.S.md)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 24)
                        }

                        // Reminder section
                        GoalReminderSection(item: item)
                            .padding(.horizontal, Mono.S.md)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24)
                            .id("\(item.id)-\(item.monthlyReminderDay ?? -1)")

                        // Delete zone
                        VStack(spacing: 8) {
                            if showDeleteZone {
                                DangerButton(icon: "trash", label: "Delete Goal") {
                                    itemToDelete = item
                                }
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .animation(.spring(duration: 0.35, bounce: 0.2), value: showDeleteZone)
                        .padding(.horizontal, Mono.S.md)
                        .opacity(appeared ? 1 : 0)

                        Spacer(minLength: 100)
                    }
                    .padding(.top, Mono.S.sm)
                }

                // Celebration overlay
                if celebrateComplete {
                    CelebrationView()
                        .transition(.opacity)
                }
            } else {
                Text("Goal not found")
                    .font(Mono.T.body)
                    .foregroundColor(Mono.C.textSec)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(item?.name ?? "Goal")
                    .font(Mono.T.mono(16, .semibold))
                    .foregroundColor(Mono.C.text)
            }
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if let item {
                    Button {
                        var updated = item
                        updated.isFavorite.toggle()
                        store.updateSavingsItem(updated)
                        Haptic.select()
                    } label: {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(item.isFavorite ? Mono.C.accent : Mono.C.textSec)
                    }

                    Button {
                        showEdit = true
                        showDeleteZone = true
                        Haptic.light()
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Mono.C.textSec)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.05)) {
                appeared = true
            }
        }
        .onChange(of: item?.isFullyFunded) { _, newVal in
            if newVal == true {
                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                    celebrateComplete = true
                }
                Haptic.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { celebrateComplete = false }
                }
            }
        }
        .sheet(isPresented: $showAssign) {
            if let item {
                AssignFundsView(item: item)
                    .presentationDetents([.fraction(0.88)])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground {
                        Color(white: 0.035)
                    }
                    .presentationCornerRadius(20)
            }
        }
        .sheet(isPresented: $showUnassign) {
            if let item {
                UnassignFundsView(item: item)
                    .presentationDetents([.fraction(0.88)])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground {
                        Color(white: 0.035)
                    }
                    .presentationCornerRadius(20)
            }
        }
        .sheet(isPresented: $showEdit) {
            if let item {
                CreateGoalView(editingItem: item)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Mono.C.bg)
            }
        }
        .sheet(item: $itemToDelete) { snap in
            DeleteGoalConfirmSheet(item: snap)
                .presentationDetents([.fraction(0.65)])
                .presentationDragIndicator(.hidden)
                .presentationBackground {
                    Color(white: 0.035)
                }
                .presentationCornerRadius(20)
        }
        .onChange(of: item?.id) { _, newID in
            if newID == nil { dismiss() }
        }
    }
}

// MARK: - Detail Hero

struct GoalDetailHero: View {
    let item: SavingsItem

    var body: some View {
        VStack(spacing: Mono.S.md) {
            // Icon + ring
            ZStack {
                ProgressRing(progress: item.progress, size: 100, lineWidth: 5)

                ZStack {
                    if let data = item.photoData, let uiImg = UIImage(data: data) {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 74, height: 74)
                            .clipShape(Circle())
                            .overlay(
                                Circle().strokeBorder(Mono.C.borderBright.opacity(0.4), lineWidth: 0.5)
                            )
                    } else {
                        Circle()
                            .fill(item.isFullyFunded ? Mono.C.text : Mono.C.surfaceUp)
                            .frame(width: 74, height: 74)

                        Image(systemName: item.icon)
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(item.isFullyFunded ? Mono.C.bg : Mono.C.textSec)
                    }
                }
            }
            .padding(.top, Mono.S.md)

            // Name
            Text(item.name)
                .font(Mono.T.mono(24, .bold))
                .foregroundColor(Mono.C.text)
                .multilineTextAlignment(.center)

            if !item.itemDescription.isEmpty {
                Text(item.itemDescription)
                    .font(Mono.T.mono(14, .regular))
                    .foregroundColor(Mono.C.textTert)
                    .multilineTextAlignment(.center)
            }

            // Amount progress
            VStack(spacing: Mono.S.sm) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(item.assignedAmount.indianFormatted)
                        .font(Mono.T.mono(34, .bold))
                        .foregroundColor(Mono.C.text)

                    Text("/ \(item.targetAmount.indianFormatted)")
                        .font(Mono.T.mono(16, .regular))
                        .foregroundColor(Mono.C.textTert)
                }

                MonoProgressBar(progress: item.progress, height: 6, showLabel: true)
                    .padding(.horizontal, Mono.S.xl)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.sm)
        }
        .frame(maxWidth: .infinity)
        .monoHeroCard()
    }
}

// MARK: - Stats Grid

struct GoalStatsGrid: View {
    let item: SavingsItem

    @Environment(AppStore.self) private var store
    @AppStorage("smart_eta_enabled") private var etaEnabled = true

    var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: 1) {
                StatCell(label: "Remaining", value: item.remaining.indianFormattedCompact, icon: "arrow.up.right")
                    .frame(maxWidth: .infinity)
                Rectangle().fill(Mono.C.border).frame(width: 0.5)
                StatCell(label: "Progress", value: "\(Int(item.progress * 100))%", icon: "chart.bar")
                    .frame(maxWidth: .infinity)
            }

            MonoDivider()

            HStack(spacing: 1) {
                if let targetDate = item.targetDate {
                    StatCell(
                        label: "Target Date",
                        value: VaultDateFormatter.short.string(from: targetDate),
                        icon: "calendar"
                    )
                    .frame(maxWidth: .infinity)
                    Rectangle().fill(Mono.C.border).frame(width: 0.5)
                    StatCell(
                        label: "Time Left",
                        value: VaultDateFormatter.daysRemaining(targetDate),
                        icon: "clock"
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    StatCell(label: "Target Date", value: "Not set", icon: "calendar")
                        .frame(maxWidth: .infinity)
                    Rectangle().fill(Mono.C.border).frame(width: 0.5)
                    StatCell(label: "Created", value: VaultDateFormatter.short.string(from: item.createdAt), icon: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
            }

            if etaEnabled, !item.isFullyFunded, let eta = store.goalETA(for: item.id) {
                MonoDivider()
                StatCell(label: "Smart ETA", value: eta, icon: "clock.arrow.2.circlepath")
                    .frame(maxWidth: .infinity)
            }
        }
        .monoCard()
    }
}

struct StatCell: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Mono.C.textDim)
                OverlineLabel(text: label)
            }
            Text(value)
                .font(Mono.T.mono(18, .semibold))
                .foregroundColor(Mono.C.text)
        }
        .padding(Mono.S.md)
    }
}

// MARK: - Goal Transaction History

struct GoalTransactionHistory: View {
    @Environment(AppStore.self) private var store
    let itemID: UUID

    private var transactions: [Transaction] {
        Array(store.transactionsForItem(itemID).prefix(8))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.md) {
            OverlineLabel(text: "Transactions", opacity: 0.45)
                .padding(.horizontal, 4)

            VStack(spacing: 1) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, t in
                    TransactionRowView(transaction: t)
                        .padding(.horizontal, Mono.S.md)
                    if index < transactions.count - 1 {
                        MonoDivider().padding(.horizontal, Mono.S.lg)
                    }
                }
            }
            .monoCard()
        }
    }
}

// MARK: - Reminder Section

struct GoalReminderSection: View {
    @Environment(AppStore.self) private var store
    let item: SavingsItem

    @State private var isEnabled: Bool
    @State private var day: Int

    init(item: SavingsItem) {
        self.item = item
        _isEnabled = State(initialValue: item.monthlyReminderDay != nil)
        _day       = State(initialValue: item.monthlyReminderDay ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.md) {
            OverlineLabel(text: "Reminders", opacity: 0.45)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                // Toggle row
                HStack(spacing: Mono.S.md) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Mono.C.textSec)
                        .frame(width: 22)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Monthly Reminder")
                            .font(Mono.T.mono(15, .medium))
                            .foregroundColor(Mono.C.text)
                        Text(isEnabled ? "Reminds you on the \(ordinal(day)) of each month" : "Off")
                            .font(Mono.T.mono(11, .regular))
                            .foregroundColor(Mono.C.textDim)
                    }

                    Spacer()

                    Toggle("", isOn: $isEnabled)
                        .tint(Mono.C.text)
                        .labelsHidden()
                        .onChange(of: isEnabled) { _, enabled in
                            var updated = item
                            if enabled {
                                store.requestNotificationPermission()
                                updated.monthlyReminderDay = day
                                store.updateSavingsItem(updated)
                                store.scheduleReminder(for: updated)
                            } else {
                                updated.monthlyReminderDay = nil
                                store.updateSavingsItem(updated)
                                store.cancelReminder(for: item.id)
                            }
                            Haptic.select()
                        }
                }
                .padding(Mono.S.md)

                if isEnabled {
                    MonoDivider().padding(.horizontal, Mono.S.md)

                    // Day picker row
                    HStack(spacing: Mono.S.md) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Mono.C.textSec)
                            .frame(width: 22)

                        Text("Remind on day")
                            .font(Mono.T.mono(15, .medium))
                            .foregroundColor(Mono.C.text)

                        Spacer()

                        // Minus
                        Button {
                            if day > 1 {
                                day -= 1
                                commitDayChange()
                                Haptic.light()
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(Mono.C.textSec)
                        }
                        .buttonStyle(.plain)

                        Text("\(day)")
                            .font(Mono.T.mono(20, .bold))
                            .foregroundColor(Mono.C.text)
                            .frame(width: 32, alignment: .center)

                        // Plus
                        Button {
                            if day < 28 {
                                day += 1
                                commitDayChange()
                                Haptic.light()
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(Mono.C.textSec)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(Mono.S.md)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .monoCard()
            .animation(.spring(duration: 0.3, bounce: 0.2), value: isEnabled)
        }
    }

    private func commitDayChange() {
        var updated = item
        updated.monthlyReminderDay = day
        store.updateSavingsItem(updated)
        store.scheduleReminder(for: updated)
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        switch n % 10 {
        case 1 where n % 100 != 11: suffix = "st"
        case 2 where n % 100 != 12: suffix = "nd"
        case 3 where n % 100 != 13: suffix = "rd"
        default: suffix = "th"
        }
        return "\(n)\(suffix)"
    }
}

// MARK: - Goal Boost Section

struct GoalBoostSection: View {
    @Environment(AppStore.self) private var store
    let item: SavingsItem

    @State private var showBoostSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.md) {
            OverlineLabel(text: "Goal Boost", opacity: 0.45)
                .padding(.horizontal, 4)

            if item.isBoostActive {
                // Active boost state
                VStack(spacing: 0) {
                    HStack(spacing: Mono.S.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                                .fill(Mono.C.accent.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Mono.C.accent)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Boost Active")
                                .font(Mono.T.mono(14, .semibold))
                                .foregroundColor(Mono.C.text)
                            if let target = item.boostTarget {
                                Text("Target: \(target.indianFormattedCompact) in \(item.boostDaysRemaining)d")
                                    .font(Mono.T.mono(11, .regular))
                                    .foregroundColor(Mono.C.textTert)
                            }
                        }

                        Spacer()

                        Text("\(item.boostDaysRemaining)d")
                            .font(Mono.T.mono(18, .bold))
                            .foregroundColor(item.boostDaysRemaining <= 2 ? Mono.C.red : Mono.C.accent)
                    }
                    .padding(Mono.S.md)

                    MonoDivider().padding(.horizontal, Mono.S.md)

                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            store.clearBoost(for: item.id)
                        }
                        Haptic.medium()
                    } label: {
                        Text("End Boost")
                            .font(Mono.T.mono(12, .medium))
                            .foregroundColor(Mono.C.textTert)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                }
                .monoCard()
                .overlay(
                    RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                        .strokeBorder(Mono.C.accent.opacity(0.4), lineWidth: 1)
                )
            } else {
                // Inactive — invite to boost
                Button {
                    showBoostSheet = true
                    Haptic.medium()
                } label: {
                    HStack(spacing: Mono.S.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                                .fill(Mono.C.surfaceUp)
                                .frame(width: 44, height: 44)
                            Image(systemName: "bolt")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Mono.C.textTert)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Start a 7-Day Boost")
                                .font(Mono.T.mono(14, .semibold))
                                .foregroundColor(Mono.C.text)
                            Text("Commit to a target amount in 7 days")
                                .font(Mono.T.mono(11, .regular))
                                .foregroundColor(Mono.C.textTert)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Mono.C.textDim)
                    }
                    .padding(Mono.S.md)
                    .monoCard()
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(isPresented: $showBoostSheet) {
            GoalBoostSetupSheet(item: item)
                .presentationDetents([.fraction(0.55)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Color(white: 0.065))
                .presentationCornerRadius(24)
        }
    }
}

// MARK: - Boost Setup Sheet

struct GoalBoostSetupSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let item: SavingsItem

    @State private var digits = ""

    private var amount: Double { AmountFormatter.toDoubleFromDigits(digits) }
    private var isValid: Bool  { amount > 0 && amount <= item.remaining }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(white: 0.40))
                .frame(width: 44, height: 6)
                .padding(.top, 14)
                .padding(.bottom, 16)

            HStack {
                Text("7-Day Boost")
                    .font(Mono.T.mono(16, .bold))
                    .foregroundColor(Mono.C.text)
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.sm)

            Text("Commit to saving \(item.name.isEmpty ? "this goal" : item.name) by a target amount within 7 days.")
                .font(Mono.T.mono(12, .regular))
                .foregroundColor(Mono.C.textTert)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Mono.S.xl)
                .padding(.bottom, Mono.S.md)

            AmountInputField(digits: $digits, fontSize: 44)
                .padding(.horizontal, Mono.S.xl)
                .padding(.bottom, Mono.S.md)

            // Quick amounts
            HStack(spacing: 8) {
                ForEach([item.remaining * 0.25, item.remaining * 0.5, item.remaining], id: \.self) { amt in
                    QuickAmountPill(amount: amt) {
                        withAnimation(.spring(duration: 0.2)) { digits = String(Int(amt)) }
                        Haptic.light()
                    }
                }
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.bottom, Mono.S.lg)

            Button {
                guard isValid else { Haptic.error(); return }
                store.activateBoost(for: item.id, target: amount)
                Haptic.success()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "bolt.fill").font(.system(size: 14))
                    Text("Start Boost").font(Mono.T.mono(15, .semibold))
                }
                .foregroundColor(isValid ? Mono.C.bg : Mono.C.textTert)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                        .fill(isValid ? Mono.C.accent : Mono.C.surfaceTop)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Mono.S.lg)
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String
    var filled: Bool = false
    var isAccent: Bool = false
    let action: () -> Void

    @AppStorage("vault_monochrome") private var isMonochrome = false

    private var activeFill: Color {
        guard filled else { return Mono.C.surfaceUp }
        return (isAccent && !isMonochrome) ? Mono.C.accent : Mono.C.text
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(Mono.T.mono(14, .semibold))
            }
            .foregroundColor(filled ? Mono.C.bg : Mono.C.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                    .fill(activeFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                            .strokeBorder(filled ? .clear : Mono.C.border, lineWidth: 0.5)
                    )
                    .shadow(
                        color: (filled && isAccent && !isMonochrome) ? Mono.C.accent.opacity(0.5) : .clear,
                        radius: 14, x: 0, y: 0
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct DangerButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(Mono.T.mono(13, .medium))
            }
            .foregroundColor(Mono.C.negative)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                    .fill(Mono.C.surfaceUp)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                            .strokeBorder(Mono.C.border.opacity(0.5), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Delete Goal Confirmation Sheet

struct DeleteGoalConfirmSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: SavingsItem

    @State private var confirmText = ""

    private var isConfirmed: Bool { confirmText == item.name }

    var body: some View {
        VStack(spacing: 0) {

            Capsule()
                .fill(Mono.C.borderBright)
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, Mono.S.md)

            HStack {
                Button("Cancel") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
                Spacer()
                Text("Delete Goal")
                    .font(Mono.T.mono(15, .semibold))
                    .foregroundColor(Mono.C.negative)
                Spacer()
                Text("Cancel").font(Mono.T.mono(14, .medium)).foregroundColor(.clear)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.lg)

            ZStack {
                RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                    .fill(Mono.C.negative.opacity(0.08))
                    .frame(width: 58, height: 58)
                Image(systemName: "trash.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Mono.C.negative)
            }
            .padding(.bottom, Mono.S.md)

            Text("This goal and all its fund assignments will be permanently deleted.")
                .font(Mono.T.mono(13, .regular))
                .foregroundColor(Mono.C.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Mono.S.xl)
                .padding(.bottom, Mono.S.xl)

            VStack(alignment: .leading, spacing: 6) {
                Text("Type \"\(item.name)\" to confirm")
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

            Button {
                guard isConfirmed else { Haptic.error(); return }
                store.deleteSavingsItem(id: item.id)
                Haptic.success()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill").font(.system(size: 14))
                    Text("Delete Goal").font(Mono.T.mono(15, .semibold))
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

// MARK: - Celebration View

struct CelebrationView: View {
    @State private var particles: [ParticleData] = []
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    struct ParticleData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: CGFloat
        var opacity: Double
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: Mono.S.lg) {
                ZStack {
                    ForEach(particles) { p in
                        Circle()
                            .fill(Mono.C.text.opacity(p.opacity))
                            .frame(width: p.size)
                            .offset(x: p.x, y: p.y)
                    }

                    VStack(spacing: Mono.S.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(Mono.C.text)

                        Text("GOAL FUNDED!")
                            .font(Mono.T.mono(22, .bold))
                            .foregroundColor(Mono.C.text)
                            .tracking(3)
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                }
            }
        }
        .onAppear {
            particles = (0..<20).map { _ in
                ParticleData(
                    x: CGFloat.random(in: -120...120),
                    y: CGFloat.random(in: -100...100),
                    size: CGFloat.random(in: 4...12),
                    speed: CGFloat.random(in: 0.3...1.0),
                    opacity: Double.random(in: 0.4...1.0)
                )
            }
            withAnimation(.spring(duration: 0.5, bounce: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
