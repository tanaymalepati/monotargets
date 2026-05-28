import SwiftUI

// MARK: - History View

struct HistoryView: View {
    @Environment(AppStore.self) private var store

    // ── State ────────────────────────────────────────────────────
    @State private var typeFilter:     TypeFilter = .all
    @State private var categoryFilter: Transaction.Category? = nil
    @State private var sortMode:       SortMode   = .newest
    @State private var showSearch      = false
    @State private var searchText      = ""
    @State private var selectedMonth:  Date       = {
        let cal = Calendar.current
        let c   = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: c) ?? Date()
    }()
    @State private var appeared        = false

    // ── Enums ────────────────────────────────────────────────────

    enum TypeFilter: String, CaseIterable {
        case all      = "All"
        case inward   = "In"
        case outward  = "Out"
        case assign   = "Assigned"

        var type: Transaction.TransactionType? {
            switch self {
            case .all:     return nil
            case .inward:  return .inward
            case .outward: return .outward
            case .assign:  return .assign
            }
        }
        var icon: String {
            switch self {
            case .all:     return "list.bullet"
            case .inward:  return "arrow.down.circle.fill"
            case .outward: return "arrow.up.circle.fill"
            case .assign:  return "arrow.right.circle.fill"
            }
        }
    }

    enum SortMode: String, CaseIterable {
        case newest  = "Newest"
        case oldest  = "Oldest"
        case highest = "Highest"
        case lowest  = "Lowest"
        var icon: String {
            switch self {
            case .newest:  return "arrow.down"
            case .oldest:  return "arrow.up"
            case .highest: return "arrow.up.right"
            case .lowest:  return "arrow.down.right"
            }
        }
    }

    // ── Computed ─────────────────────────────────────────────────

    private var selectedMonthStart: Date { selectedMonth }
    private var selectedMonthEnd: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? Date()
    }
    private var isCurrentMonth: Bool {
        Calendar.current.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private var monthTransactions: [Transaction] {
        store.transactions.filter { $0.date >= selectedMonthStart && $0.date < selectedMonthEnd }
    }

    private var filtered: [Transaction] {
        var list = monthTransactions

        // Type
        if let t = typeFilter.type { list = list.filter { $0.type == t } }

        // Category (for outward only)
        if let cat = categoryFilter { list = list.filter { $0.category == cat } }

        // Search
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.note.lowercased().contains(q) ||
                ($0.payee?.lowercased().contains(q) ?? false) ||
                ($0.category?.label.lowercased().contains(q) ?? false)
            }
        }

        // Sort
        switch sortMode {
        case .newest:  list.sort { $0.date > $1.date }
        case .oldest:  list.sort { $0.date < $1.date }
        case .highest: list.sort { $0.amount > $1.amount }
        case .lowest:  list.sort { $0.amount < $1.amount }
        }

        return list
    }

    private var monthInflow:  Double { monthTransactions.filter { $0.type == .inward  }.reduce(0) { $0 + $1.amount } }
    private var monthOutflow: Double { monthTransactions.filter { $0.type == .outward }.reduce(0) { $0 + $1.amount } }
    private var monthNet:     Double { monthInflow - monthOutflow }

    private var groupedTransactions: [(String, [Transaction])] {
        let cal = Calendar.current
        var groups: [String: [Transaction]] = [:]
        for t in filtered {
            let key: String
            if cal.isDateInToday(t.date)          { key = "Today" }
            else if cal.isDateInYesterday(t.date) { key = "Yesterday" }
            else {
                let fmt = DateFormatter()
                fmt.dateFormat = "d MMMM"
                key = fmt.string(from: t.date)
            }
            groups[key, default: []].append(t)
        }
        return groups.sorted { a, b in
            (a.1.first?.date ?? .distantPast) > (b.1.first?.date ?? .distantPast)
        }
    }

    private var spendByCategory: [(Transaction.Category, Double)] {
        var totals: [Transaction.Category: Double] = [:]
        for t in monthTransactions where t.type == .outward {
            totals[t.category ?? .other, default: 0] += t.amount
        }
        return totals.sorted { $0.value > $1.value }.map { ($0.key, $0.value) }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Month Navigator ──────────────────────────────
                MonthNavigator(selectedMonth: $selectedMonth)
                    .padding(.horizontal, Mono.S.md)
                    .padding(.top, Mono.S.xs)
                    .padding(.bottom, Mono.S.sm)

                // ── Monthly Summary ──────────────────────────────
                MonthlySummaryBar(inflow: monthInflow, outflow: monthOutflow, net: monthNet,
                                  count: monthTransactions.count)
                    .padding(.horizontal, Mono.S.md)
                    .padding(.bottom, Mono.S.sm)
                    .opacity(appeared ? 1 : 0)

                // ── Filter + Sort toolbar ────────────────────────
                VStack(spacing: 6) {
                    // Type filter pills + search + sort
                    HStack(spacing: 6) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                ForEach(TypeFilter.allCases, id: \.self) { opt in
                                    TypeFilterChip(option: opt, isSelected: typeFilter == opt) {
                                        withAnimation(.spring(duration: 0.2, bounce: 0.3)) {
                                            typeFilter = opt
                                            if opt != .outward { categoryFilter = nil }
                                        }
                                        Haptic.select()
                                    }
                                }
                            }
                        }

                        Spacer(minLength: 0)

                        // Search toggle
                        Button {
                            withAnimation(.spring(duration: 0.25)) { showSearch.toggle() }
                            if !showSearch { searchText = "" }
                            Haptic.light()
                        } label: {
                            Image(systemName: showSearch ? "xmark" : "magnifyingglass")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(showSearch ? Mono.C.accent : Mono.C.textSec)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                    .fill(showSearch ? Mono.C.accent.opacity(0.12) : Mono.C.surfaceUp)
                                    .overlay(RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                        .strokeBorder(showSearch ? Mono.C.accent.opacity(0.4) : Mono.C.border, lineWidth: 0.5)))
                        }
                        .buttonStyle(.plain)

                        // Sort menu
                        Menu {
                            ForEach(SortMode.allCases, id: \.self) { mode in
                                Button {
                                    withAnimation { sortMode = mode }
                                    Haptic.select()
                                } label: {
                                    Label(mode.rawValue, systemImage: sortMode == mode ? "checkmark" : mode.icon)
                                }
                            }
                        } label: {
                            HStack(spacing: 3) {
                                Image(systemName: sortMode.icon)
                                    .font(.system(size: 11, weight: .semibold))
                                Text(sortMode.rawValue)
                                    .font(Mono.T.mono(11, .medium))
                            }
                            .foregroundColor(Mono.C.textSec)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                .fill(Mono.C.surfaceUp)
                                .overlay(RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                    .strokeBorder(Mono.C.border, lineWidth: 0.5)))
                        }
                    }
                    .padding(.horizontal, Mono.S.md)

                    // Search bar
                    if showSearch {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Mono.C.textTert)
                            TextField("Search notes, payees, categories…", text: $searchText)
                                .font(Mono.T.mono(13, .regular))
                                .foregroundColor(Mono.C.text)
                                .tint(Mono.C.accent)
                                .autocorrectionDisabled()
                            if !searchText.isEmpty {
                                Button { searchText = "" } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(Mono.C.textTert)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Mono.S.md)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                .fill(Mono.C.surfaceTop)
                                .overlay(RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                    .strokeBorder(Mono.C.accent.opacity(0.3), lineWidth: 0.8))
                        )
                        .padding(.horizontal, Mono.S.md)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Category sub-filter (only visible when type = All or Out)
                    if typeFilter == .all || typeFilter == .outward {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                ToolbarFilterPill(label: "All Categories", isSelected: categoryFilter == nil) {
                                    withAnimation { categoryFilter = nil }
                                    Haptic.select()
                                }
                                ForEach(Transaction.Category.allCases.filter { !$0.isIncome }) { cat in
                                    let hasData = spendByCategory.contains { $0.0 == cat }
                                    if hasData {
                                        ToolbarFilterPill(label: cat.label, isSelected: categoryFilter == cat) {
                                            withAnimation { categoryFilter = (categoryFilter == cat) ? nil : cat }
                                            Haptic.select()
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, Mono.S.md)
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding(.bottom, Mono.S.sm)

                MonoDivider()

                // ── Content ──────────────────────────────────────
                if filtered.isEmpty {
                    Spacer()
                    VStack(spacing: Mono.S.sm) {
                        Image(systemName: searchText.isEmpty ? "clock.arrow.circlepath" : "magnifyingglass")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(Mono.C.textDim)
                        Text(searchText.isEmpty ? "No transactions" : "No results for \"\(searchText)\"")
                            .font(Mono.T.mono(15, .semibold))
                            .foregroundColor(Mono.C.textSec)
                        Text(searchText.isEmpty ? "Nothing here for this period" : "Try a different search term")
                            .font(Mono.T.caption)
                            .foregroundColor(Mono.C.textTert)
                    }
                    .padding(.horizontal, Mono.S.md)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: Mono.S.lg, pinnedViews: []) {
                            // Category breakdown (all + outward view only)
                            if (typeFilter == .all || typeFilter == .outward) && !spendByCategory.isEmpty && searchText.isEmpty {
                                HistoryCategoryBreakdown(breakdown: spendByCategory, filterCat: $categoryFilter)
                                    .padding(.horizontal, Mono.S.md)
                                    .padding(.top, Mono.S.sm)
                                    .opacity(appeared ? 1 : 0)
                            }

                            ForEach(groupedTransactions, id: \.0) { section, txns in
                                SectionGroup(title: section, transactions: txns)
                                    .padding(.horizontal, Mono.S.md)
                                    .opacity(appeared ? 1 : 0)
                            }

                            // Summary footer
                            if filtered.count > 3 {
                                HistoryFooterSummary(transactions: filtered)
                                    .padding(.horizontal, Mono.S.md)
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.top, Mono.S.sm)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.45, bounce: 0.2).delay(0.08)) { appeared = true }
        }
        .animation(.spring(duration: 0.25), value: typeFilter)
        .animation(.spring(duration: 0.25), value: categoryFilter)
        .animation(.spring(duration: 0.25), value: showSearch)
    }
}

// MARK: - Month Navigator

struct MonthNavigator: View {
    @Binding var selectedMonth: Date

    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"; return f
    }()

    private var canGoForward: Bool {
        let cal = Calendar.current
        return !cal.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
        HStack(spacing: Mono.S.md) {
            // Back
            Button {
                if let prev = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) { selectedMonth = prev }
                    Haptic.light()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Mono.C.textSec)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Mono.C.surfaceUp)
                        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(Mono.C.border, lineWidth: 0.5)))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(Self.fmt.string(from: selectedMonth).uppercased())
                .font(Mono.T.mono(14, .semibold))
                .foregroundColor(Mono.C.text)
                .tracking(1)
                .transition(.push(from: .leading))

            Spacer()

            // Forward
            Button {
                guard canGoForward else { return }
                if let next = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.2)) { selectedMonth = next }
                    Haptic.light()
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(canGoForward ? Mono.C.textSec : Mono.C.textDim)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(canGoForward ? Mono.C.surfaceUp : Mono.C.surface)
                        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(Mono.C.border, lineWidth: 0.5)))
            }
            .buttonStyle(.plain)
            .disabled(!canGoForward)
        }
    }
}

// MARK: - Monthly Summary Bar

struct MonthlySummaryBar: View {
    let inflow:  Double
    let outflow: Double
    let net:     Double
    let count:   Int

    @AppStorage("vault_monochrome") private var isMonochrome = false

    var body: some View {
        HStack(spacing: 0) {
            SummaryPill(icon: "arrow.down.circle.fill", label: "In",  value: inflow,
                        color: isMonochrome ? Mono.C.positive : Mono.C.accent, positive: true)
                .frame(maxWidth: .infinity)
            Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 36)
            SummaryPill(icon: "arrow.up.circle.fill",  label: "Out", value: outflow,
                        color: isMonochrome ? Mono.C.negative : Mono.C.red, positive: false)
                .frame(maxWidth: .infinity)
            Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 36)
            SummaryPill(icon: net >= 0 ? "plus" : "minus", label: "Net", value: abs(net),
                        color: net >= 0 ? (isMonochrome ? Mono.C.positive : Mono.C.accent) : (isMonochrome ? Mono.C.negative : Mono.C.red),
                        positive: net >= 0)
                .frame(maxWidth: .infinity)
            Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 36)
            VStack(spacing: 2) {
                Text("\(count)")
                    .font(Mono.T.mono(16, .bold))
                    .foregroundColor(Mono.C.textSec)
                Text("TXN".uppercased())
                    .font(Mono.T.overline)
                    .foregroundColor(Mono.C.textTert)
                    .tracking(1)
            }
            .padding(.vertical, Mono.S.sm)
            .frame(maxWidth: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                .fill(Mono.C.surface)
                .overlay(RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                    .strokeBorder(Mono.C.border, lineWidth: 0.5))
        )
    }
}

private struct SummaryPill: View {
    let icon: String
    let label: String
    let value: Double
    let color: Color
    let positive: Bool

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(color)
                Text(label.uppercased())
                    .font(Mono.T.overline)
                    .foregroundColor(Mono.C.textTert)
                    .tracking(1)
            }
            Text(value > 0 ? value.indianFormattedCompact : "—")
                .font(Mono.T.mono(15, .bold))
                .foregroundColor(value > 0 ? color : Mono.C.textDim)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(.vertical, Mono.S.sm)
    }
}

// MARK: - Type Filter Chip

struct TypeFilterChip: View {
    let option: HistoryView.TypeFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: option.icon)
                    .font(.system(size: 10, weight: .semibold))
                Text(option.rawValue)
                    .font(Mono.T.mono(11, .semibold))
            }
            .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Mono.C.text : Mono.C.surfaceUp)
                    .overlay(Capsule(style: .continuous)
                        .strokeBorder(isSelected ? .clear : Mono.C.border, lineWidth: 0.5))
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.2, bounce: 0.3), value: isSelected)
    }
}

// MARK: - Category Breakdown (enhanced)

struct HistoryCategoryBreakdown: View {
    let breakdown: [(Transaction.Category, Double)]
    @Binding var filterCat: Transaction.Category?
    @AppStorage("vault_monochrome") private var isMonochrome = false

    private var total: Double { breakdown.reduce(0) { $0 + $1.1 } }

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.sm) {
            HStack {
                OverlineLabel(text: "Spending Breakdown", opacity: 0.45)
                Spacer()
                Text(total.indianFormattedCompact)
                    .font(Mono.T.mono(12, .semibold))
                    .foregroundColor(Mono.C.textSec)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 8) {
                ForEach(Array(breakdown.prefix(6).enumerated()), id: \.offset) { _, pair in
                    let fraction = total > 0 ? pair.1 / total : 0
                    let isFiltered = filterCat == pair.0
                    Button {
                        withAnimation(.spring(duration: 0.2)) {
                            filterCat = (filterCat == pair.0) ? nil : pair.0
                        }
                        Haptic.select()
                    } label: {
                        HStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(isFiltered ? Mono.C.accent.opacity(0.15) : Mono.C.surfaceTop)
                                    .frame(width: 30, height: 30)
                                Image(systemName: pair.0.icon)
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(isFiltered ? Mono.C.accent : Mono.C.textSec)
                            }

                            Text(pair.0.label)
                                .font(Mono.T.mono(12, .medium))
                                .foregroundColor(isFiltered ? Mono.C.accent : Mono.C.textSec)
                                .frame(width: 72, alignment: .leading)

                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(Mono.C.surfaceTop).frame(height: 6)
                                    Capsule()
                                        .fill(isFiltered
                                              ? LinearGradient(colors: [Mono.C.accent, Mono.C.accent.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                                              : LinearGradient(colors: [isMonochrome ? Mono.C.textSec : Mono.C.red.opacity(0.75),
                                                                         isMonochrome ? Mono.C.textTert : Mono.C.red.opacity(0.4)], startPoint: .leading, endPoint: .trailing))
                                        .frame(width: max(geo.size.width * fraction, 4), height: 6)
                                }
                            }
                            .frame(height: 6)

                            Text(pair.1.indianFormattedCompact)
                                .font(Mono.T.mono(11, .medium))
                                .foregroundColor(isFiltered ? Mono.C.accent : Mono.C.textDim)
                                .frame(width: 56, alignment: .trailing)

                            Text("\(Int(fraction * 100))%")
                                .font(Mono.T.mono(10, .regular))
                                .foregroundColor(Mono.C.textDim)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Mono.S.md)
            .monoCard()
        }
    }
}

// MARK: - Section Group

struct SectionGroup: View {
    let title: String
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.sm) {
            HStack {
                OverlineLabel(text: title, opacity: 0.45).padding(.horizontal, 4)
                Spacer()
                Text("\(transactions.count)")
                    .font(Mono.T.mono(10, .medium))
                    .foregroundColor(Mono.C.textDim)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Mono.C.surfaceTop))
            }

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

// MARK: - History Footer Summary

struct HistoryFooterSummary: View {
    let transactions: [Transaction]

    private var total: Double { transactions.reduce(0) { $0 + $1.amount } }
    private var avg:   Double { transactions.isEmpty ? 0 : total / Double(transactions.count) }
    private var max:   Double { transactions.map { $0.amount }.max() ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OverlineLabel(text: "Summary", opacity: 0.4).padding(.horizontal, 4)
                Spacer()
            }
            .padding(.bottom, Mono.S.sm)

            HStack(spacing: 0) {
                FooterStat(label: "Total",   value: total.indianFormattedCompact)
                    .frame(maxWidth: .infinity)
                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 36)
                FooterStat(label: "Average", value: avg.indianFormattedCompact)
                    .frame(maxWidth: .infinity)
                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 36)
                FooterStat(label: "Largest", value: max.indianFormattedCompact)
                    .frame(maxWidth: .infinity)
            }
            .monoCard()
        }
    }
}

private struct FooterStat: View {
    let label: String
    let value: String
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(Mono.T.mono(14, .bold))
                .foregroundColor(Mono.C.textSec)
            Text(label.uppercased())
                .font(Mono.T.overline)
                .foregroundColor(Mono.C.textTert)
                .tracking(1)
        }
        .padding(.vertical, Mono.S.sm)
    }
}

