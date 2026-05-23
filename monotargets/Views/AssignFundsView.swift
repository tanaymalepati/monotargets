import SwiftUI

struct AssignFundsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: SavingsItem

    @State private var digits = ""
    @State private var showSuccess = false

    private var amount: Double { AmountFormatter.toDoubleFromDigits(digits) }
    private var isValid: Bool  { amount > 0 && amount <= store.totalUnassigned }
    private var overflows: Bool { amount > store.totalUnassigned }

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            VStack(spacing: 0) {

                // ── Drag handle
                Capsule()
                    .fill(Mono.C.borderBright)
                    .frame(width: 36, height: 4)
                    .padding(.top, 14)
                    .padding(.bottom, Mono.S.md)

                // ── Header row
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(Mono.T.mono(14, .medium))
                        .foregroundColor(Mono.C.textSec)

                    Spacer()

                    Text("Assign Funds")
                        .font(Mono.T.mono(15, .semibold))
                        .foregroundColor(Mono.C.text)

                    Spacer()

                    // Balance available (right-aligned, mirrors Cancel width)
                    Text(store.totalUnassigned.indianFormattedCompact)
                        .font(Mono.T.mono(14, .semibold))
                        .foregroundColor(Mono.C.textSec)
                        .frame(minWidth: 44, alignment: .trailing)
                }
                .padding(.horizontal, Mono.S.lg)
                .padding(.bottom, Mono.S.md)

                MonoDivider()
                    .padding(.horizontal, Mono.S.md)
                    .padding(.bottom, Mono.S.md)

                // ── Item summary card
                HStack(spacing: Mono.S.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                            .fill(Mono.C.surfaceTop)
                            .frame(width: 42, height: 42)
                        Image(systemName: item.icon)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Mono.C.textSec)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.name)
                            .font(Mono.T.mono(15, .semibold))
                            .foregroundColor(Mono.C.text)
                            .lineLimit(1)
                        Text("\(item.assignedAmount.indianFormattedCompact) of \(item.targetAmount.indianFormattedCompact)")
                            .font(Mono.T.mono(11, .regular))
                            .foregroundColor(Mono.C.textTert)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        ProgressRing(progress: item.progress, size: 38, lineWidth: 3)
                        Text("\(Int(item.progress * 100))%")
                            .font(Mono.T.mono(10, .medium))
                            .foregroundColor(Mono.C.textDim)
                    }
                }
                .padding(Mono.S.md)
                .monoCard()
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.md)

                // ── Amount input
                AmountInputField(digits: $digits, placeholder: "0", fontSize: 42)
                    .padding(.horizontal, Mono.S.xl)
                    .padding(.bottom, Mono.S.xs)

                // Overflow warning
                if overflows {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 11, weight: .medium))
                        Text("Exceeds available balance")
                            .font(Mono.T.mono(12, .regular))
                    }
                    .foregroundColor(Mono.C.negative)
                    .padding(.bottom, Mono.S.xs)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // ── Quick assign pills
                let remaining  = item.remaining
                let unassigned = store.totalUnassigned
                let maxAmount  = min(remaining, unassigned)

                if maxAmount > 0 {
                    HStack(spacing: 8) {
                        QuickAssignPill(label: "25%", amount: (maxAmount * 0.25).rounded()) {
                            digits = String(Int((maxAmount * 0.25).rounded()))
                            Haptic.light()
                        }
                        QuickAssignPill(label: "50%", amount: (maxAmount * 0.5).rounded()) {
                            digits = String(Int((maxAmount * 0.5).rounded()))
                            Haptic.light()
                        }
                        QuickAssignPill(label: "Max", amount: maxAmount) {
                            digits = String(Int(maxAmount))
                            Haptic.light()
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.bottom, Mono.S.sm)
                }

                // ── Numpad
                MonoNumpad(digits: $digits) { commitAssign() }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.top, Mono.S.xs)

                // ── Confirm button
                Button(action: commitAssign) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 15))
                        Text(amount > 0 ? "Assign \(amount.indianFormattedCompact)" : "Assign Funds")
                            .font(Mono.T.mono(15, .semibold))
                    }
                    .foregroundColor(isValid ? Mono.C.bg : Mono.C.textDim)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .fill(isValid ? Mono.C.text : Mono.C.surfaceUp)
                    )
                    .animation(.spring(duration: 0.25, bounce: 0.2), value: isValid)
                }
                .disabled(!isValid)
                .buttonStyle(.plain)
                .padding(.horizontal, Mono.S.md)
                .padding(.top, Mono.S.sm)
                .padding(.bottom, Mono.S.lg)
            }

            if showSuccess {
                SuccessCheckmark()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.25, bounce: 0.2), value: overflows)
    }

    private func commitAssign() {
        guard isValid else { Haptic.error(); return }
        store.assignFunds(to: item.id, amount: amount)
        Haptic.success()
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
    }
}

// MARK: - Quick Assign Pill

struct QuickAssignPill: View {
    let label: String
    let amount: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
