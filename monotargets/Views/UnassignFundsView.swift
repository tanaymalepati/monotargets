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

    private var previewProgress: Double {
        guard item.targetAmount > 0 else { return 0 }
        return max((item.assignedAmount - amount) / item.targetAmount, 0)
    }

    private var accentColor: Color { isMonochrome ? Mono.C.negative : Mono.C.red }

    var body: some View {
        ZStack {
            Color(white: 0.035).ignoresSafeArea()

            // Subtle red ambient glow from top
            if !isMonochrome {
                LinearGradient(
                    colors: [Mono.C.red.opacity(0.06), .clear],
                    startPoint: .top,
                    endPoint: .init(x: 0.5, y: 0.30)
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 0) {

                // ── Drag handle (prominent)
                Capsule()
                    .fill(Mono.C.borderBright)
                    .frame(width: 40, height: 5)
                    .padding(.top, 14)
                    .padding(.bottom, Mono.S.md)

                // ── Header row
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(Mono.T.mono(14, .medium))
                        .foregroundColor(Mono.C.textSec)

                    Spacer()

                    VStack(spacing: 2) {
                        Text("Unassign Funds")
                            .font(Mono.T.mono(15, .semibold))
                            .foregroundColor(Mono.C.text)
                        if !isMonochrome {
                            Text("•")
                                .font(.system(size: 6))
                                .foregroundColor(Mono.C.red)
                        }
                    }

                    Spacer()

                    // Currently assigned
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.assignedAmount.indianFormattedCompact)
                            .font(Mono.T.mono(13, .semibold))
                            .foregroundColor(Mono.C.textSec)
                        Text("assigned")
                            .font(Mono.T.mono(9, .regular))
                            .foregroundColor(Mono.C.textDim)
                    }
                    .frame(minWidth: 54, alignment: .trailing)
                }
                .padding(.horizontal, Mono.S.lg)
                .padding(.bottom, Mono.S.md)

                MonoDivider()
                    .padding(.horizontal, Mono.S.md)
                    .padding(.bottom, Mono.S.md)

                // ── Item summary card (with preview progress)
                HStack(spacing: Mono.S.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Mono.C.surfaceTop, Mono.C.surfaceUp],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                                    .strokeBorder(Mono.C.border, lineWidth: 0.5)
                            )
                        Image(systemName: item.icon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Mono.C.textSec)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.name)
                            .font(Mono.T.mono(14, .semibold))
                            .foregroundColor(Mono.C.text)
                            .lineLimit(1)

                        // Progress bar — shows shrinkage preview when typing
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(Mono.C.surfaceTop)
                                    .frame(height: 4)

                                // Ghost of current fill (shows what will be removed)
                                if amount > 0 {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .fill(accentColor.opacity(0.18))
                                        .frame(
                                            width: geo.size.width * item.progress,
                                            height: 4
                                        )
                                }

                                // Remaining fill after unassign
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: isMonochrome
                                                ? [Color(white: 0.55), Color(white: 0.40)]
                                                : [Mono.C.accent.opacity(0.7), Mono.C.accent],
                                            startPoint: .leading, endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geo.size.width * (amount > 0 ? previewProgress : item.progress),
                                        height: 4
                                    )
                                    .animation(.spring(duration: 0.4, bounce: 0.2), value: previewProgress)
                            }
                        }
                        .frame(height: 4)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        ProgressRing(progress: amount > 0 ? previewProgress : item.progress, size: 38, lineWidth: 3)
                        Text(amount > 0 ? "\(Int(previewProgress * 100))%" : "\(Int(item.progress * 100))%")
                            .font(Mono.T.mono(10, .medium))
                            .foregroundColor(amount > 0 ? accentColor : Mono.C.textDim)
                            .animation(.spring(duration: 0.3), value: amount > 0)
                    }
                }
                .padding(Mono.S.md)
                .monoCard(elevated: true)
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.md)

                // ── Amount input with red glow when active
                ZStack {
                    if amount > 0 && !isMonochrome {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Mono.C.red.opacity(0.04))
                            .blur(radius: 8)
                            .padding(.horizontal, Mono.S.xl)
                    }
                    AmountInputField(digits: $digits, placeholder: "0", fontSize: 42)
                        .padding(.horizontal, Mono.S.xl)
                }
                .padding(.bottom, Mono.S.xs)
                .animation(.spring(duration: 0.3, bounce: 0.2), value: amount > 0)

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

                // ── Quick pills (with red tint)
                let assigned = item.assignedAmount

                if assigned > 0 {
                    HStack(spacing: 8) {
                        QuickAssignPill(
                            label: "25%",
                            amount: (assigned * 0.25).rounded(),
                            tint: accentColor
                        ) {
                            digits = String(Int((assigned * 0.25).rounded()))
                            Haptic.light()
                        }
                        QuickAssignPill(
                            label: "50%",
                            amount: (assigned * 0.5).rounded(),
                            tint: accentColor
                        ) {
                            digits = String(Int((assigned * 0.5).rounded()))
                            Haptic.light()
                        }
                        QuickAssignPill(
                            label: "All",
                            amount: assigned,
                            tint: accentColor
                        ) {
                            digits = String(Int(assigned))
                            Haptic.light()
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.bottom, Mono.S.sm)
                }

                // ── Numpad (red flash on digit keys)
                MonoNumpad(
                    digits: $digits,
                    showConfirmKey: false,
                    accentColor: accentColor
                ) { commitUnassign() }
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
                            .fill(isValid ? accentColor : Mono.C.surfaceUp)
                            .overlay(
                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                    .strokeBorder(
                                        isValid ? .clear : Mono.C.border.opacity(0.5),
                                        lineWidth: 0.5
                                    )
                            )
                            .shadow(
                                color: (isValid && !isMonochrome) ? Mono.C.red.opacity(0.55) : .clear,
                                radius: 18, x: 0, y: 0
                            )
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
