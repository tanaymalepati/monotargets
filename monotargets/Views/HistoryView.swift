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

    private var groupedTransactions: [(String, [Transaction])] {
        let cal = Calendar.current
        var groups: [String: [Transaction]] = [:]
        for t in filtered {
            let key: String
            if cal.isDateInToday(t.date)     { key = "Today" }
            else if cal.isDateInYesterday(t.date) { key = "Yesterday" }
            else {
                let components = cal.dateComponents([.year, .month], from: t.date)
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                key = formatter.string(from: t.date)
            }
            groups[key, default: []].append(t)
        }
        // Sort by most recent first
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
