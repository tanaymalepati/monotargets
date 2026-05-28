import SwiftUI

// MARK: - Goals View

struct GoalsView: View {
    @Environment(AppStore.self) private var store
    @State private var showCreateGoal  = false
    @State private var selectedItem:   SavingsItem?
    @State private var appeared        = false
    @State private var activeTab:      GoalTab = .active
    @State private var sortMode:       GoalSort = .progress
    @State private var filterMode:     GoalFilter = .all
    @State private var showSortMenu    = false
    @Namespace private var zoomNamespace

    enum GoalTab   { case active, completed }
    enum GoalSort  { case progress, targetDate, remaining, name
        var label: String {
            switch self { case .progress: return "Progress"; case .targetDate: return "Due Date"
                         case .remaining: return "Remaining"; case .name: return "Name" }
        }
    }
    enum GoalFilter: String, CaseIterable { case all = "All"; case pinned = "Pinned"; case overdue = "Overdue"; case funded = "Funded" }

    private var activeItems: [SavingsItem] {
        var items = store.savingsItems.filter { !$0.isCompleted }
        switch filterMode {
        case .all:     break
        case .pinned:  items = items.filter { $0.isFavorite }
        case .overdue: items = items.filter { ($0.daysUntilTarget ?? 1) < 0 && !$0.isFullyFunded }
        case .funded:  items = items.filter { $0.isFullyFunded }
        }
        switch sortMode {
        case .progress:   items.sort { $0.progress > $1.progress }
        case .targetDate: items.sort {
            let a = $0.targetDate ?? Date.distantFuture
            let b = $1.targetDate ?? Date.distantFuture
            return a < b
        }
        case .remaining:  items.sort { $0.remaining < $1.remaining }
        case .name:       items.sort { $0.name < $1.name }
        }
        return items
    }

    private var completedItems: [SavingsItem] {
        store.savingsItems.filter { $0.isCompleted }.sorted { $0.createdAt > $1.createdAt }
    }

    private var totalGoalAmount:  Double { store.savingsItems.reduce(0) { $0 + $1.targetAmount } }
    private var totalFunded:      Double { store.savingsItems.reduce(0) { $0 + $1.assignedAmount } }
    private var overallProgress:  Double { totalGoalAmount > 0 ? min(totalFunded / totalGoalAmount, 1.0) : 0 }

    var body: some View {
        ZStack(alignment: .bottom) {
            Mono.C.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Stats hero ─────────────────────────────────────
                GoalsHeroHeader(
                    progress: overallProgress,
                    funded: totalFunded,
                    target: totalGoalAmount,
                    goalCount: store.savingsItems.count,
                    completedCount: completedItems.count,
                    unassigned: store.totalUnassigned
                )
                .padding(.horizontal, Mono.S.md)
                .padding(.top, Mono.S.sm)
                .padding(.bottom, Mono.S.sm)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.94)

                // ── Tab + Sort bar ──────────────────────────────────
                HStack(spacing: 8) {
                    // Tab pills
                    HStack(spacing: 4) {
                        GoalTabPill(label: "Active", count: activeItems.count, isSelected: activeTab == .active) {
                            withAnimation(.spring(duration: 0.25, bounce: 0.3)) { activeTab = .active }
                            Haptic.select()
                        }
                        GoalTabPill(label: "Done", count: completedItems.count, isSelected: activeTab == .completed) {
                            withAnimation(.spring(duration: 0.25, bounce: 0.3)) { activeTab = .completed }
                            Haptic.select()
                        }
                    }
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Mono.C.surfaceTop))

                    Spacer()

                    if activeTab == .active {
                        // Filter pills
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                ForEach(GoalFilter.allCases, id: \.self) { f in
                                    MiniFilterPill(label: f.rawValue, isSelected: filterMode == f) {
                                        withAnimation(.spring(duration: 0.2)) { filterMode = f }
                                        Haptic.select()
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: 160)

                        // Sort button
                        Menu {
                            ForEach([GoalSort.progress, .targetDate, .remaining, .name], id: \.label) { s in
                                Button {
                                    withAnimation { sortMode = s }
                                    Haptic.select()
                                } label: {
                                    Label(s.label, systemImage: sortMode == s ? "checkmark" : "")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.up.arrow.down")
                                    .font(.system(size: 11, weight: .semibold))
                                Text(sortMode.label)
                                    .font(Mono.T.mono(11, .medium))
                            }
                            .foregroundColor(Mono.C.textSec)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                    .fill(Mono.C.surfaceUp)
                                    .overlay(RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                        .strokeBorder(Mono.C.border, lineWidth: 0.5))
                            )
                        }
                    }
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.sm)
                .opacity(appeared ? 1 : 0)

                // ── Content ─────────────────────────────────────────
                if activeTab == .active {
                    if activeItems.isEmpty {
                        Spacer()
                        EmptyGoalsCard(filterMode: filterMode) { showCreateGoal = true }
                            .padding(.horizontal, Mono.S.md)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 10) {
                                ForEach(Array(activeItems.enumerated()), id: \.element.id) { idx, item in
                                    GoalCard(item: item, namespace: zoomNamespace) { selectedItem = item }
                                        .padding(.horizontal, Mono.S.md)
                                        .opacity(appeared ? 1 : 0)
                                        .offset(y: appeared ? 0 : 20 + CGFloat(idx * 6))
                                        .animation(.spring(duration: 0.45, bounce: 0.25).delay(0.05 + Double(idx) * 0.05), value: appeared)
                                }
                                Spacer(minLength: 110)
                            }
                            .padding(.top, 4)
                        }
                    }
                } else {
                    if completedItems.isEmpty {
                        Spacer()
                        EmptyStateCard(icon: "checkmark.circle", title: "No completed goals",
                                       subtitle: "Goals move here once confirmed complete")
                            .padding(.horizontal, Mono.S.md)
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 8) {
                                ForEach(completedItems) { item in
                                    CompletedGoalCard(item: item)
                                        .padding(.horizontal, Mono.S.md)
                                        .onTapGesture { selectedItem = item; Haptic.light() }
                                }
                                Spacer(minLength: 80)
                            }
                            .padding(.top, 4)
                        }
                    }
                }
            }

            // ── FAB ─────────────────────────────────────────────────
            if activeTab == .active {
                HStack {
                    Spacer()
                    Button {
                        showCreateGoal = true
                        Haptic.medium()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "plus").font(.system(size: 15, weight: .bold))
                            Text("New Goal").font(Mono.T.mono(14, .semibold))
                        }
                        .foregroundColor(Mono.C.bg)
                        .padding(.horizontal, Mono.S.lg)
                        .padding(.vertical, 14)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Mono.C.text)
                                .shadow(color: .white.opacity(0.12), radius: 18)
                                .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, Mono.S.lg)
                    .padding(.bottom, 96)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.55, bounce: 0.2).delay(0.05)) { appeared = true }
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

// MARK: - Goals Hero Header

struct GoalsHeroHeader: View {
    let progress:       Double
    let funded:         Double
    let target:         Double
    let goalCount:      Int
    let completedCount: Int
    let unassigned:     Double

    @State private var animProgress: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Mono.S.lg) {
                // Big ring
                ZStack {
                    Circle()
                        .trim(from: 0.12, to: 0.88)
                        .stroke(Mono.C.surfaceTop, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(90))

                    Circle()
                        .trim(from: 0.12, to: 0.12 + animProgress * 0.76)
                        .stroke(
                            AngularGradient(colors: [Mono.C.accent.opacity(0.5), Mono.C.accent],
                                            center: .center, startAngle: .degrees(-90), endAngle: .degrees(270)),
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(90))

                    VStack(spacing: 2) {
                        Text("\(Int(progress * 100))%")
                            .font(Mono.T.mono(24, .bold))
                            .foregroundColor(Mono.C.text)
                            .contentTransition(.numericText(countsDown: false))
                        Text("funded")
                            .font(Mono.T.mono(10, .regular))
                            .foregroundColor(Mono.C.textTert)
                    }
                }
                .frame(width: 90, height: 90)
                .onAppear {
                    withAnimation(.spring(duration: 1.1, bounce: 0.15).delay(0.1)) {
                        animProgress = progress
                    }
                }
                .onChange(of: progress) { _, new in
                    withAnimation(.spring(duration: 0.6)) { animProgress = new }
                }

                // Stats column
                VStack(alignment: .leading, spacing: Mono.S.sm) {
                    VStack(alignment: .leading, spacing: 2) {
                        OverlineLabel(text: "Total Funded")
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(funded.indianFormattedCompact)
                                .font(Mono.T.mono(22, .bold))
                                .foregroundColor(Mono.C.text)
                            Text("/ \(target.indianFormattedCompact)")
                                .font(Mono.T.mono(12, .regular))
                                .foregroundColor(Mono.C.textTert)
                        }
                    }

                    MonoDivider()

                    HStack(spacing: Mono.S.lg) {
                        GoalMicroStat(value: "\(goalCount)", label: "Total")
                        GoalMicroStat(value: "\(completedCount)", label: "Done")
                        GoalMicroStat(value: unassigned.indianFormattedCompact, label: "Free Cash")
                    }
                }
            }
            .padding(Mono.S.lg)
        }
        .monoHeroCard()
    }
}

private struct GoalMicroStat: View {
    let value: String
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(Mono.T.mono(14, .bold))
                .foregroundColor(Mono.C.text)
            Text(label.uppercased())
                .font(Mono.T.overline)
                .foregroundColor(Mono.C.textTert)
                .tracking(1)
        }
    }
}

// MARK: - Tab Pill

struct GoalTabPill: View {
    let label: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(label)
                    .font(Mono.T.mono(12, .semibold))
                if count > 0 {
                    Text("\(count)")
                        .font(Mono.T.mono(10, .medium))
                        .foregroundColor(isSelected ? Mono.C.bg.opacity(0.6) : Mono.C.textDim)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(isSelected ? Mono.C.text.opacity(0.2) : Mono.C.surfaceTop))
                }
            }
            .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Mono.C.text : .clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.22, bounce: 0.3), value: isSelected)
    }
}

struct MiniFilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Mono.T.mono(10, .semibold))
                .foregroundColor(isSelected ? Mono.C.accent : Mono.C.textTert)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isSelected ? Mono.C.accent.opacity(0.12) : .clear)
                        .overlay(Capsule().strokeBorder(isSelected ? Mono.C.accent.opacity(0.4) : Mono.C.border, lineWidth: 0.5))
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.18), value: isSelected)
    }
}

// MARK: - Goal Card (redesigned)

struct GoalCard: View {
    let item: SavingsItem
    let namespace: Namespace.ID
    let onTap: () -> Void

    @Environment(AppStore.self) private var store
    @AppStorage("smart_eta_enabled") private var etaEnabled = true

    private var urgencyColor: Color {
        guard let days = item.daysUntilTarget else { return .clear }
        if days < 0   { return Mono.C.red.opacity(0.6) }
        if days <= 14 { return Color(red: 1, green: 0.55, blue: 0).opacity(0.6) }
        return .clear
    }

    var body: some View {
        Button(action: { onTap(); Haptic.light() }) {
            VStack(spacing: 0) {
                // Main content row
                HStack(spacing: 14) {
                    // Icon / Photo
                    ZStack {
                        if let data = item.photoData, let ui = UIImage(data: data) {
                            Image(uiImage: ui)
                                .resizable().scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous))
                        } else {
                            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                .fill(item.isFullyFunded ? Mono.C.text : Mono.C.surfaceTop)
                                .frame(width: 56, height: 56)
                            Image(systemName: item.icon)
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(item.isFullyFunded ? Mono.C.bg : Mono.C.textSec)
                        }
                        // Boost bolt overlay
                        if item.isBoostActive {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(Mono.C.bg)
                                        .padding(3)
                                        .background(Circle().fill(Mono.C.accent))
                                        .offset(x: 4, y: -4)
                                }
                                Spacer()
                            }
                        }
                    }
                    .frame(width: 56, height: 56)

                    // Middle: name + desc
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Text(item.name)
                                .font(Mono.T.mono(15, .semibold))
                                .foregroundColor(Mono.C.text)
                                .lineLimit(1)
                            if item.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(Mono.C.accent.opacity(0.8))
                            }
                        }
                        if !item.itemDescription.isEmpty {
                            Text(item.itemDescription)
                                .font(Mono.T.mono(11, .regular))
                                .foregroundColor(Mono.C.textTert)
                                .lineLimit(1)
                        }
                        // Amount sub-label
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(item.assignedAmount.indianFormattedCompact)
                                .font(Mono.T.mono(13, .semibold))
                                .foregroundColor(Mono.C.textSec)
                            Text("/ \(item.targetAmount.indianFormattedCompact)")
                                .font(Mono.T.mono(11, .regular))
                                .foregroundColor(Mono.C.textTert)
                        }
                    }

                    Spacer()

                    // Right: percentage ring
                    ZStack {
                        Circle()
                            .stroke(Mono.C.surfaceTop, lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: item.progress)
                            .stroke(item.isFullyFunded ? Mono.C.text : Mono.C.accent,
                                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(item.progress * 100))%")
                            .font(Mono.T.mono(10, .bold))
                            .foregroundColor(Mono.C.text)
                    }
                    .frame(width: 44, height: 44)
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.top, Mono.S.md)
                .padding(.bottom, 10)

                // Progress bar (full width)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Mono.C.surfaceTop)
                        Rectangle()
                            .fill(
                                LinearGradient(colors: [Mono.C.accent.opacity(0.7), Mono.C.accent],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * item.progress)
                    }
                }
                .frame(height: 3)

                // Bottom info row
                HStack(spacing: 0) {
                    // Left: ETA or target date
                    HStack(spacing: 4) {
                        if let days = item.daysUntilTarget {
                            Image(systemName: "calendar")
                                .font(.system(size: 9, weight: .medium))
                            Text(VaultDateFormatter.daysRemaining(item.targetDate!))
                                .font(Mono.T.mono(10, .medium))
                                .foregroundColor(days < 0 ? Mono.C.red : (days <= 14 ? Color(red:1,green:0.55,blue:0) : Mono.C.textDim))
                        } else if etaEnabled, let eta = store.goalETA(for: item.id) {
                            Image(systemName: "clock")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(Mono.C.textDim)
                            Text(eta)
                                .font(Mono.T.mono(10, .medium))
                                .foregroundColor(Mono.C.textDim)
                        } else {
                            Text("No date set")
                                .font(Mono.T.mono(10, .regular))
                                .foregroundColor(Mono.C.textDim)
                        }
                    }
                    .padding(.leading, Mono.S.md)

                    Spacer()

                    // Right: remaining
                    Text(item.remaining.indianFormattedCompact + " left")
                        .font(Mono.T.mono(10, .regular))
                        .foregroundColor(Mono.C.textDim)
                        .padding(.trailing, Mono.S.md)
                }
                .frame(height: 32)
            }
            .background(
                RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                    .fill(Mono.G.cardSubtle)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                            .strokeBorder(urgencyColor == .clear ? Mono.C.border : urgencyColor, lineWidth: urgencyColor == .clear ? 0.5 : 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 16, x: 0, y: 6)
            )
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

// MARK: - Empty Goals Card

struct EmptyGoalsCard: View {
    let filterMode: GoalsView.GoalFilter
    let onCreate: () -> Void

    var body: some View {
        VStack(spacing: Mono.S.md) {
            Image(systemName: filterMode == .all ? "target" : "line.3.horizontal.decrease.circle")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(Mono.C.textDim)
            Text(filterMode == .all ? "No goals yet" : "No \(filterMode.rawValue.lowercased()) goals")
                .font(Mono.T.mono(16, .semibold))
                .foregroundColor(Mono.C.textSec)
            Text(filterMode == .all ? "Create your first savings goal to start tracking" : "Try changing the filter above")
                .font(Mono.T.caption)
                .foregroundColor(Mono.C.textTert)
                .multilineTextAlignment(.center)
            if filterMode == .all {
                Button(action: onCreate) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                        Text("Create Goal").font(Mono.T.mono(13, .semibold))
                    }
                    .foregroundColor(Mono.C.bg)
                    .padding(.horizontal, Mono.S.lg)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Mono.C.text))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .monoCard()
    }
}

// MARK: - Goal Stats Header (legacy alias)

struct GoalStatsHeader: View {
    var body: some View { EmptyView() }
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
                    .fill(Mono.C.text).frame(width: 44, height: 44)
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
                        .foregroundColor(Mono.C.accent)
                }
                Text(item.targetAmount.indianFormatted)
                    .font(Mono.T.mono(12, .regular))
                    .foregroundColor(Mono.C.textTert)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("DONE")
                    .font(Mono.T.mono(9, .bold))
                    .foregroundColor(Mono.C.accent)
                    .tracking(1)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Mono.C.accent.opacity(0.12)))
                Text(VaultDateFormatter.short.string(from: item.createdAt))
                    .font(Mono.T.mono(10, .regular))
                    .foregroundColor(Mono.C.textTert)
            }
        }
        .padding(Mono.S.md)
        .monoCard()
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation { store.deleteSavingsItem(id: item.id) }
                Haptic.medium()
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}
