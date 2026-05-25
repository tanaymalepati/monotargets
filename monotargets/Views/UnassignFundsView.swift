import SwiftUI

struct UnassignFundsView: View {
    @Environment(AppStore.self) private var store

    @Binding var isPresented: Bool

    let item: SavingsItem

    @AppStorage("vault_monochrome") private var isMonochrome = false

    @State private var digits = ""
    @State private var showSuccess = false
    @State private var panelOffset: CGFloat = 700
    @State private var backdropOpacity: Double = 0

    private var amount: Double { AmountFormatter.toDoubleFromDigits(digits) }
    private var isValid: Bool  { amount > 0 && amount <= item.assignedAmount }
    private var overflows: Bool { amount > item.assignedAmount }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(backdropOpacity)
                .ignoresSafeArea()
                .onTapGesture { hide() }

            VStack(spacing: 0) {

                // ── Drag handle
                Capsule()
                    .fill(Mono.C.borderBright)
                    .frame(width: 36, height: 4)
                    .padding(.top, 14)
                    .padding(.bottom, Mono.S.md)

                // ── Header row
                HStack {
                    Button("Cancel") { hide() }
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

                    ZStack {
                        ProgressRing(progress: item.progress, size: 42, lineWidth: 3)
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
                            .fill(isValid ? Mono.C.red : Mono.C.surfaceUp)
                            .shadow(color: Mono.C.red.opacity(0.3), radius: isValid ? 12 : 0, y: isValid ? 4 : 0)
                    )
                    .animation(.spring(duration: 0.25, bounce: 0.2), value: isValid)
                }
                .disabled(!isValid)
                .buttonStyle(.plain)
                .padding(.horizontal, Mono.S.md)
                .padding(.top, Mono.S.sm)
                .padding(.bottom, Mono.S.lg)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Mono.C.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Mono.C.borderBright.opacity(0.35), lineWidth: 0.5)
                    )
                    .shadow(color: .white.opacity(0.15), radius: 30, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.55), radius: 36, x: 0, y: 10)
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .frame(maxHeight: .infinity, alignment: .bottom)
            .offset(y: panelOffset)
            .gesture(
                DragGesture(minimumDistance: 16)
                    .onChanged { value in
                        guard value.translation.height > 0 else { return }
                        panelOffset = value.translation.height
                        backdropOpacity = max(0, 0.65 * (1 - value.translation.height / 320))
                    }
                    .onEnded { value in
                        let dy = value.translation.height
                        let velocity = value.predictedEndTranslation.height
                        if dy > 90 || velocity > 280 {
                            hide()
                        } else {
                            withAnimation(.spring(duration: 0.38, bounce: 0.38)) {
                                panelOffset = 0
                                backdropOpacity = 0.65
                            }
                        }
                    }
            )

            if showSuccess {
                SuccessCheckmark()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.15)) {
                panelOffset = 0
                backdropOpacity = 0.65
            }
        }
        .animation(.spring(duration: 0.25, bounce: 0.2), value: overflows)
    }

    private func hide() {
        withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
            panelOffset = 700
            backdropOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            isPresented = false
            digits = ""
            showSuccess = false
            panelOffset = 700
            backdropOpacity = 0
        }
    }

    private func commitUnassign() {
        guard isValid else { Haptic.error(); return }
        store.unassignFunds(from: item.id, amount: amount)
        Haptic.success()
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { hide() }
    }
}
