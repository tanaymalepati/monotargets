import SwiftUI

struct GoalsView: View {
    @Environment(AppStore.self) private var store
    @State private var showCreateGoal = false
    @State private var selectedItem: SavingsItem?
    @State private var appeared = false
    @State private var selectedSegment = 0
    @Namespace private var zoomNamespace

    private var inProgressItems: [SavingsItem] { store.savingsItems.filter { !$0.isFullyFunded && !$0.isCompleted } }
    private var fundedItems: [SavingsItem]     { store.savingsItems.filter { $0.isFullyFunded && !$0.isCompleted } }
    private var completedItems: [SavingsItem]  { store.savingsItems.filter { $0.isCompleted }.sorted { $0.createdAt > $1.createdAt } }

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

                    Picker("", selection: $selectedSegment) {
                        Text("Active").tag(0)
                        Text("Completed").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, Mono.S.md)

                    if selectedSegment == 0 {
                        if store.savingsItems.isEmpty {
                            EmptyStateCard(
                                icon: "target",
                                title: "No goals yet",
                                subtitle: "Create your first savings goal\nto start tracking"
                            )
                            .padding(.horizontal, Mono.S.md)
                            .padding(.top, Mono.S.xl)
                        } else {
                            // In-progress goals
                            ForEach(Array(inProgressItems.enumerated()), id: \.element.id) { index, item in
                                GoalCard(item: item, namespace: zoomNamespace) { selectedItem = item }
                                    .padding(.horizontal, Mono.S.md)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 24 + CGFloat(index * 8))
                                    .animation(
                                        .spring(duration: 0.5, bounce: 0.3).delay(0.1 + Double(index) * 0.07),
                                        value: appeared
                                    )
                            }

                            // Separator between in-progress and funded
                            if !fundedItems.isEmpty && !inProgressItems.isEmpty {
                                HStack(spacing: Mono.S.sm) {
                                    Rectangle()
                                        .fill(Mono.C.border)
                                        .frame(height: 0.5)
                                    OverlineLabel(text: "Funded", opacity: 0.35)
                                    Rectangle()
                                        .fill(Mono.C.border)
                                        .frame(height: 0.5)
                                }
                                .padding(.horizontal, Mono.S.md)
                                .opacity(appeared ? 1 : 0)
                            }

                            // Funded goals
                            ForEach(Array(fundedItems.enumerated()), id: \.element.id) { index, item in
                                GoalCard(item: item, namespace: zoomNamespace) { selectedItem = item }
                                    .padding(.horizontal, Mono.S.md)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 24 + CGFloat(index * 8))
                                    .animation(
                                        .spring(duration: 0.5, bounce: 0.3)
                                            .delay(0.1 + Double(index + inProgressItems.count) * 0.07),
                                        value: appeared
                                    )
                            }
                        }
                    } else {
                        if completedItems.isEmpty {
                            EmptyStateCard(
                                icon: "checkmark.circle",
                                title: "No completed goals",
                                subtitle: "Goals will appear here once\nyou confirm their completion"
                            )
                            .padding(.horizontal, Mono.S.md)
                            .padding(.top, Mono.S.xl)
                        } else {
                            ForEach(completedItems) { item in
                                CompletedGoalCard(item: item)
                                    .padding(.horizontal, Mono.S.md)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedItem = item
                                        Haptic.medium()
                                    }
                            }
                        }
                    }

                    Spacer(minLength: 100)
                }
            }

            // FAB
            if selectedSegment == 0 {
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
                        .padding(.bottom, 96)
                    }
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
        .sheet(item: $selectedItem) { item in
            NavigationStack {
                GoalDetailView(itemID: item.id)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Mono.C.bg)
            .presentationCornerRadius(20)
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
    let namespace: Namespace.ID
    let onTap: () -> Void

    @Environment(AppStore.self) private var store
    @AppStorage("smart_eta_enabled") private var etaEnabled = true

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
                        if etaEnabled, !item.isFullyFunded, let eta = store.goalETA(for: item.id) {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10, weight: .medium))
                                Text(eta)
                                    .font(Mono.T.mono(11, .medium))
                            }
                            .foregroundColor(Mono.C.textDim)
                        } else {
                            Text("No target date")
                                .font(Mono.T.mono(11, .regular))
                                .foregroundColor(Mono.C.textDim)
                        }

                        Spacer()

                        Text(item.remaining.indianFormattedCompact + " remaining")
                            .font(Mono.T.mono(11, .regular))
                            .foregroundColor(Mono.C.textDim)
                    }
                }
            }
            .padding(Mono.S.lg)
            .monoCard(elevated: true)
            .matchedTransitionSource(id: item.id, in: namespace)
        }
        .buttonStyle(CardPressStyle())
    }
}

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(duration: 0.18, bounce: 0.4), value: configuration.isPressed)
    }
}

// MARK: - Completed Goal Card

struct CompletedGoalCard: View {
    @Environment(AppStore.self) private var store
    let item: SavingsItem
    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: Mono.S.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                    .fill(Mono.C.text)
                    .frame(width: 44, height: 44)
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Mono.C.bg)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(Mono.T.mono(15, .semibold))
                        .foregroundColor(Mono.C.text)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Mono.C.positive)
                }
                Text(item.targetAmount.indianFormatted)
                    .font(Mono.T.mono(12, .regular))
                    .foregroundColor(Mono.C.textTert)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("Completed")
                    .font(Mono.T.mono(10, .semibold))
                    .foregroundColor(Mono.C.textDim)
                    .tracking(1)
                Text(VaultDateFormatter.short.string(from: item.createdAt))
                    .font(Mono.T.mono(11, .regular))
                    .foregroundColor(Mono.C.textTert)
            }
        }
        .padding(Mono.S.md)
        .monoCard(elevated: false)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                    store.deleteSavingsItem(id: item.id)
                }
                Haptic.medium()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .contextMenu {
            Button(role: .destructive) {
                store.deleteSavingsItem(id: item.id)
                Haptic.medium()
            } label: {
                Label("Delete Goal", systemImage: "trash")
            }
        }
    }
}
