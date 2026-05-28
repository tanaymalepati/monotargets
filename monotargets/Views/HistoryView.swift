import SwiftUI

struct HistoryView: View {
    @Environment(AppStore.self) private var store
    @State private var filter: FilterOption = .all
    @State private var appeared = false

    enum FilterOption: String, CaseIterable {
        case all     = "All"
        case inward  = "In"
        case outward = "Out"
        case assign  = "Assigned"

        var type: Transaction.TransactionType? {
            switch self {
            case .all:     return nil
            case .inward:  return .inward
            case .outward: return .outward
            case .assign:  return .assign
            }
        }
    }

    private var filtered: [Transaction] {
        guard let t = filter.type else { return store.transactions }
        return store.transactions.filter { $0.type == t }
    }

    private static let monthYearFormatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt
    }()

    private var groupedTransactions: [(String, [Transaction])] {
        let cal = Calendar.current
        var groups: [String: [Transaction]] = [:]
        for t in filtered {
            let key: String
            if cal.isDateInToday(t.date)          { key = "Today" }
            else if cal.isDateInYesterday(t.date) { key = "Yesterday" }
            else                                   { key = Self.monthYearFormatter.string(from: t.date) }
            groups[key, default: []].append(t)
        }
        return groups.sorted { a, b in
            let firstA = a.1.first?.date ?? Date.distantPast
            let firstB = b.1.first?.date ?? Date.distantPast
            return firstA > firstB
        }
    }

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Filter bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            CategoryPill(
                                label: option.rawValue,
                                isSelected: filter == option
                            ) {
                                withAnimation(.spring(duration: 0.25, bounce: 0.3)) {
                                    filter = option
                                }
                                Haptic.select()
                            }
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.vertical, Mono.S.sm)
                }

                if filtered.isEmpty {
                    Spacer()
                    EmptyStateCard(
                        icon: "clock.arrow.circlepath",
                        title: "No transactions",
                        subtitle: "Nothing here yet"
                    )
                    .padding(.horizontal, Mono.S.md)
                    Spacer()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: Mono.S.lg) {
                            // Category breakdown — visible only when showing all transactions
                            if filter == .all && !store.thisMonthSpendByCategory.isEmpty {
                                HistoryCategoryBreakdown()
                                    .padding(.horizontal, Mono.S.md)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 12)
                            }

                            ForEach(groupedTransactions, id: \.0) { section, transactions in
                                SectionGroup(title: section, transactions: transactions)
                                    .padding(.horizontal, Mono.S.md)
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 16)
                            }
                            Spacer(minLength: 100)
                        }
                        .padding(.top, Mono.S.sm)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.2).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Category Breakdown

struct HistoryCategoryBreakdown: View {
    @Environment(AppStore.self) private var store
    @AppStorage("vault_monochrome") private var isMonochrome = false

    private var breakdown: [(Transaction.Category, Double)] {
        store.thisMonthSpendByCategory
    }
    private var total: Double { breakdown.reduce(0) { $0 + $1.1 } }

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.md) {
            HStack {
                OverlineLabel(text: "Spending This Month", opacity: 0.45)
                Spacer()
                Text(total.currencyFormattedCompact)
                    .font(Mono.T.mono(12, .semibold))
                    .foregroundColor(Mono.C.textSec)
            }
            .padding(.horizontal, 4)

            VStack(spacing: 10) {
                ForEach(Array(breakdown.prefix(5).enumerated()), id: \.offset) { _, pair in
                    let fraction = total > 0 ? pair.1 / total : 0
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(Mono.C.surfaceTop)
                                .frame(width: 28, height: 28)
                            Image(systemName: pair.0.icon)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Mono.C.textSec)
                        }

                        Text(pair.0.label)
                            .font(Mono.T.mono(12, .medium))
                            .foregroundColor(Mono.C.textSec)
                            .frame(width: 76, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Mono.C.surfaceTop)
                                    .frame(height: 5)
                                Capsule()
                                    .fill(isMonochrome
                                          ? Mono.C.textSec
                                          : Mono.C.red.opacity(0.75))
                                    .frame(
                                        width: max(geo.size.width * fraction, 4),
                                        height: 5
                                    )
                            }
                        }
                        .frame(height: 5)

                        Text(pair.1.currencyFormattedCompact)
                            .font(Mono.T.mono(11, .medium))
                            .foregroundColor(Mono.C.textDim)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
            }
            .padding(Mono.S.md)
            .monoCard()
        }
    }
}

struct SectionGroup: View {
    let title: String
    let transactions: [Transaction]

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.sm) {
            OverlineLabel(text: title, opacity: 0.45)
                .padding(.horizontal, 4)

            VStack(spacing: 1) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, t in
                    TransactionRowView(transaction: t)
                        .padding(.horizontal, Mono.S.md)

                    if index < transactions.count - 1 {
                        MonoDivider()
                            .padding(.horizontal, Mono.S.lg)
                    }
                }
            }
            .monoCard()
        }
    }
}
