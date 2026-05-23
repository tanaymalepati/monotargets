import SwiftUI

struct EditTransactionView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let transaction: Transaction

    @State private var digits: String = ""
    @State private var type: Transaction.TransactionType
    @State private var note: String
    @State private var showDeleteConfirm = false

    // Assign/unassign rows are system-managed — only the note is editable
    private var isSystemTransaction: Bool {
        transaction.type == .assign || transaction.type == .unassign
    }

    init(transaction: Transaction) {
        self.transaction = transaction
        _digits = State(initialValue: String(Int(transaction.amount)))
        _type   = State(initialValue: transaction.type)
        _note   = State(initialValue: transaction.note)
    }

    private var amount: Double { AmountFormatter.toDoubleFromDigits(digits) }
    private var isValid: Bool  { isSystemTransaction ? true : amount > 0 }

    var body: some View {
        NavigationStack {
            ZStack {
                Mono.C.bg.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: Mono.S.lg) {

                        // Amount (only editable for inward/outward)
                        if !isSystemTransaction {
                            VStack(spacing: Mono.S.md) {
                                // Type toggle
                                HStack(spacing: 0) {
                                    TypeTab(
                                        label: "Money In",
                                        icon: "arrow.down.circle.fill",
                                        isActive: type == .inward
                                    ) {
                                        withAnimation(.spring(duration: 0.25, bounce: 0.3)) { type = .inward }
                                        Haptic.select()
                                    }
                                    TypeTab(
                                        label: "Money Out",
                                        icon: "arrow.up.circle.fill",
                                        isActive: type == .outward
                                    ) {
                                        withAnimation(.spring(duration: 0.25, bounce: 0.3)) { type = .outward }
                                        Haptic.select()
                                    }
                                }
                                .padding(.horizontal, Mono.S.md)

                                AmountInputField(digits: $digits, placeholder: "0", fontSize: 44)
                                    .padding(.horizontal, Mono.S.xl)

                                MonoNumpad(digits: $digits)
                                    .padding(.horizontal, Mono.S.sm)
                            }
                        } else {
                            // System transaction — show read-only amount
                            VStack(spacing: 6) {
                                OverlineLabel(text: transaction.type.label)
                                HStack(spacing: 4) {
                                    Text(transaction.type.isDebit ? "-" : "+")
                                        .font(Mono.T.mono(28, .semibold))
                                        .foregroundColor(Mono.C.textTert)
                                    Text(transaction.amount.indianFormatted)
                                        .font(Mono.T.mono(34, .bold))
                                        .foregroundColor(Mono.C.text)
                                }
                                Text("This transaction is managed automatically")
                                    .font(Mono.T.caption)
                                    .foregroundColor(Mono.C.textDim)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Mono.S.lg)
                            .monoCard()
                            .padding(.horizontal, Mono.S.md)
                        }

                        // Note field — always editable
                        FormField(label: "Note") {
                            TextField("Add a note…", text: $note)
                                .font(Mono.T.body)
                                .foregroundColor(Mono.C.text)
                        }
                        .padding(.horizontal, Mono.S.md)

                        // Date (read-only)
                        VStack(alignment: .leading, spacing: 8) {
                            OverlineLabel(text: "Date")
                                .padding(.horizontal, 4)
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Mono.C.textTert)
                                Text(VaultDateFormatter.full.string(from: transaction.date))
                                    .font(Mono.T.mono(14, .regular))
                                    .foregroundColor(Mono.C.textSec)
                            }
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
                        .padding(.horizontal, Mono.S.md)

                        // Save button
                        Button(action: saveChanges) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 15))
                                Text("Save Changes")
                                    .font(Mono.T.mono(15, .semibold))
                            }
                            .foregroundColor(isValid ? Mono.C.bg : Mono.C.textDim)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                    .fill(isValid ? Mono.C.text : Mono.C.surfaceUp)
                            )
                            .padding(.horizontal, Mono.S.md)
                            .animation(.spring(duration: 0.25, bounce: 0.2), value: isValid)
                        }
                        .disabled(!isValid)
                        .buttonStyle(.plain)

                        // Delete button
                        DangerButton(icon: "trash", label: "Delete Transaction") {
                            showDeleteConfirm = true
                        }
                        .padding(.horizontal, Mono.S.md)
                        .padding(.bottom, Mono.S.xl)
                    }
                    .padding(.top, Mono.S.md)
                }
            }
            .navigationTitle("Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .font(Mono.T.body)
                        .foregroundColor(Mono.C.textSec)
                }
            }
            .confirmationDialog(
                "Delete this transaction?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    store.deleteTransaction(id: transaction.id)
                    Haptic.medium()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func saveChanges() {
        guard isValid else { return }
        Haptic.success()

        if let idx = store.transactions.firstIndex(where: { $0.id == transaction.id }) {
            if !isSystemTransaction {
                store.transactions[idx].amount = amount
                store.transactions[idx].type   = type
            }
            store.transactions[idx].note = note
            store.save()
        }
        dismiss()
    }
}
