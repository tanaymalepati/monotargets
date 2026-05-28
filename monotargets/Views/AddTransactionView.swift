import SwiftUI

// MARK: - Add Transaction Sheet

struct AddTransactionView: View {
    @Environment(AppStore.self) private var store
    @Binding var isPresented: Bool

    @AppStorage("vault_monochrome") private var isMonochrome = false

    @State private var digits                = ""
    @State private var type: Transaction.TransactionType = .inward
    @State private var selectedCategory:     Transaction.Category?       = nil
    @State private var note                  = ""
    @State private var payee                 = ""
    @State private var selectedPaymentMethod: Transaction.PaymentMethod? = nil
    @State private var tagsText              = ""
    @State private var isRecurring           = false
    @State private var recurringPeriod:      Transaction.RecurringPeriod? = nil
    @State private var showDetails           = false
    @State private var showSuccess           = false

    @State private var panelOffset:    CGFloat = 700
    @State private var backdropOpacity: Double = 0

    private var amount: Double { AmountFormatter.toDoubleFromDigits(digits) }
    private var isValid: Bool  { amount > 0 }

    private var parsedTags: [String] {
        tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(backdropOpacity)
                .ignoresSafeArea()
                .onTapGesture { hide() }

            // Bottom panel
            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(Mono.C.borderBright)
                    .frame(width: 36, height: 4)
                    .padding(.top, 12)
                    .padding(.bottom, 18)

                // Type selector
                HStack(spacing: 4) {
                    TypeTab(label: "Money In",  icon: "arrow.down.circle.fill", isActive: type == .inward)  {
                        withAnimation(.spring(duration: 0.28, bounce: 0.3)) { type = .inward }
                        Haptic.select()
                    }
                    TypeTab(label: "Money Out", icon: "arrow.up.circle.fill",   isActive: type == .outward) {
                        withAnimation(.spring(duration: 0.28, bounce: 0.3)) { type = .outward }
                        Haptic.select()
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button + 2, style: .continuous)
                        .fill(Mono.C.surfaceTop)
                        .overlay(RoundedRectangle(cornerRadius: Mono.R.button + 2, style: .continuous)
                            .strokeBorder(Mono.C.border.opacity(0.6), lineWidth: 0.5))
                )
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.lg)

                // Amount
                AmountInputField(digits: $digits, fontSize: 52)
                    .shadow(
                        color: (!isMonochrome && !digits.isEmpty) ? Mono.C.accent.opacity(0.45) : .clear,
                        radius: 16
                    )
                    .padding(.horizontal, Mono.S.xl)
                    .padding(.bottom, Mono.S.md)

                // Quick amounts
                HStack(spacing: 8) {
                    ForEach(quickAmounts, id: \.self) { amt in
                        QuickAmountPill(amount: amt) {
                            withAnimation(.spring(duration: 0.2, bounce: 0.4)) { digits = String(Int(amt)) }
                            Haptic.light()
                        }
                    }
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.sm)

                // Category
                let relevantCats: [Transaction.Category] = type == .inward
                    ? Transaction.Category.allCases.filter { $0.isIncome || $0 == .other }
                    : Transaction.Category.allCases.filter { !$0.isIncome }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(relevantCats) { cat in
                            TransactionCategoryChip(cat: cat, isSelected: selectedCategory == cat) {
                                withAnimation(.spring(duration: 0.2, bounce: 0.3)) {
                                    selectedCategory = (selectedCategory == cat) ? nil : cat
                                    if note.isEmpty { note = cat.label }
                                }
                                Haptic.select()
                            }
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.vertical, 2)
                }
                .padding(.bottom, Mono.S.sm)

                // Details expand toggle
                Button {
                    withAnimation(.spring(duration: 0.35, bounce: 0.3)) { showDetails.toggle() }
                    Haptic.light()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                        Text(showDetails ? "Hide Details" : "Add Details (payee, tags...)")
                            .font(Mono.T.mono(11, .medium))
                    }
                    .foregroundColor(Mono.C.textTert)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Mono.S.md)

                // Expandable details
                if showDetails {
                    VStack(spacing: 8) {
                        // Note field
                        MonoTextField(placeholder: "Note (optional)", text: $note, icon: "text.alignleft")

                        // Payee field
                        MonoTextField(placeholder: "Payee / Merchant", text: $payee, icon: "storefront")

                        // Payment method
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(Transaction.PaymentMethod.allCases) { pm in
                                    PaymentMethodChip(
                                        method: pm,
                                        isSelected: selectedPaymentMethod == pm
                                    ) {
                                        withAnimation(.spring(duration: 0.2, bounce: 0.3)) {
                                            selectedPaymentMethod = (selectedPaymentMethod == pm) ? nil : pm
                                        }
                                        Haptic.select()
                                    }
                                }
                            }
                            .padding(.horizontal, Mono.S.md)
                        }

                        // Tags
                        MonoTextField(placeholder: "Tags (comma-separated)", text: $tagsText, icon: "tag")

                        // Recurring toggle
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Mono.C.textTert)
                                .frame(width: 18)
                            Toggle("Recurring", isOn: $isRecurring.animation())
                                .font(Mono.T.mono(13, .regular))
                                .foregroundColor(Mono.C.textSec)
                                .tint(Mono.C.accent)
                        }
                        .padding(.horizontal, Mono.S.md)

                        if isRecurring {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(Transaction.RecurringPeriod.allCases) { period in
                                        RecurringPeriodChip(
                                            period: period,
                                            isSelected: recurringPeriod == period
                                        ) {
                                            withAnimation(.spring(duration: 0.2, bounce: 0.3)) {
                                                recurringPeriod = (recurringPeriod == period) ? nil : period
                                            }
                                            Haptic.select()
                                        }
                                    }
                                }
                                .padding(.horizontal, Mono.S.md)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

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
                    .shadow(color: .black.opacity(0.55), radius: 36, x: 0, y: -6)
                    .ignoresSafeArea(edges: .bottom)
            )
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
            withAnimation(.spring(duration: 0.42, bounce: 0.05)) {
                panelOffset = 0
                backdropOpacity = 0.65
            }
        }
        .onChange(of: type) { _, _ in
            withAnimation(.spring(duration: 0.2, bounce: 0.2)) {
                selectedCategory = nil
                note = ""
            }
        }
    }

    // MARK: - Helpers

    private var quickAmounts: [Double] {
        type == .inward ? [1_000, 5_000, 10_000, 50_000] : [500, 1_000, 2_000, 5_000]
    }

    private func commitTransaction() {
        guard isValid else { Haptic.error(); return }

        let finalNote = note.isEmpty ? (selectedCategory?.label ?? "") : note

        store.addTransaction(
            amount:          amount,
            type:            type,
            note:            finalNote,
            category:        selectedCategory,
            payee:           payee.isEmpty ? nil : payee,
            paymentMethod:   selectedPaymentMethod,
            tags:            parsedTags,
            isRecurring:     isRecurring,
            recurringPeriod: isRecurring ? recurringPeriod : nil
        )
        Haptic.success()
        withAnimation(.spring(duration: 0.4, bounce: 0.3)) { showSuccess = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { hide() }
    }

    private func hide() {
        withAnimation(.spring(duration: 0.34, bounce: 0.05)) {
            panelOffset = 700
            backdropOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.36) {
            isPresented = false
            digits = ""
            note   = ""
            payee  = ""
            tagsText = ""
            selectedCategory     = nil
            selectedPaymentMethod = nil
            isRecurring          = false
            recurringPeriod      = nil
            showDetails          = false
            showSuccess          = false
            panelOffset          = 700
            backdropOpacity      = 0
        }
    }
}

// MARK: - MonoTextField

struct MonoTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Mono.C.textTert)
                .frame(width: 18)
            TextField(placeholder, text: $text)
                .font(Mono.T.mono(13, .regular))
                .foregroundColor(Mono.C.text)
                .tint(Mono.C.accent)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, Mono.S.md)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                .fill(Mono.C.surfaceTop)
                .overlay(
                    RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                        .strokeBorder(Mono.C.border, lineWidth: 0.5)
                )
        )
        .padding(.horizontal, Mono.S.md)
    }
}

// MARK: - Payment Method Chip

struct PaymentMethodChip: View {
    let method: Transaction.PaymentMethod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: method.icon)
                    .font(.system(size: 11, weight: .medium))
                Text(method.label)
                    .font(Mono.T.mono(12, .medium))
            }
            .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Mono.C.text : Mono.C.surfaceTop)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(isSelected ? .clear : Mono.C.border, lineWidth: 0.5)
                    )
            )
            .animation(.spring(duration: 0.2, bounce: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recurring Period Chip

struct RecurringPeriodChip: View {
    let period: Transaction.RecurringPeriod
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: period.icon)
                    .font(.system(size: 10, weight: .medium))
                Text(period.label)
                    .font(Mono.T.mono(11, .medium))
            }
            .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Mono.C.accent : Mono.C.surfaceTop)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(isSelected ? .clear : Mono.C.border, lineWidth: 0.5)
                    )
            )
            .animation(.spring(duration: 0.2, bounce: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Views (kept from original)

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
                        .overlay(Capsule(style: .continuous).strokeBorder(Mono.C.border, lineWidth: 0.5))
                )
        }
        .buttonStyle(.plain)
    }
}

struct TransactionCategoryChip: View {
    let cat: Transaction.Category
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: cat.icon)
                    .font(.system(size: 11, weight: .medium))
                Text(cat.label)
                    .font(Mono.T.mono(12, .medium))
            }
            .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? Mono.C.text : Mono.C.surfaceTop)
                    .overlay(Capsule(style: .continuous).strokeBorder(isSelected ? .clear : Mono.C.border, lineWidth: 0.5))
            )
            .animation(.spring(duration: 0.2, bounce: 0.3), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

struct SuccessCheckmark: View {
    @State private var scale:   CGFloat = 0.3
    @State private var opacity: Double  = 0

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
                scale   = 1.0
                opacity = 1.0
            }
        }
    }
}
