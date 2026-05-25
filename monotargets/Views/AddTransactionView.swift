import SwiftUI

// MARK: - Add Transaction Sheet

struct AddTransactionView: View {
    @Environment(AppStore.self) private var store
    @Binding var isPresented: Bool

    @AppStorage("vault_monochrome") private var isMonochrome = false

    @State private var digits = ""
    @State private var type: Transaction.TransactionType = .inward
    @State private var showSuccess = false

    // Explicit state instead of a boolean so drag can push them live
    @State private var panelOffset: CGFloat = 700
    @State private var backdropOpacity: Double = 0

    private var amount: Double { AmountFormatter.toDoubleFromDigits(digits) }
    private var isValid: Bool { amount > 0 }

    var body: some View {
        ZStack {

            // ── Backdrop: fades independently from the panel
            Color.black.opacity(backdropOpacity)
                .ignoresSafeArea()
                .onTapGesture { hide() }

            // ── Bottom panel
            VStack(spacing: 0) {

                // Drag handle
                Capsule()
                    .fill(Mono.C.borderBright)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 18)

                // Type selector — segmented pill
                HStack(spacing: 4) {
                    TypeTab(
                        label: "Money In",
                        icon: "arrow.down.circle.fill",
                        isActive: type == .inward
                    ) {
                        withAnimation(.spring(duration: 0.28, bounce: 0.3)) { type = .inward }
                        Haptic.select()
                    }
                    TypeTab(
                        label: "Money Out",
                        icon: "arrow.up.circle.fill",
                        isActive: type == .outward
                    ) {
                        withAnimation(.spring(duration: 0.28, bounce: 0.3)) { type = .outward }
                        Haptic.select()
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button + 2, style: .continuous)
                        .fill(Mono.C.surfaceTop)
                        .overlay(
                            RoundedRectangle(cornerRadius: Mono.R.button + 2, style: .continuous)
                                .strokeBorder(Mono.C.border.opacity(0.6), lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.lg)

                // Amount display
                AmountInputField(digits: $digits, fontSize: 52)
                    .padding(.horizontal, Mono.S.xl)
                    .padding(.bottom, Mono.S.md)

                // Quick amounts
                HStack(spacing: 8) {
                    ForEach(quickAmounts, id: \.self) { amt in
                        QuickAmountPill(amount: amt) {
                            withAnimation(.spring(duration: 0.2, bounce: 0.4)) {
                                digits = String(Int(amt))
                            }
                            Haptic.light()
                        }
                    }
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.md)

                // Numpad
                MonoNumpad(digits: $digits) { commitTransaction() }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.bottom, Mono.S.md)
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
            // Swipe-down to dismiss
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

            // ── Success flash (centered over everything)
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
    }

    // MARK: - Helpers

    private var quickAmounts: [Double] {
        type == .inward ? [1_000, 5_000, 10_000, 50_000] : [500, 1_000, 2_000, 5_000]
    }

    private func commitTransaction() {
        guard isValid else { Haptic.error(); return }
        store.addTransaction(amount: amount, type: type, note: "")
        Haptic.success()
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { hide() }
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
}

// MARK: - Supporting Views

struct TypeTab: View {
    let label: String
    let icon: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                Text(label)
                    .font(Mono.T.mono(13, .semibold))
            }
            .foregroundColor(isActive ? Mono.C.bg : Mono.C.textSec)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                    .fill(isActive ? Mono.C.text : Color.clear)
                    .shadow(color: isActive ? .black.opacity(0.25) : .clear, radius: 4, y: 2)
            )
            .animation(.spring(duration: 0.28, bounce: 0.3), value: isActive)
        }
        .buttonStyle(.plain)
    }
}

struct QuickAmountPill: View {
    let amount: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(amount.indianFormattedCompact)
                .font(Mono.T.mono(12, .medium))
                .foregroundColor(Mono.C.textSec)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(Mono.C.surfaceTop)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(Mono.C.border, lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

struct SuccessCheckmark: View {
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .fill(Mono.C.text.opacity(0.12))
                .frame(width: 100, height: 100)
                .scaleEffect(scale * 1.4)
                .opacity(opacity * 0.5)

            ZStack {
                Circle()
                    .fill(Mono.C.text)
                    .frame(width: 72, height: 72)
                    .shadow(color: .white.opacity(0.2), radius: 20)

                Image(systemName: "checkmark")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Mono.C.bg)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.4, bounce: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
