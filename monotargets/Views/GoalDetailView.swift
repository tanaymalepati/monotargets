import SwiftUI

struct GoalDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let itemID: UUID

    @State private var showAssign = false
    @State private var showEdit = false
    @State private var appeared = false
    @State private var showDeleteConfirm = false
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
                        HStack(spacing: 10) {
                            if !item.isFullyFunded {
                                ActionButton(
                                    icon: "arrow.right.circle.fill",
                                    label: "Assign Funds",
                                    filled: true
                                ) {
                                    showAssign = true
                                    Haptic.medium()
                                }
                            } else {
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
                                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                        .fill(Mono.C.text)
                                )
                            }

                            ActionButton(
                                icon: "pencil.circle.fill",
                                label: "Edit",
                                filled: false
                            ) {
                                showEdit = true
                                Haptic.light()
                            }
                        }
                        .padding(.horizontal, Mono.S.md)
                        .opacity(appeared ? 1 : 0)

                        // Stats grid
                        GoalStatsGrid(item: item)
                            .padding(.horizontal, Mono.S.md)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)

                        // Transaction history for this goal
                        if !store.transactionsForItem(itemID).isEmpty {
                            GoalTransactionHistory(itemID: itemID)
                                .padding(.horizontal, Mono.S.md)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 24)
                        }

                        // Unassign / Delete
                        VStack(spacing: 8) {
                            if item.assignedAmount > 0 {
                                DangerButton(
                                    icon: "arrow.left.circle",
                                    label: "Unassign All Funds"
                                ) {
                                    store.unassignFunds(from: itemID, amount: item.assignedAmount)
                                    Haptic.medium()
                                }
                            }
                            DangerButton(icon: "trash", label: "Delete Goal") {
                                showDeleteConfirm = true
                            }
                        }
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
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Mono.C.bg)
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
        .confirmationDialog("Delete this goal?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Goal", role: .destructive) {
                store.deleteSavingsItem(id: itemID)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
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
                    Circle()
                        .fill(item.isFullyFunded ? Mono.C.text : Mono.C.surfaceUp)
                        .frame(width: 74, height: 74)

                    Image(systemName: item.icon)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(item.isFullyFunded ? Mono.C.bg : Mono.C.textSec)
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

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.md) {
            OverlineLabel(text: "Transactions", opacity: 0.45)
                .padding(.horizontal, 4)

            VStack(spacing: 1) {
                ForEach(Array(store.transactionsForItem(itemID).prefix(8).enumerated()), id: \.element.id) { index, t in
                    TransactionRowView(transaction: t)
                        .padding(.horizontal, Mono.S.md)
                    if index < store.transactionsForItem(itemID).prefix(8).count - 1 {
                        MonoDivider().padding(.horizontal, Mono.S.lg)
                    }
                }
            }
            .monoCard()
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String
    var filled: Bool = false
    let action: () -> Void

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
                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                    .fill(filled ? Mono.C.text : Mono.C.surfaceUp)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .strokeBorder(filled ? .clear : Mono.C.border, lineWidth: 0.5)
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
                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                    .fill(Mono.C.surfaceUp)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .strokeBorder(Mono.C.border.opacity(0.5), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
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
