import SwiftUI

struct UnassignFundsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: SavingsItem

    @AppStorage("vault_monochrome") private var isMonochrome = false

    @State private var digits = ""
    @State private var showSuccess = false

    private var amount: Double { AmountFormatter.toDoubleFromDigits(digits) }
    private var isValid: Bool  { amount > 0 && amount <= item.assignedAmount }
    private var overflows: Bool { amount > item.assignedAmount }

    var body: some View {
        ZStack {
            Color(white: 0.035).ignoresSafeArea()

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

                    Text("Unassign Funds")
                        .font(Mono.T.mono(15, .semibold))
                        .foregroundColor(Mono.C.text)

                    Spacer()

                    // Currently assigned (mirrors Cancel width)
                    Text(item.assignedAmount.indianFormattedCompact)
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
                        Text("\(item.assignedAmount.indianFormattedCompact) currently assigned")
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
                        Text("Exceeds assigned amount")
                            .font(Mono.T.mono(12, .regular))
                    }
                    .foregroundColor(Mono.C.negative)
                    .padding(.bottom, Mono.S.xs)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // ── Quick pills
                let assigned = item.assignedAmount

                if assigned > 0 {
                    HStack(spacing: 8) {
                        QuickAssignPill(label: "25%", amount: (assigned * 0.25).rounded()) {
                            digits = String(Int((assigned * 0.25).rounded()))
                            Haptic.light()
                        }
                        QuickAssignPill(label: "50%", amount: (assigned * 0.5).rounded()) {
                            digits = String(Int((assigned * 0.5).rounded()))
                            Haptic.light()
                        }
                        QuickAssignPill(label: "All", amount: assigned) {
                            digits = String(Int(assigned))
                            Haptic.light()
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.bottom, Mono.S.sm)
                }

                // ── Numpad
                MonoNumpad(digits: $digits, showConfirmKey: false) { commitUnassign() }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.top, Mono.S.xs)

                // ── Confirm button
                Button(action: commitUnassign) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 15))
                        Text(amount > 0 ? "Unassign \(amount.indianFormattedCompact)" : "Unassign Funds")
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

    private func commitUnassign() {
        guard isValid else { Haptic.error(); return }
        store.unassignFunds(from: item.id, amount: amount)
        Haptic.success()
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss() }
    }
}
