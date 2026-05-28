import SwiftUI

// MARK: - Custom Categories View

struct CustomCategoriesView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: CategoryTab = .expense
    @State private var showAddForm = false

    enum CategoryTab { case expense, income }

    private var expenseCategories: [CustomCategory] {
        store.customCategories.filter { !$0.isIncome }
    }

    private var incomeCategories: [CustomCategory] {
        store.customCategories.filter { $0.isIncome }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle
            Capsule()
                .fill(Mono.C.borderBright)
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, Mono.S.sm)

            // Header
            HStack {
                Button("Done") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
                Spacer()
                Text("Custom Categories")
                    .font(Mono.T.mono(15, .semibold))
                    .foregroundColor(Mono.C.text)
                Spacer()
                Text("Done")
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.md)

            MonoDivider()
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.sm)

            // Tab switcher
            HStack(spacing: 4) {
                CategoryTabPill(label: "Expense", isSelected: selectedTab == .expense) {
                    withAnimation(.spring(duration: 0.22, bounce: 0.3)) { selectedTab = .expense }
                    Haptic.select()
                }
                CategoryTabPill(label: "Income", isSelected: selectedTab == .income) {
                    withAnimation(.spring(duration: 0.22, bounce: 0.3)) { selectedTab = .income }
                    Haptic.select()
                }
            }
            .padding(3)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Mono.C.surfaceTop))
            .padding(.horizontal, Mono.S.md)
            .padding(.bottom, Mono.S.sm)

            // Category list
            let displayedCategories = selectedTab == .expense ? expenseCategories : incomeCategories

            if displayedCategories.isEmpty {
                Spacer()
                VStack(spacing: Mono.S.sm) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 32, weight: .light))
                        .foregroundColor(Mono.C.textDim)
                    Text("No custom \(selectedTab == .expense ? "expense" : "income") categories")
                        .font(Mono.T.mono(14, .medium))
                        .foregroundColor(Mono.C.textSec)
                    Text("Tap \"Add Category\" below to create one")
                        .font(Mono.T.mono(11, .regular))
                        .foregroundColor(Mono.C.textDim)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, Mono.S.xl)
                Spacer()
            } else {
                List {
                    ForEach(displayedCategories) { cat in
                        HStack(spacing: Mono.S.md) {
                            ZStack {
                                RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                    .fill(Mono.C.surfaceTop)
                                    .frame(width: 38, height: 38)
                                Image(systemName: cat.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Mono.C.textSec)
                            }
                            Text(cat.name)
                                .font(Mono.T.mono(15, .medium))
                                .foregroundColor(Mono.C.text)
                            Spacer()
                        }
                        .listRowBackground(Mono.C.surface)
                        .listRowInsets(EdgeInsets(top: 6, leading: Mono.S.md, bottom: 6, trailing: Mono.S.md))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation { store.deleteCustomCategory(id: cat.id) }
                                Haptic.medium()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Mono.C.bg)
            }

            Spacer(minLength: 0)

            // Add Category button
            Button {
                withAnimation(.spring(duration: 0.35, bounce: 0.3)) { showAddForm = true }
                Haptic.medium()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Add Category")
                        .font(Mono.T.mono(15, .semibold))
                }
                .foregroundColor(Mono.C.bg)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(Mono.C.text)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Mono.S.md)
            .padding(.bottom, Mono.S.lg)
        }
        .background(Mono.C.bg.ignoresSafeArea())
        .sheet(isPresented: $showAddForm) {
            AddCustomCategoryForm(defaultIsIncome: selectedTab == .income)
                .presentationDetents([.fraction(0.78)])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Mono.C.bg)
                .presentationCornerRadius(24)
        }
    }
}

// MARK: - Tab Pill

private struct CategoryTabPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(Mono.T.mono(13, .semibold))
                .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isSelected ? Mono.C.text : .clear)
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.22, bounce: 0.3), value: isSelected)
    }
}

// MARK: - Add Custom Category Form

struct AddCustomCategoryForm: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let defaultIsIncome: Bool

    @State private var name = ""
    @State private var selectedIcon = "star.fill"
    @State private var isIncome: Bool

    init(defaultIsIncome: Bool) {
        self.defaultIsIncome = defaultIsIncome
        _isIncome = State(initialValue: defaultIsIncome)
    }

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 6)

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Mono.C.borderBright)
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, Mono.S.sm)

            // Header
            HStack {
                Button("Cancel") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
                Spacer()
                Text("New Category")
                    .font(Mono.T.mono(15, .semibold))
                    .foregroundColor(Mono.C.text)
                Spacer()
                Text("Cancel").font(Mono.T.mono(14, .medium)).foregroundColor(.clear)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.md)

            MonoDivider().padding(.horizontal, Mono.S.md).padding(.bottom, Mono.S.md)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: Mono.S.lg) {

                    // Name field
                    VStack(alignment: .leading, spacing: 6) {
                        OverlineLabel(text: "Category Name")
                            .padding(.horizontal, 4)
                        HStack(spacing: 10) {
                            Image(systemName: selectedIcon)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Mono.C.accent)
                                .frame(width: 22)
                            TextField("e.g. Coffee, Subscriptions…", text: $name)
                                .font(Mono.T.mono(15, .regular))
                                .foregroundColor(Mono.C.text)
                                .tint(Mono.C.accent)
                                .autocorrectionDisabled()
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
                    .padding(.horizontal, Mono.S.md)

                    // Income/Expense toggle
                    VStack(alignment: .leading, spacing: 6) {
                        OverlineLabel(text: "Type")
                            .padding(.horizontal, Mono.S.md + 4)
                        HStack(spacing: 4) {
                            TypeTogglePill(label: "Expense", icon: "arrow.up.circle.fill", isSelected: !isIncome) {
                                withAnimation(.spring(duration: 0.22, bounce: 0.3)) { isIncome = false }
                                Haptic.select()
                            }
                            TypeTogglePill(label: "Income", icon: "arrow.down.circle.fill", isSelected: isIncome) {
                                withAnimation(.spring(duration: 0.22, bounce: 0.3)) { isIncome = true }
                                Haptic.select()
                            }
                        }
                        .padding(3)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Mono.C.surfaceTop))
                        .padding(.horizontal, Mono.S.md)
                    }

                    // Icon picker
                    VStack(alignment: .leading, spacing: 10) {
                        OverlineLabel(text: "Icon")
                            .padding(.horizontal, Mono.S.md + 4)
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(CustomCategory.suggestedIcons, id: \.self) { sym in
                                Button {
                                    withAnimation(.spring(duration: 0.18, bounce: 0.4)) { selectedIcon = sym }
                                    Haptic.select()
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                            .fill(selectedIcon == sym ? Mono.C.text : Mono.C.surfaceUp)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: Mono.R.small, style: .continuous)
                                                    .strokeBorder(selectedIcon == sym ? .clear : Mono.C.border, lineWidth: 0.5)
                                            )
                                        Image(systemName: sym)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(selectedIcon == sym ? Mono.C.bg : Mono.C.textSec)
                                    }
                                    .frame(height: 44)
                                }
                                .buttonStyle(.plain)
                                .animation(.spring(duration: 0.18, bounce: 0.4), value: selectedIcon == sym)
                            }
                        }
                        .padding(.horizontal, Mono.S.md)
                    }

                    // Save button
                    Button {
                        guard isValid else { Haptic.error(); return }
                        let newCat = CustomCategory(
                            name: name.trimmingCharacters(in: .whitespaces),
                            icon: selectedIcon,
                            isIncome: isIncome
                        )
                        store.addCustomCategory(newCat)
                        Haptic.success()
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .semibold))
                            Text("Save Category")
                                .font(Mono.T.mono(15, .semibold))
                        }
                        .foregroundColor(isValid ? Mono.C.bg : Mono.C.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                .fill(isValid ? Mono.C.text : Mono.C.surfaceUp)
                        )
                        .animation(.spring(duration: 0.3, bounce: 0.2), value: isValid)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValid)
                    .padding(.horizontal, Mono.S.md)
                    .padding(.bottom, Mono.S.xl)
                }
                .padding(.top, Mono.S.sm)
            }
        }
    }
}

// MARK: - Type Toggle Pill

private struct TypeTogglePill: View {
    let label: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(label)
                    .font(Mono.T.mono(13, .semibold))
            }
            .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Mono.C.text : .clear)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.22, bounce: 0.3), value: isSelected)
    }
}
