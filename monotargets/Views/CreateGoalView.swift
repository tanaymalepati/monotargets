import SwiftUI

struct CreateGoalView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var editingItem: SavingsItem? = nil

    @State private var name = ""
    @State private var description = ""
    @State private var icon = "target"
    @State private var targetDigits = ""
    @State private var hasTargetDate = false
    @State private var targetDate = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()

    @State private var focusedField: Field? = .name
    @State private var nameScale: CGFloat = 1.0

    enum Field { case name, description }

    private var targetAmount: Double { AmountFormatter.toDoubleFromDigits(targetDigits) }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && targetAmount > 0 }
    private var isEditing: Bool { editingItem != nil }

    var body: some View {
        NavigationStack {
            ZStack {
                Mono.C.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Mono.S.lg) {

                        // Icon + Name header
                        VStack(spacing: Mono.S.lg) {
                            IconSelectButton(icon: $icon)

                            // Name field
                            VStack(alignment: .leading, spacing: 6) {
                                OverlineLabel(text: "Goal Name")
                                TextField("e.g. MacBook Pro, Europe Trip…", text: $name)
                                    .font(Mono.T.mono(17, .semibold))
                                    .foregroundColor(Mono.C.text)
                                    .multilineTextAlignment(.center)
                                    .onChange(of: name) { _, _ in
                                        withAnimation(.spring(duration: 0.15, bounce: 0.6)) {
                                            nameScale = 1.04
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                            withAnimation(.spring(duration: 0.2, bounce: 0.3)) {
                                                nameScale = 1.0
                                            }
                                        }
                                    }
                            }
                            .padding(.horizontal, Mono.S.lg)
                            .scaleEffect(nameScale)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Mono.S.lg)
                        .monoHeroCard()
                        .padding(.horizontal, Mono.S.md)

                        // Description
                        FormField(label: "Description (Optional)") {
                            TextField("What are you saving for?", text: $description, axis: .vertical)
                                .font(Mono.T.body)
                                .foregroundColor(Mono.C.text)
                                .lineLimit(3)
                        }
                        .padding(.horizontal, Mono.S.md)

                        // Target Amount
                        VStack(alignment: .leading, spacing: Mono.S.md) {
                            OverlineLabel(text: "Target Amount")
                                .padding(.horizontal, 4)

                            AmountInputField(digits: $targetDigits, placeholder: "0", fontSize: 44)
                                .padding(.horizontal, Mono.S.xl)
                                .padding(.bottom, Mono.S.sm)

                            // Quick target amounts
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(quickTargets, id: \.self) { amount in
                                        QuickAmountPill(amount: Double(amount)) {
                                            withAnimation(.spring(duration: 0.2, bounce: 0.4)) {
                                                targetDigits = String(amount)
                                            }
                                            Haptic.light()
                                        }
                                    }
                                }
                                .padding(.horizontal, Mono.S.lg)
                            }

                            MonoNumpad(digits: $targetDigits)
                                .padding(.horizontal, Mono.S.sm)
                        }
                        .padding(.horizontal, Mono.S.md)

                        // Target Date toggle
                        VStack(spacing: Mono.S.sm) {
                            FormToggle(
                                label: "Set Target Date",
                                icon: "calendar",
                                isOn: $hasTargetDate
                            )
                            .padding(.horizontal, Mono.S.md)

                            if hasTargetDate {
                                DatePicker(
                                    "Target Date",
                                    selection: $targetDate,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .colorScheme(.dark)
                                .tint(Mono.C.text)
                                .padding(.horizontal, Mono.S.md)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .animation(.spring(duration: 0.35, bounce: 0.25), value: hasTargetDate)

                        // Save button
                        Button(action: saveGoal) {
                            HStack(spacing: 8) {
                                Image(systemName: isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text(isEditing ? "Save Changes" : "Create Goal")
                                    .font(Mono.T.mono(16, .semibold))
                            }
                            .foregroundColor(isValid ? Mono.C.bg : Mono.C.textDim)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                    .fill(isValid ? Mono.C.text : Mono.C.surfaceUp)
                                    .shadow(
                                        color: isValid ? .white.opacity(0.1) : .clear,
                                        radius: 12
                                    )
                            )
                            .padding(.horizontal, Mono.S.md)
                            .animation(.spring(duration: 0.3, bounce: 0.2), value: isValid)
                        }
                        .disabled(!isValid)
                        .buttonStyle(.plain)

                        Spacer(minLength: 60)
                    }
                    .padding(.top, Mono.S.md)
                }
            }
            .navigationTitle(isEditing ? "Edit Goal" : "New Goal")
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
        .onAppear {
            if let item = editingItem {
                name         = item.name
                description  = item.itemDescription
                icon         = item.icon
                targetDigits = String(Int(item.targetAmount))
                hasTargetDate = item.targetDate != nil
                targetDate   = item.targetDate ?? Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
            }
        }
    }

    private let quickTargets = [5000, 10000, 25000, 50000, 100000, 250000]

    private func saveGoal() {
        guard isValid else { return }
        Haptic.success()

        if var existing = editingItem {
            existing.name            = name.trimmingCharacters(in: .whitespaces)
            existing.itemDescription = description
            existing.icon            = icon
            existing.targetAmount    = targetAmount
            existing.targetDate      = hasTargetDate ? targetDate : nil
            store.updateSavingsItem(existing)
        } else {
            let item = SavingsItem(
                name: name.trimmingCharacters(in: .whitespaces),
                itemDescription: description,
                icon: icon,
                targetAmount: targetAmount,
                targetDate: hasTargetDate ? targetDate : nil
            )
            store.createSavingsItem(item)
        }
        dismiss()
    }
}

// MARK: - Form Components

struct FormField<Content: View>: View {
    let label: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            OverlineLabel(text: label)
                .padding(.horizontal, 4)

            content
                .padding(Mono.S.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(Mono.C.surfaceUp)
                        .overlay(
                            RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                .strokeBorder(Mono.C.border, lineWidth: 0.5)
                        )
                )
        }
    }
}

struct FormToggle: View {
    let label: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Mono.S.md) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Mono.C.textSec)
                .frame(width: 22)

            Text(label)
                .font(Mono.T.mono(15, .medium))
                .foregroundColor(Mono.C.text)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Mono.C.text)
                .labelsHidden()
        }
        .padding(Mono.S.md)
        .background(
            RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                .fill(Mono.C.surfaceUp)
                .overlay(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .strokeBorder(Mono.C.border, lineWidth: 0.5)
                )
        )
    }
}
