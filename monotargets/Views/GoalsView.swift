import SwiftUI

struct GoalsView: View {
    @Environment(AppStore.self) private var store
    @State private var showCreateGoal = false
    @State private var selectedItem: SavingsItem?
    @State private var appeared = false

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Mono.S.md) {
                    // Header stats
                    GoalStatsHeader()
                        .padding(.horizontal, Mono.S.md)
                        .padding(.top, Mono.S.sm)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    if store.savingsItems.isEmpty {
                        EmptyStateCard(
                            icon: "target",
                            title: "No goals yet",
                            subtitle: "Create your first savings goal\nto start tracking"
                        )
                        .padding(.horizontal, Mono.S.md)
                        .padding(.top, Mono.S.xl)
                    } else {
                        ForEach(Array(store.savingsItems.enumerated()), id: \.element.id) { index, item in
                            GoalCard(item: item) {
                                selectedItem = item
                            }
                            .padding(.horizontal, Mono.S.md)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 24 + CGFloat(index * 8))
                            .animation(
                                .spring(duration: 0.5, bounce: 0.3).delay(0.1 + Double(index) * 0.07),
                                value: appeared
                            )
                        }
                    }

                    Spacer(minLength: 100)
                }
            }

            // FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showCreateGoal = true
                        Haptic.medium()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .bold))
                            Text("New Goal")
                                .font(Mono.T.mono(14, .semibold))
                        }
                        .foregroundColor(Mono.C.bg)
                        .padding(.horizontal, Mono.S.lg)
                        .padding(.vertical, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Mono.C.text)
                                .shadow(color: .white.opacity(0.15), radius: 16)
                                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, Mono.S.lg)
                    .padding(.bottom, 16)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.2).delay(0.05)) {
                appeared = true
            }
        }
        .sheet(isPresented: $showCreateGoal) {
            CreateGoalView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Mono.C.bg)
        }
        .navigationDestination(item: $selectedItem) { item in
            GoalDetailView(itemID: item.id)
        }
    }
}

// MARK: - Goal Stats Header

struct GoalStatsHeader: View {
    @Environment(AppStore.self) private var store

    private var totalGoalAmount: Double {
        store.savingsItems.reduce(0) { $0 + $1.targetAmount }
    }
    private var totalFunded: Double {
        store.savingsItems.reduce(0) { $0 + $1.assignedAmount }
    }
    private var overallProgress: Double {
        totalGoalAmount > 0 ? min(totalFunded / totalGoalAmount, 1.0) : 0
    }

    var body: some View {
        VStack(spacing: Mono.S.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    OverlineLabel(text: "Overall Progress")
                    Text("\(Int(overallProgress * 100))% funded")
                        .font(Mono.T.mono(26, .bold))
                        .foregroundColor(Mono.C.text)
                }
                Spacer()
                ProgressRing(progress: overallProgress, size: 56, lineWidth: 4)
            }

            MonoProgressBar(progress: overallProgress, height: 5, showLabel: false)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    OverlineLabel(text: "Funded")
                    Text(totalFunded.indianFormattedCompact)
                        .font(Mono.T.mono(16, .semibold))
                        .foregroundColor(Mono.C.text)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    OverlineLabel(text: "Target")
                    Text(totalGoalAmount.indianFormattedCompact)
                        .font(Mono.T.mono(16, .semibold))
                        .foregroundColor(Mono.C.textSec)
                }
            }
        }
        .padding(Mono.S.lg)
        .monoHeroCard()
    }
}

// MARK: - Goal Card

struct GoalCard: View {
    let item: SavingsItem
    let onTap: () -> Void

    @State private var pressed = false

    var body: some View {
        Button(action: {
            onTap()
            Haptic.light()
        }) {
            VStack(spacing: Mono.S.md) {
                // Top row: icon + name + progress ring
                HStack(alignment: .center, spacing: Mono.S.md) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                            .fill(item.isFullyFunded ? Mono.C.text : Mono.C.surfaceTop)
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                    .strokeBorder(Mono.C.border, lineWidth: 0.5)
                            )

                        Image(systemName: item.icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(item.isFullyFunded ? Mono.C.bg : Mono.C.textSec)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(item.name)
                                .font(Mono.T.mono(16, .semibold))
                                .foregroundColor(Mono.C.text)

                            if item.isFullyFunded {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Mono.C.positive)
                            }
                        }

                        if !item.itemDescription.isEmpty {
                            Text(item.itemDescription)
                                .font(Mono.T.mono(12, .regular))
                                .foregroundColor(Mono.C.textTert)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    ProgressRing(progress: item.progress, size: 44, lineWidth: 3.5)
                }

                // Amount row
                HStack(alignment: .lastTextBaseline) {
                    Text(item.assignedAmount.indianFormatted)
                        .font(Mono.T.mono(20, .bold))
                        .foregroundColor(Mono.C.text)

                    Text("/ \(item.targetAmount.indianFormatted)")
                        .font(Mono.T.mono(14, .regular))
                        .foregroundColor(Mono.C.textTert)

                    Spacer()

                    Text("\(Int(item.progress * 100))%")
                        .font(Mono.T.mono(14, .semibold))
                        .foregroundColor(Mono.C.textSec)
                }

                // Progress bar
                MonoProgressBar(progress: item.progress, height: 4)

                // Bottom row: date info
                HStack {
                    if let targetDate = item.targetDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 10, weight: .medium))
                            Text(VaultDateFormatter.display.string(from: targetDate))
                                .font(Mono.T.mono(11, .regular))
                        }
                        .foregroundColor(Mono.C.textDim)

                        Spacer()

                        let days = item.daysUntilTarget ?? 0
                        Text(VaultDateFormatter.daysRemaining(targetDate))
                            .font(Mono.T.mono(11, .medium))
                            .foregroundColor(days < 0 ? Mono.C.negative : (days <= 30 ? Mono.C.textSec : Mono.C.textDim))
                    } else {
                        Text("No target date")
                            .font(Mono.T.mono(11, .regular))
                            .foregroundColor(Mono.C.textDim)

                        Spacer()

                        Text(item.remaining.indianFormattedCompact + " remaining")
                            .font(Mono.T.mono(11, .regular))
                            .foregroundColor(Mono.C.textDim)
                    }
                }
            }
            .padding(Mono.S.lg)
            .monoCard(elevated: true)
            .scaleEffect(pressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !pressed {
                        withAnimation(.spring(duration: 0.12, bounce: 0.4)) { pressed = true }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(duration: 0.25, bounce: 0.5)) { pressed = false }
                }
        )
    }
}
