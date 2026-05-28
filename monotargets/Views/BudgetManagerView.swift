import SwiftUI

// MARK: - Budget Manager View

struct BudgetManagerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss)     private var dismiss

    @State private var editingCategory: Transaction.Category? = nil
    @State private var editAmount = ""

    /// Categories eligible for budgeting (expense only)
    private var expenseCategories: [Transaction.Category] {
        Transaction.Category.allCases.filter { !$0.isIncome }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Rectangle()
                .fill(LinearGradient(colors: [Color.white.opacity(0.10), .clear], startPoint: .top, endPoint: .bottom))
                .frame(height: 1)

            Capsule()
                .fill(Color(white: 0.40))
                .frame(width: 44, height: 6)
                .padding(.top, 14)
                .padding(.bottom, 16)

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Monthly Budgets")
                        .font(Mono.T.mono(17, .bold))
                        .foregroundColor(Mono.C.text)
                    Text("Set limits for each spending category")
                        .font(Mono.T.mono(11, .regular))
                        .foregroundColor(Mono.C.textTert)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.lg)

            MonoDivider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 1) {
                    ForEach(Array(expenseCategories.enumerated()), id: \.element.id) { i, cat in
                        BudgetCategoryRow(
                            category: cat,
                            budget:   store.budgets.first { $0.category == cat },
                            spent:    store.spent(in: cat)
                        ) {
                            editingCategory = cat
                            let existing = store.budgets.first { $0.category == cat }?.monthlyLimit
                            editAmount = existing.map { String(Int($0)) } ?? ""
                        }

                        if i < expenseCategories.count - 1 {
                            MonoDivider().padding(.horizontal, Mono.S.md)
                        }
                    }
                }
                .monoCard()
                .padding(Mono.S.md)
                .padding(.bottom, Mono.S.xxl)
            }
        }
        .background(Mono.C.bg.ignoresSafeArea())
        .sheet(item: $editingCategory) { cat in
            BudgetEditSheet(
                category: cat,
                amount: $editAmount,
                onSave: { limit in
                    store.setBudget(for: cat, limit: limit)
                    editingCategory = nil
                    Haptic.success()
                },
                onRemove: {
                    store.removeBudget(for: cat)
                    editingCategory = nil
                    Haptic.medium()
                }
            )
            .presentationDetents([.fraction(0.52)])
            .presentationDragIndicator(.hidden)
            .presentationBackground(Color(white: 0.065))
            .presentationCornerRadius(24)
        }
    }
}

// MARK: - Budget Category Row

struct BudgetCategoryRow: View {
    let category: Transaction.Category
    let budget: Budget?
    let spent: Double
    let onTap: () -> Void

    private var limit: Double { budget?.monthlyLimit ?? 0 }
    private var fraction: Double {
        guard limit > 0 else { return 0 }
        return min(spent / limit, 1.0)
    }
    private var isOver: Bool { limit > 0 && spent > limit }

    var body: some View {
        Button(action: { onTap(); Haptic.light() }) {
            HStack(spacing: Mono.S.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                        .fill(Mono.C.surfaceTop)
                        .frame(width: 38, height: 38)
                    Image(systemName: category.icon)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isOver ? Mono.C.red : Mono.C.textSec)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.label)
                            .font(Mono.T.mono(13, .semibold))
                            .foregroundColor(Mono.C.text)
                        Spacer()
                        if limit > 0 {
                            Text("\(spent.indianFormattedCompact) / \(limit.indianFormattedCompact)")
                                .font(Mono.T.mono(11, .medium))
                                .foregroundColor(isOver ? Mono.C.red : Mono.C.textTert)
                        } else {
                            Text("No limit")
                                .font(Mono.T.mono(11, .regular))
                                .foregroundColor(Mono.C.textDim)
                        }
                    }

                    if limit > 0 {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2).fill(Mono.C.surfaceTop)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isOver ? Mono.C.red : Mono.C.accent)
                                    .frame(width: geo.size.width * fraction)
                                    .animation(.spring(duration: 0.6, bounce: 0.1), value: fraction)
                            }
                        }
                        .frame(height: 4)
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Mono.C.textDim)
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Budget Edit Sheet

struct BudgetEditSheet: View {
    let category: Transaction.Category
    @Binding var amount: String
    let onSave: (Double) -> Void
    let onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var parsedAmount: Double? {
        guard let d = Double(amount), d > 0 else { return nil }
        return d
    }

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color(white: 0.40))
                .frame(width: 44, height: 6)
                .padding(.top, 14)
                .padding(.bottom, 16)

            HStack {
                Image(systemName: category.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Mono.C.textSec)
                Text(category.label + " Budget")
                    .font(Mono.T.mono(16, .bold))
                    .foregroundColor(Mono.C.text)
                Spacer()
                Button("Cancel") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.lg)

            Text("Monthly limit for \(category.label.lowercased()) spending")
                .font(Mono.T.mono(12, .regular))
                .foregroundColor(Mono.C.textTert)
                .padding(.bottom, Mono.S.md)

            // Amount input
            HStack {
                Text(CurrencyInfo.current.symbol)
                    .font(Mono.T.mono(24, .bold))
                    .foregroundColor(Mono.C.textSec)
                TextField("0", text: $amount)
                    .font(Mono.T.mono(38, .bold))
                    .foregroundColor(Mono.C.text)
                    .keyboardType(.numberPad)
                    .tint(Mono.C.accent)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, Mono.S.xl)
            .padding(.vertical, Mono.S.md)

            // Quick presets
            HStack(spacing: 8) {
                ForEach([2000, 5000, 10000, 20000], id: \.self) { preset in
                    Button {
                        amount = String(preset)
                        Haptic.light()
                    } label: {
                        Text(Double(preset).indianFormattedCompact)
                            .font(Mono.T.mono(12, .medium))
                            .foregroundColor(Mono.C.textSec)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Mono.C.surfaceTop)
                                .overlay(Capsule().strokeBorder(Mono.C.border, lineWidth: 0.5)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, Mono.S.lg)

            VStack(spacing: 8) {
                Button {
                    if let a = parsedAmount { onSave(a) }
                } label: {
                    Text("Set Budget")
                        .font(Mono.T.mono(15, .semibold))
                        .foregroundColor(parsedAmount != nil ? Mono.C.bg : Mono.C.textTert)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                .fill(parsedAmount != nil ? Mono.C.text : Mono.C.surfaceTop)
                        )
                }
                .buttonStyle(.plain)
                .disabled(parsedAmount == nil)

                Button {
                    onRemove()
                } label: {
                    Text("Remove Budget")
                        .font(Mono.T.mono(13, .medium))
                        .foregroundColor(Mono.C.red.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                                .fill(Mono.C.surfaceUp)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Mono.S.lg)
        }
    }
}

