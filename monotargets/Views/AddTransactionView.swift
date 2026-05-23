import SwiftUI

// MARK: - Pull-down Add Transaction Panel

struct AddTransactionView: View {
    @Environment(AppStore.self) private var store
    @Binding var isPresented: Bool

    @State private var digits = ""
    @State private var type: Transaction.TransactionType = .inward
    @State private var note = ""
    @State private var showSuccess = false

    private var amount: Double { AmountFormatter.toDoubleFromDigits(digits) }
    private var isValid: Bool { amount > 0 }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Mono.C.borderBright)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // Type selector
                HStack(spacing: 0) {
                    TypeTab(label: "Money In", icon: "arrow.down.circle.fill", isActive: type == .inward) {
                        withAnimation(.spring(duration: 0.25, bounce: 0.3)) { type = .inward }
                        Haptic.select()
                    }
                    TypeTab(label: "Money Out", icon: "arrow.up.circle.fill", isActive: type == .outward) {
                        withAnimation(.spring(duration: 0.25, bounce: 0.3)) { type = .outward }
                        Haptic.select()
                    }
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.xl)

                // Amount display
                AmountInputField(digits: $digits, fontSize: 52)
                    .padding(.horizontal, Mono.S.xl)
                    .padding(.bottom, Mono.S.lg)

                // Quick amounts
                HStack(spacing: 8) {
                    ForEach(quickAmounts, id: \.self) { amount in
                        QuickAmountPill(amount: amount) {
                            withAnimation(.spring(duration: 0.2, bounce: 0.4)) {
                                digits = String(Int(amount))
                            }
                            Haptic.light()
                        }
                    }
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.md)

                // Note field
                HStack(spacing: 10) {
                    Image(systemName: "text.alignleft")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Mono.C.textTert)

                    TextField("Add a note…", text: $note)
                        .font(Mono.T.body)
                        .foregroundColor(Mono.C.text)
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(Mono.C.surfaceUp)
                        .overlay(
                            RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                .strokeBorder(Mono.C.border, lineWidth: 0.5)
                        )
                )
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.md)

                // Numpad
                MonoNumpad(digits: $digits) {
                    commitTransaction()
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.md)
            }
            .background(
                RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                    .fill(Mono.C.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                            .strokeBorder(Mono.C.borderBright.opacity(0.4), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.7), radius: 40, x: 0, y: -8)
                    .ignoresSafeArea(edges: .bottom)
            )
            .frame(maxWidth: .infinity)
            .frame(maxHeight: .infinity, alignment: .bottom)

            // Success flash
            if showSuccess {
                SuccessCheckmark()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
    }

    private var quickAmounts: [Double] {
        type == .inward
            ? [1000, 5000, 10000, 50000]
            : [500, 1000, 2000, 5000]
    }

    private func commitTransaction() {
        guard isValid else {
            Haptic.error()
            return
        }
        store.addTransaction(amount: amount, type: type, note: note)
        Haptic.success()
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
            showSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            dismissWithAnimation()
        }
    }

    private func dismissWithAnimation() {
        withAnimation(.spring(duration: 0.4, bounce: 0.1)) {
            isPresented = false
        }
        digits = ""
        note = ""
        showSuccess = false
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
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                    .fill(isActive ? Mono.C.text : .clear)
            )
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
