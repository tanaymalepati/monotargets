import SwiftUI

struct AssignFundsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: SavingsItem

    @State private var digits = ""
    @State private var showSuccess = false

    private var amount: Double { AmountFormatter.toDoubleFromDigits(digits) }
    private var isValid: Bool { amount > 0 && amount <= store.totalUnassigned }
    private var overflows: Bool { amount > store.totalUnassigned }

    var body: some View {
        NavigationStack {
            ZStack {
                Mono.C.bg.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Item summary
                    HStack(spacing: Mono.S.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                                .fill(Mono.C.surfaceTop)
                                .frame(width: 44, height: 44)
                            Image(systemName: item.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Mono.C.textSec)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.name)
                                .font(Mono.T.mono(16, .semibold))
                                .foregroundColor(Mono.C.text)

                            Text("\(item.assignedAmount.indianFormatted) / \(item.targetAmount.indianFormatted)")
                                .font(Mono.T.mono(12, .regular))
                                .foregroundColor(Mono.C.textTert)
                        }

                        Spacer()

                        ProgressRing(progress: item.progress, size: 40, lineWidth: 3)
                    }
                    .padding(Mono.S.md)
                    .monoCard()
                    .padding(.horizontal, Mono.S.md)
                    .padding(.top, Mono.S.md)

                    // Available balance
                    HStack {
                        OverlineLabel(text: "Available to assign")
                        Spacer()
                        Text(store.totalUnassigned.indianFormatted)
                            .font(Mono.T.mono(15, .semibold))
                            .foregroundColor(Mono.C.text)
                    }
                    .padding(.horizontal, Mono.S.lg)
                    .padding(.vertical, Mono.S.md)

                    MonoDivider()
                        .padding(.horizontal, Mono.S.md)

                    Spacer().frame(height: Mono.S.lg)

                    // Amount input
                    AmountInputField(digits: $digits, placeholder: "0", fontSize: 44)
                        .padding(.horizontal, Mono.S.xl)

                    // Overflow warning
                    if overflows {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 11, weight: .medium))
                            Text("Exceeds unassigned balance")
                                .font(Mono.T.mono(12, .regular))
                        }
                        .foregroundColor(Mono.C.negative)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Quick assign presets
                    HStack(spacing: 8) {
                        let remaining = item.remaining
                        let unassigned = store.totalUnassigned
                        let max = min(remaining, unassigned)

                        if max > 0 {
                            QuickAssignPill(
                                label: "25%",
                                amount: min(max * 0.25, unassigned)
                            ) { digits = String(Int(min(max * 0.25, unassigned))) }

                            QuickAssignPill(
                                label: "50%",
                                amount: min(max * 0.5, unassigned)
                            ) { digits = String(Int(min(max * 0.5, unassigned))) }

                            QuickAssignPill(
                                label: "Max",
                                amount: max
                            ) { digits = String(Int(max)) }
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.top, Mono.S.md)

                    Spacer().frame(height: Mono.S.md)

                    // Numpad
                    MonoNumpad(digits: $digits) {
                        commitAssign()
                    }
                    .padding(.horizontal, Mono.S.md)

                    // Confirm button
                    Button(action: commitAssign) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 16))
                            Text("Assign \(amount > 0 ? amount.indianFormattedCompact : "Funds")")
                                .font(Mono.T.mono(16, .semibold))
                        }
                        .foregroundColor(isValid ? Mono.C.bg : Mono.C.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                .fill(isValid ? Mono.C.text : Mono.C.surfaceUp)
                        )
                        .padding(.horizontal, Mono.S.md)
                        .animation(.spring(duration: 0.3, bounce: 0.2), value: isValid)
                    }
                    .disabled(!isValid)
                    .buttonStyle(.plain)
                    .padding(.vertical, Mono.S.md)
                }

                if showSuccess {
                    SuccessCheckmark()
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3, bounce: 0.2), value: overflows)
            .navigationTitle("Assign Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(Mono.T.body)
                        .foregroundColor(Mono.C.textSec)
                }
            }
        }
    }

    private func commitAssign() {
        guard isValid else {
            Haptic.error()
            return
        }
        store.assignFunds(to: item.id, amount: amount)
        Haptic.success()
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
    }
}

struct QuickAssignPill: View {
    let label: String
    let amount: Double
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            Haptic.light()
        }) {
            VStack(spacing: 2) {
                Text(label)
                    .font(Mono.T.mono(12, .semibold))
                    .foregroundColor(Mono.C.text)
                Text(amount.indianFormattedCompact)
                    .font(Mono.T.mono(10, .regular))
                    .foregroundColor(Mono.C.textTert)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                    .fill(Mono.C.surfaceTop)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .strokeBorder(Mono.C.border, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
