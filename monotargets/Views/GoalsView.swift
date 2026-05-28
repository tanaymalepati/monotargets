import SwiftUI

// MARK: - Goals View

enum GoalLayoutMode: String {
    case list  = "list"
    case grid  = "grid"
    case swipe = "swipe"
}

struct GoalsView: View {
    @Environment(AppStore.self) private var store
    @State private var showCreateGoal  = false
    @State private var selectedItem:   SavingsItem?
    @State private var appeared        = false
    @State private var activeTab:      GoalTab = .active
    @State private var sortMode:       GoalSort = .progress
    @State private var filterMode:     GoalFilter = .all
    @State private var categoryFilter: GoalCategory? = nil
    @State private var showSortMenu    = false
    @AppStorage("goals_layout_mode") private var layoutModeRaw = "list"
    @Namespace private var zoomNamespace

    private var layoutMode: GoalLayoutMode { GoalLayoutMode(rawValue: layoutModeRaw) ?? .list }

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
        // Apply category filter
        if let cat = categoryFilter {
            items = items.filter { $0.goalCategory == cat }
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

    /// Which categories are actually used in active goals (so we only show relevant pills)
    private var usedCategories: [GoalCategory] {
        let used = Set(store.savingsItems.filter { !$0.isCompleted }.compactMap { $0.goalCategory })
        return GoalCategory.allCases.filter { used.contains($0) }
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

                // ── Tab + Filter bar ────────────────────────────────
                VStack(spacing: 8) {
                    // Row 1: Tab switcher + Layout toggle
                    HStack(spacing: Mono.S.sm) {
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
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Mono.C.surfaceTop))

                        // Layout toggle buttons
                        if activeTab == .active {
                            HStack(spacing: 2) {
                                ForEach([("list.bullet", "list"), ("square.grid.2x2", "grid"), ("rectangle.stack", "swipe")], id: \.1) { sym, mode in
                                    Button {
                                        withAnimation(.spring(duration: 0.22, bounce: 0.3)) { layoutModeRaw = mode }
                                        Haptic.select()
                                    } label: {
                                        Image(systemName: sym)
                                            .font(.system(size: 12, weight: layoutModeRaw == mode ? .bold : .regular))
                                            .foregroundColor(layoutModeRaw == mode ? Mono.C.text : Mono.C.textDim)
                                            .frame(width: 30, height: 30)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .fill(layoutModeRaw == mode ? Mono.C.surfaceTop : .clear)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(3)
                            .background(
                                RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .fill(Mono.C.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .strokeBorder(Mono.C.border, lineWidth: 0.5))
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }

                    // Row 2: Filters + Sort (active tab only)
                    if activeTab == .active {
                        HStack(spacing: 6) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 5) {
                                    ForEach(GoalFilter.allCases, id: \.self) { f in
                                        ToolbarFilterPill(label: f.rawValue, isSelected: filterMode == f) {
                                            withAnimation(.spring(duration: 0.2)) { filterMode = f }
                                            Haptic.select()
                                        }
                                    }
                                }
                            }

                            Spacer(minLength: 0)

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
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                        .fill(Mono.C.surfaceUp)
                                        .overlay(RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                            .strokeBorder(Mono.C.border, lineWidth: 0.5))
                                )
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Row 3: Category filter (only when active tab and categories exist)
                    if activeTab == .active && !usedCategories.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                // "All" pill
                                ToolbarFilterPill(label: "All", isSelected: categoryFilter == nil) {
                                    withAnimation(.spring(duration: 0.2)) { categoryFilter = nil }
                                    Haptic.select()
                                }
                                ForEach(usedCategories) { cat in
                                    Button {
                                        withAnimation(.spring(duration: 0.2)) {
                                            categoryFilter = (categoryFilter == cat) ? nil : cat
                                        }
                                        Haptic.select()
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 9, weight: .semibold))
                                            Text(cat.label)
                                                .font(Mono.T.mono(11, .semibold))
                                        }
                                        .foregroundColor(categoryFilter == cat ? cat.color : Mono.C.textSec)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 7)
                                        .background(
                                            Capsule(style: .continuous)
                                                .fill(categoryFilter == cat ? cat.color.opacity(0.15) : Mono.C.surfaceUp)
                                                .overlay(Capsule(style: .continuous)
                                                    .strokeBorder(
                                                        categoryFilter == cat ? cat.color.opacity(0.5) : Mono.C.border,
                                                        lineWidth: 0.5))
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.spring(duration: 0.18), value: categoryFilter == cat)
                                }
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
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
                        switch layoutMode {
                        case .list:
                            GoalListLayout(
                                items: activeItems,
                                namespace: zoomNamespace,
                                appeared: appeared,
                                onTap: { selectedItem = $0 }
                            )
                        case .grid:
                            GoalGridLayout(
                                items: activeItems,
                                appeared: appeared,
                                onTap: { selectedItem = $0 }
                            )
                        case .swipe:
                            GoalSwipeLayout(
                                items: activeItems,
                                namespace: zoomNamespace,
                                appeared: appeared,
                                onTap: { selectedItem = $0 },
                                onAdd: { showCreateGoal = true }
                            )
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

            // ── FAB (hidden in swipe mode — "+" is the last swipe card) ──
            if activeTab == .active && layoutMode != .swipe {
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
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Mono.C.text : .clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.22, bounce: 0.3), value: isSelected)
    }
}

// Unified filter pill used in both GoalsView (toolbar row) and HistoryView (category row)
struct ToolbarFilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Mono.T.mono(11, .semibold))
                .foregroundColor(isSelected ? Mono.C.accent : Mono.C.textSec)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Mono.C.accent.opacity(0.12) : Mono.C.surfaceUp)
                        .overlay(Capsule(style: .continuous)
                            .strokeBorder(isSelected ? Mono.C.accent.opacity(0.45) : Mono.C.border, lineWidth: 0.5))
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.18), value: isSelected)
    }
}

// Legacy alias — HistoryView uses this name for the category sub-filter
typealias MiniFilterPill = ToolbarFilterPill

// MARK: - Goal Card (premium redesign)

struct GoalCard: View {
    let item: SavingsItem
    let namespace: Namespace.ID
    let onTap: () -> Void

    @Environment(AppStore.self) private var store
    @AppStorage("smart_eta_enabled") private var etaEnabled = true

    private var urgencyColor: Color {
        guard let days = item.daysUntilTarget else { return .clear }
        if days < 0   { return Mono.C.red.opacity(0.65) }
        if days <= 14 { return Color(red: 1, green: 0.55, blue: 0).opacity(0.65) }
        return .clear
    }

    private var accentForProgress: Color {
        item.isFullyFunded ? Mono.C.text : Mono.C.accent
    }

    var body: some View {
        Button(action: { onTap(); Haptic.light() }) {
            VStack(spacing: 0) {

                // ── Top progress glow strip ───────────────────────────
                // Subtle colored bar behind the card top, visible only when funded
                if item.progress > 0 {
                    GeometryReader { geo in
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [accentForProgress.opacity(0.18), .clear],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * item.progress, 0))
                    }
                    .frame(height: 3)
                } else {
                    Color.clear.frame(height: 3)
                }

                // ── Main body ─────────────────────────────────────────
                HStack(alignment: .top, spacing: 14) {

                    // Icon / Photo
                    ZStack(alignment: .topTrailing) {
                        Group {
                            if let data = item.photoData, let ui = UIImage(data: data) {
                                Image(uiImage: ui)
                                    .resizable().scaledToFill()
                                    .frame(width: 52, height: 52)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(item.isFullyFunded ? Mono.C.text : Mono.C.surfaceTop)
                                    .frame(width: 52, height: 52)
                                    .overlay(
                                        Image(systemName: item.icon)
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(item.isFullyFunded ? Mono.C.bg : Mono.C.textSec)
                                    )
                            }
                        }
                        if item.isBoostActive {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 7, weight: .bold))
                                .foregroundColor(Mono.C.bg)
                                .padding(2.5)
                                .background(Circle().fill(Mono.C.accent))
                                .offset(x: 5, y: -5)
                        }
                    }
                    .frame(width: 52, height: 52)

                    // Middle: name + amount
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Text(item.name)
                                .font(Mono.T.mono(15, .semibold))
                                .foregroundColor(Mono.C.text)
                                .lineLimit(1)
                            if item.isFavorite {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(Mono.C.accent.opacity(0.85))
                            }
                        }
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(item.assignedAmount.indianFormattedCompact)
                                .font(Mono.T.mono(14, .semibold))
                                .foregroundColor(Mono.C.textSec)
                            Text("/ \(item.targetAmount.indianFormattedCompact)")
                                .font(Mono.T.mono(11, .regular))
                                .foregroundColor(Mono.C.textTert)
                        }
                        if !item.itemDescription.isEmpty {
                            Text(item.itemDescription)
                                .font(Mono.T.mono(10, .regular))
                                .foregroundColor(Mono.C.textTert)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 4)

                    // Right: large bold percentage
                    VStack(alignment: .trailing, spacing: 0) {
                        HStack(alignment: .firstTextBaseline, spacing: 1) {
                            Text("\(Int(item.progress * 100))")
                                .font(Mono.T.mono(30, .bold))
                                .foregroundColor(item.progress > 0 ? accentForProgress : Mono.C.textDim)
                                .contentTransition(.numericText(countsDown: false))
                            Text("%")
                                .font(Mono.T.mono(14, .semibold))
                                .foregroundColor(Mono.C.textTert)
                                .baselineOffset(3)
                        }
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.top, Mono.S.md)
                .padding(.bottom, 10)

                // ── Progress bar (full-width, 4px) ────────────────────
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle().fill(Mono.C.surfaceTop)
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [accentForProgress.opacity(0.55), accentForProgress],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * item.progress, 0))
                    }
                }
                .frame(height: 4)

                // ── Footer row ────────────────────────────────────────
                HStack {
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
                    .foregroundColor(Mono.C.textDim)
                    .padding(.leading, Mono.S.md)

                    Spacer()

                    Text(item.remaining.indianFormattedCompact + " left")
                        .font(Mono.T.mono(10, .regular))
                        .foregroundColor(Mono.C.textDim)
                        .padding(.trailing, Mono.S.md)
                }
                .frame(height: 34)
            }
            .background(
                RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                    .fill(Mono.G.cardSubtle)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                            .strokeBorder(
                                urgencyColor == .clear ? Mono.C.border : urgencyColor,
                                lineWidth: urgencyColor == .clear ? 0.5 : 1.2
                            )
                    )
                    .shadow(color: .black.opacity(0.45), radius: 14, x: 0, y: 5)
            )
            .clipShape(RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous))
            .matchedTransitionSource(id: item.id, in: namespace)
        }
        .buttonStyle(CardPressStyle())
    }
}

// MARK: - Goal Layout Containers

struct GoalListLayout: View {
    let items: [SavingsItem]
    let namespace: Namespace.ID
    let appeared: Bool
    let onTap: (SavingsItem) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    GoalCard(item: item, namespace: namespace) { onTap(item) }
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
}

struct GoalGridLayout: View {
    let items: [SavingsItem]
    let appeared: Bool
    let onTap: (SavingsItem) -> Void

    private let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    GoalGridCard(item: item) { onTap(item) }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20 + CGFloat(idx * 4))
                        .animation(.spring(duration: 0.45, bounce: 0.25).delay(0.05 + Double(idx) * 0.04), value: appeared)
                }
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.top, 4)
            Spacer(minLength: 110)
        }
    }
}

struct GoalSwipeLayout: View {
    let items: [SavingsItem]
    let namespace: Namespace.ID
    let appeared: Bool
    let onTap: (SavingsItem) -> Void
    let onAdd: () -> Void

    @State private var currentPage = 0

    private var totalPages: Int { items.count + 1 }
    private var showDots: Bool { totalPages <= 8 }

    var body: some View {
        // ZStack so TabView fills all space and dots float above the bottom
        ZStack(alignment: .bottom) {
            TabView(selection: $currentPage) {
                ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                    GoalSwipeCard(item: item, namespace: namespace) { onTap(item) }
                        .padding(.horizontal, 16)
                        // bottom padding keeps content above tab bar + dot strip
                        .padding(.bottom, 68)
                        .tag(idx)
                }
                GoalSwipeCreateCard(onAdd: onAdd)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 68)
                    .tag(items.count)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(appeared ? 1 : 0)

            // Dot / count indicator — floated above tab bar
            Group {
                if showDots {
                    HStack(spacing: 5) {
                        ForEach(0..<totalPages, id: \.self) { i in
                            let isCurrent = i == currentPage
                            let isCreate  = i == items.count
                            Capsule(style: .continuous)
                                .fill(isCreate
                                      ? (isCurrent ? Mono.C.accent : Mono.C.textDim.opacity(0.4))
                                      : (isCurrent ? Mono.C.text   : Mono.C.textDim.opacity(0.4)))
                                .frame(width: isCurrent ? 18 : 6, height: 6)
                                .animation(.spring(duration: 0.28, bounce: 0.4), value: currentPage)
                        }
                    }
                } else {
                    Text("\(min(currentPage + 1, totalPages)) / \(totalPages)")
                        .font(Mono.T.mono(11, .medium))
                        .foregroundColor(Mono.C.textDim)
                }
            }
            .padding(.bottom, 108) // sits just above the tab bar
        }
    }
}

// MARK: - Swipe Card (large, full-height)

struct GoalSwipeCard: View {
    let item: SavingsItem
    let namespace: Namespace.ID
    let onTap: () -> Void

    @Environment(AppStore.self) private var store
    @AppStorage("smart_eta_enabled") private var etaEnabled = true
    @AppStorage("vault_monochrome")  private var isMonochrome = false
    @State private var barAppeared = false

    private var accentColor: Color { item.isFullyFunded ? Mono.C.text : Mono.C.accent }

    private var urgencyColor: Color {
        guard let days = item.daysUntilTarget else { return .clear }
        if days < 0   { return Mono.C.red }
        if days <= 14 { return Color(red: 1, green: 0.55, blue: 0) }
        return .clear
    }

    private var stats: [(String, String, String)] {
        var result: [(String, String, String)] = []
        result.append(("Remaining", item.remaining.indianFormattedCompact, "minus.circle"))
        if let days = item.daysUntilTarget {
            let label = days < 0 ? "Overdue" : (days == 0 ? "Today!" : "\(days) days")
            result.append(("Deadline", label, "calendar"))
        } else if etaEnabled, let eta = store.goalETA(for: item.id) {
            result.append(("ETA", eta, "clock"))
        }
        if item.isBoostActive {
            result.append(("Boost", "\(item.boostDaysRemaining)d left", "bolt.fill"))
        } else if let cat = item.goalCategory {
            result.append((cat.label, "", cat.icon))
        }
        return Array(result.prefix(3))
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Top strip: category + star ───────────────
            HStack {
                if let cat = item.goalCategory {
                    HStack(spacing: 4) {
                        Image(systemName: cat.icon)
                            .font(.system(size: 9, weight: .semibold))
                        Text(cat.label)
                            .font(Mono.T.mono(10, .semibold))
                    }
                    .foregroundColor(cat.color)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule(style: .continuous)
                            .fill(cat.color.opacity(0.12))
                            .overlay(Capsule().strokeBorder(cat.color.opacity(0.3), lineWidth: 0.5))
                    )
                } else {
                    Spacer()
                }
                Spacer()
                if item.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Mono.C.accent.opacity(0.9))
                }
                if item.isBoostActive {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Mono.C.accent)
                        .padding(.leading, 6)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 10)

            // ── Hero icon ─────────────────────────────────
            ZStack {
                if let data = item.photoData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable().scaledToFill()
                        .frame(width: 108, height: 108)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                } else {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(item.isFullyFunded ? Mono.C.text : Mono.C.surfaceTop)
                        .frame(width: 108, height: 108)
                        .overlay(
                            Image(systemName: item.icon)
                                .font(.system(size: 44, weight: .medium))
                                .foregroundColor(item.isFullyFunded ? Mono.C.bg : Mono.C.textSec)
                        )
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
            .padding(.bottom, 20)

            // ── Goal name ─────────────────────────────────
            Text(item.name)
                .font(Mono.T.mono(26, .bold))
                .foregroundColor(Mono.C.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 22)

            if !item.itemDescription.isEmpty {
                Text(item.itemDescription)
                    .font(Mono.T.mono(13, .regular))
                    .foregroundColor(Mono.C.textTert)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 22)
                    .padding(.top, 4)
            }

            // ── Giant percentage ──────────────────────────
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(Int(item.progress * 100))")
                    .font(Mono.T.mono(80, .bold))
                    .foregroundColor(item.progress > 0 ? accentColor : Mono.C.textDim)
                    .contentTransition(.numericText(countsDown: false))
                    .shadow(color: item.progress > 0 ? accentColor.opacity(0.25) : .clear, radius: 20)
                Text("%")
                    .font(Mono.T.mono(32, .semibold))
                    .foregroundColor(Mono.C.textTert)
                    .baselineOffset(6)
            }
            .padding(.top, 4)

            Spacer(minLength: 0)

            // ── Amounts + progress bar ─────────────────────
            VStack(spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        OverlineLabel(text: "Saved", opacity: 0.45)
                        Text(item.assignedAmount.indianFormattedCompact)
                            .font(Mono.T.mono(20, .bold))
                            .foregroundColor(Mono.C.text)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        OverlineLabel(text: "Target", opacity: 0.45)
                        Text(item.targetAmount.indianFormattedCompact)
                            .font(Mono.T.mono(20, .semibold))
                            .foregroundColor(Mono.C.textSec)
                    }
                }
                .padding(.horizontal, 22)

                // Thick animated progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Mono.C.surfaceTop)
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(LinearGradient(
                                colors: [accentColor.opacity(0.6), accentColor],
                                startPoint: .leading, endPoint: .trailing
                            ))
                            .frame(width: max(geo.size.width * (barAppeared ? item.progress : 0), 0), height: 10)
                            .animation(.spring(duration: 1.0, bounce: 0.1).delay(0.15), value: barAppeared)
                    }
                }
                .frame(height: 10)
                .padding(.horizontal, 22)
                .onAppear { barAppeared = true }
                .onDisappear { barAppeared = false }
            }

            // ── Stats row ─────────────────────────────────
            if !stats.isEmpty {
                HStack(spacing: 0) {
                    ForEach(Array(stats.enumerated()), id: \.offset) { i, stat in
                        VStack(spacing: 3) {
                            Image(systemName: stat.2)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(
                                    stat.0 == "Overdue" ? Mono.C.red :
                                    (stat.0 == "Boost" ? Mono.C.accent : Mono.C.textDim)
                                )
                            if !stat.1.isEmpty {
                                Text(stat.1)
                                    .font(Mono.T.mono(12, .semibold))
                                    .foregroundColor(
                                        stat.0 == "Overdue" ? Mono.C.red :
                                        (stat.0 == "Boost" ? Mono.C.accent : Mono.C.text)
                                    )
                                    .minimumScaleFactor(0.8)
                                    .lineLimit(1)
                            }
                            Text(stat.0.uppercased())
                                .font(Mono.T.mono(8, .medium))
                                .foregroundColor(Mono.C.textDim)
                                .tracking(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        if i < stats.count - 1 {
                            Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 36)
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)
            }

            // ── Open Goal button ──────────────────────────
            Button(action: { onTap(); Haptic.medium() }) {
                HStack(spacing: 8) {
                    Text("Open Goal")
                        .font(Mono.T.mono(15, .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Mono.C.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(Mono.C.text)
                        .shadow(color: .white.opacity(0.08), radius: 12)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.top, 18)
            .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(white: 0.10))   // slightly lighter than bg for clear separation
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(
                            urgencyColor == .clear ? Mono.C.borderBright.opacity(0.6) : urgencyColor.opacity(0.8),
                            lineWidth: urgencyColor == .clear ? 0.8 : 1.5
                        )
                )
                .shadow(color: .black.opacity(0.6), radius: 30, x: 0, y: 14)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .matchedTransitionSource(id: item.id, in: namespace)
    }
}

// MARK: - Swipe "Add" Card (last in deck)

struct GoalSwipeCreateCard: View {
    let onAdd: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Mono.C.surfaceTop)
                        .frame(width: 96, height: 96)
                    Image(systemName: "plus")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(Mono.C.textDim)
                }

                VStack(spacing: 6) {
                    Text("New Goal")
                        .font(Mono.T.mono(24, .bold))
                        .foregroundColor(Mono.C.text)
                    Text("Start saving for something new")
                        .font(Mono.T.mono(13, .regular))
                        .foregroundColor(Mono.C.textTert)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 22)
            Spacer()

            Button(action: { onAdd(); Haptic.medium() }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Create Goal")
                        .font(Mono.T.mono(15, .semibold))
                }
                .foregroundColor(Mono.C.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(Mono.C.text)
                        .shadow(color: .white.opacity(0.08), radius: 12)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(white: 0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .strokeBorder(Mono.C.borderBright.opacity(0.5), lineWidth: 0.8)
                )
                .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 10)
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

// MARK: - Goal Grid Card

struct GoalGridCard: View {
    let item: SavingsItem
    let onTap: () -> Void

    @AppStorage("smart_eta_enabled") private var etaEnabled = true

    private var accentColor: Color { item.isFullyFunded ? Mono.C.text : Mono.C.accent }

    var body: some View {
        Button(action: { onTap(); Haptic.light() }) {
            VStack(alignment: .leading, spacing: 10) {
                // Icon + Category badge row
                HStack(alignment: .top) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(item.isFullyFunded ? Mono.C.text : Mono.C.surfaceTop)
                            .frame(width: 40, height: 40)
                        Image(systemName: item.icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(item.isFullyFunded ? Mono.C.bg : Mono.C.textSec)
                    }
                    Spacer()
                    // Percentage badge
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text("\(Int(item.progress * 100))")
                            .font(Mono.T.mono(17, .bold))
                            .foregroundColor(item.progress > 0 ? accentColor : Mono.C.textDim)
                            .contentTransition(.numericText(countsDown: false))
                        Text("%")
                            .font(Mono.T.mono(9, .semibold))
                            .foregroundColor(Mono.C.textTert)
                            .baselineOffset(2)
                    }
                }

                // Name
                Text(item.name)
                    .font(Mono.T.mono(13, .semibold))
                    .foregroundColor(Mono.C.text)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                // Thin progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Mono.C.surfaceTop)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(LinearGradient(colors: [accentColor.opacity(0.6), accentColor],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(geo.size.width * item.progress, 0))
                    }
                }
                .frame(height: 3)

                // Target amount
                Text(item.targetAmount.indianFormattedCompact)
                    .font(Mono.T.mono(10, .regular))
                    .foregroundColor(Mono.C.textDim)
            }
            .padding(Mono.S.md)
            .frame(minHeight: 130)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                    .fill(Mono.G.cardSubtle)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                            .strokeBorder(Mono.C.border, lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 4)
            )
            .clipShape(RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous))
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
