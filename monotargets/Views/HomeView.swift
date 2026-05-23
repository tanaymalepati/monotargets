import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    @State private var balanceScale: CGFloat = 0.85
    @State private var balanceOpacity: Double = 0
    @State private var cardsOffset: CGFloat = 30

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Mono.C.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Mono.S.lg) {
                    // Balance hero card
                    BalanceHeroCard()
                        .scaleEffect(balanceScale)
                        .opacity(balanceOpacity)
                        .padding(.horizontal, Mono.S.md)
                        .padding(.top, Mono.S.sm)

                    // Goals horizontal scroll
                    if !store.savingsItems.isEmpty {
                        GoalsScrollSection()
                            .offset(y: cardsOffset)
                            .opacity(cardsOffset == 0 ? 1 : 0)
                    }

                    // Recent transactions
                    RecentTransactionsSection()
                        .offset(y: cardsOffset)
                        .opacity(cardsOffset == 0 ? 1 : 0)

                    Spacer(minLength: 100)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.35).delay(0.1)) {
                balanceScale = 1.0
                balanceOpacity = 1.0
            }
            withAnimation(.spring(duration: 0.6, bounce: 0.2).delay(0.3)) {
                cardsOffset = 0
            }
        }
    }
}

// MARK: - Balance Hero Card

struct BalanceHeroCard: View {
    @Environment(AppStore.self) private var store

    @State private var innerScale: CGFloat = 1.0
    @State private var showBreakdown = false

    var body: some View {
        VStack(spacing: 0) {
            // Top: total balance
            VStack(alignment: .leading, spacing: Mono.S.xs) {
                OverlineLabel(text: "Total Balance")
                    .padding(.bottom, 2)

                AnimatedAmountText(
                    digits: amountDigits(store.totalBalance),
                    fontSize: 52,
                    weight: .bold
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                Text(VaultDateFormatter.display.string(from: Date()))
                    .font(Mono.T.label)
                    .foregroundColor(Mono.C.textTert)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.top, Mono.S.lg)
            .padding(.bottom, Mono.S.md)

            // Divider
            MonoDivider()
                .padding(.horizontal, Mono.S.lg)

            // Bottom: breakdown
            HStack(spacing: 0) {
                BalanceStat(
                    label: "Unassigned",
                    amount: store.totalUnassigned,
                    icon: "circle.dotted"
                )
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Mono.C.border)
                    .frame(width: 0.5, height: 48)

                BalanceStat(
                    label: "Assigned",
                    amount: store.totalAssigned,
                    icon: "checkmark.circle"
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.top, Mono.S.md)
            .padding(.bottom, Mono.S.sm)

            // Progress bar
            BalanceSegmentBar(
                assigned: store.totalAssigned,
                unassigned: store.totalUnassigned
            )
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.lg)

            // Stats row
            HStack(spacing: Mono.S.lg) {
                MiniStat(
                    value: "\(store.savingsItems.count)",
                    label: "Goals"
                )
                MiniStat(
                    value: "\(store.completedGoals)",
                    label: "Funded"
                )
                MiniStat(
                    value: "\(store.transactions.count)",
                    label: "Entries"
                )
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.md)
        }
        .monoHeroCard()
        .scaleEffect(innerScale)
        .onTapGesture {
            withAnimation(.spring(duration: 0.15, bounce: 0.6)) { innerScale = 0.97 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(duration: 0.3, bounce: 0.4)) { innerScale = 1.0 }
            }
        }
    }

    private func amountDigits(_ amount: Double) -> String {
        String(Int(max(amount, 0)))
    }
}

struct BalanceStat: View {
    let label: String
    let amount: Double
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Mono.C.textTert)
                OverlineLabel(text: label)
            }
            Text(amount.indianFormattedCompact)
                .font(Mono.T.mono(22, .semibold))
                .foregroundColor(Mono.C.text)
        }
        .padding(.horizontal, Mono.S.lg)
        .padding(.bottom, Mono.S.sm)
    }
}

struct MiniStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Mono.T.mono(18, .bold))
                .foregroundColor(Mono.C.text)
            Text(label.uppercased())
                .font(Mono.T.overline)
                .foregroundColor(Mono.C.textTert)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Goals Horizontal Scroll

struct GoalsScrollSection: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.md) {
            HStack {
                OverlineLabel(text: "Savings Goals", opacity: 0.5)
                Spacer()
                Text("\(store.savingsItems.count) goals")
                    .font(Mono.T.label)
                    .foregroundColor(Mono.C.textDim)
            }
            .padding(.horizontal, Mono.S.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(store.savingsItems.prefix(6).enumerated()), id: \.element.id) { index, item in
                        GoalMiniCard(item: item)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                            .animation(.spring(duration: 0.4, bounce: 0.3).delay(Double(index) * 0.06), value: store.savingsItems.count)
                    }
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.vertical, 4)
            }
        }
    }
}

struct GoalMiniCard: View {
    let item: SavingsItem
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                        .fill(item.isFullyFunded ? Mono.C.text : Mono.C.surfaceTop)
                        .frame(width: 38, height: 38)

                    Image(systemName: item.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(item.isFullyFunded ? Mono.C.bg : Mono.C.textSec)
                }

                Spacer()

                ProgressRing(progress: item.progress, size: 34, lineWidth: 2.5)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(Mono.T.mono(13, .semibold))
                    .foregroundColor(Mono.C.text)
                    .lineLimit(1)

                Text(item.assignedAmount.indianFormattedCompact)
                    .font(Mono.T.mono(11, .regular))
                    .foregroundColor(Mono.C.textTert)
            }

            // Progress bar
            MonoProgressBar(progress: item.progress, height: 3)

            if let targetDate = item.targetDate {
                let days = item.daysUntilTarget ?? 0
                Text(days >= 0 ? "\(VaultDateFormatter.daysRemaining(targetDate)) left" : "Overdue")
                    .font(Mono.T.mono(10, .medium))
                    .foregroundColor(days < 0 ? Mono.C.negative : Mono.C.textDim)
            }
        }
        .padding(Mono.S.md)
        .frame(width: 150)
        .monoCard(elevated: true)
        .scaleEffect(appeared ? 1.0 : 0.88)
        .opacity(appeared ? 1.0 : 0)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                appeared = true
            }
        }
    }
}

// MARK: - Recent Transactions

struct RecentTransactionsSection: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.md) {
            HStack {
                OverlineLabel(text: "Recent", opacity: 0.5)
                Spacer()
                if store.transactions.count > 5 {
                    Text("See all →")
                        .font(Mono.T.label)
                        .foregroundColor(Mono.C.textDim)
                }
            }
            .padding(.horizontal, Mono.S.md)

            if store.transactions.isEmpty {
                EmptyStateCard(
                    icon: "arrow.down.circle",
                    title: "No transactions yet",
                    subtitle: "Pull down to log your first transaction"
                )
                .padding(.horizontal, Mono.S.md)
            } else {
                VStack(spacing: 1) {
                    ForEach(Array(store.recentTransactions.prefix(5).enumerated()), id: \.element.id) { index, t in
                        TransactionRowView(transaction: t)
                            .padding(.horizontal, Mono.S.md)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(
                                .spring(duration: 0.4, bounce: 0.2).delay(Double(index) * 0.05),
                                value: store.transactions.count
                            )

                        if index < min(store.recentTransactions.count, 5) - 1 {
                            MonoDivider()
                                .padding(.horizontal, Mono.S.lg)
                        }
                    }
                }
                .monoCard()
                .padding(.horizontal, Mono.S.md)
            }
        }
    }
}

// MARK: - Empty State Card

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Mono.S.sm) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Mono.C.textDim)
                .padding(.bottom, 4)

            Text(title)
                .font(Mono.T.mono(15, .semibold))
                .foregroundColor(Mono.C.textSec)

            Text(subtitle)
                .font(Mono.T.caption)
                .foregroundColor(Mono.C.textTert)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Mono.S.xxl)
        .monoCard()
    }
}

// MARK: - Transaction Row

struct TransactionRowView: View {
    @Environment(AppStore.self) private var store
    let transaction: Transaction
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: Mono.S.md) {
            ZStack {
                Circle()
                    .fill(Mono.C.surfaceUp)
                    .frame(width: 36, height: 36)

                Image(systemName: transaction.type.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(
                        transaction.type == .inward ? Mono.C.positive : Mono.C.negative
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? transaction.type.label : transaction.note)
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.text)
                    .lineLimit(1)

                Text(VaultDateFormatter.relativeDate(transaction.date))
                    .font(Mono.T.mono(11, .regular))
                    .foregroundColor(Mono.C.textTert)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text((transaction.type.isDebit ? "-" : "+") + transaction.amount.indianFormattedNoSymbol)
                    .font(Mono.T.mono(15, .semibold))
                    .foregroundColor(transaction.type.isDebit ? Mono.C.negative : Mono.C.positive)

                Text("₹")
                    .font(Mono.T.mono(10, .medium))
                    .foregroundColor(Mono.C.textDim)
            }

            // Chevron hint
            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Mono.C.textDim)
        }
        .padding(.vertical, Mono.S.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail = true
            Haptic.light()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                    store.deleteTransaction(id: transaction.id)
                }
                Haptic.medium()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showDetail) {
            TransactionDetailSheet(transaction: transaction)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(Mono.C.bg)
        }
    }
}

// MARK: - Transaction Detail Sheet

struct TransactionDetailSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var amountColor: Color {
        transaction.type.isDebit ? Mono.C.negative : Mono.C.positive
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Drag handle
            Capsule()
                .fill(Mono.C.borderBright)
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, Mono.S.md)

            // ── Header row
            HStack {
                Text("Transaction")
                    .font(Mono.T.mono(15, .semibold))
                    .foregroundColor(Mono.C.text)
                Spacer()
                Button("Done") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.lg)

            // ── Amount hero card
            VStack(spacing: 10) {
                // Type badge
                HStack(spacing: 6) {
                    Image(systemName: transaction.type.symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(amountColor)
                    Text(transaction.type.label.uppercased())
                        .font(Mono.T.overline)
                        .foregroundColor(Mono.C.textDim)
                        .tracking(2)
                }

                // Large amount
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(transaction.type.isDebit ? "-₹" : "+₹")
                        .font(Mono.T.mono(22, .medium))
                        .foregroundColor(amountColor.opacity(0.55))
                    Text(transaction.amount.indianFormattedNoSymbol)
                        .font(Mono.T.mono(46, .bold))
                        .foregroundColor(amountColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Mono.S.lg)
            .monoCard(elevated: true)
            .padding(.horizontal, Mono.S.md)

            // ── Meta rows
            VStack(spacing: 0) {
                DetailRow(
                    icon: "text.alignleft",
                    label: "Note",
                    value: transaction.note.isEmpty ? "—" : transaction.note
                )
                MonoDivider().padding(.horizontal, Mono.S.md)
                DetailRow(
                    icon: "calendar",
                    label: "Date",
                    value: VaultDateFormatter.full.string(from: transaction.date)
                )
                MonoDivider().padding(.horizontal, Mono.S.md)
                DetailRow(
                    icon: "number",
                    label: "ID",
                    value: String(transaction.id.uuidString.prefix(8)).uppercased()
                )
            }
            .monoCard()
            .padding(.horizontal, Mono.S.md)
            .padding(.top, Mono.S.md)

            Spacer(minLength: Mono.S.lg)

            // ── Action buttons
            VStack(spacing: 8) {
                Button {
                    showEdit = true
                    Haptic.medium()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 15))
                        Text("Edit Transaction")
                            .font(Mono.T.mono(15, .semibold))
                    }
                    .foregroundColor(Mono.C.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .fill(Mono.C.text)
                    )
                }
                .buttonStyle(.plain)

                DangerButton(icon: "trash", label: "Delete Transaction") {
                    showDeleteConfirm = true
                }
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.bottom, Mono.S.xl)
        }
        .background(Mono.C.bg.ignoresSafeArea())
        .confirmationDialog(
            "Delete this transaction?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                store.deleteTransaction(id: transaction.id)
                Haptic.medium()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showEdit) {
            EditTransactionView(transaction: transaction)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Mono.C.bg)
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Mono.S.md) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Mono.C.textDim)
                .frame(width: 18)

            Text(label)
                .font(Mono.T.mono(13, .regular))
                .foregroundColor(Mono.C.textTert)

            Spacer()

            Text(value)
                .font(Mono.T.mono(13, .medium))
                .foregroundColor(Mono.C.textSec)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(Mono.S.md)
    }
}
