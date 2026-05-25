import SwiftUI

struct GoalDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let itemID: UUID

    @State private var showAssign = false
    @State private var showUnassign = false
    @State private var showEdit = false
    @State private var appeared = false
    @State private var itemToDelete: SavingsItem?
    @State private var celebrateComplete = false
    @State private var showCompleteConfirm = false

    private var item: SavingsItem? {
        store.savingsItems.first { $0.id == itemID }
    }

    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()

            if let item {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: Mono.S.lg) {
                        Capsule()
                            .fill(Mono.C.borderBright)
                            .frame(width: 36, height: 4)
                            .padding(.top, 12)
                        
                        HStack {
                            Spacer()
                            HStack(spacing: 20) {
                                Button {
                                    var updated = item
                                    updated.isFavorite.toggle()
                                    store.updateSavingsItem(updated)
                                    Haptic.select()
                                } label: {
                                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(item.isFavorite ? Mono.C.text : Mono.C.textSec)
                                }
                                
                                Button {
                                    showEdit = true
                                    Haptic.light()
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Mono.C.textSec)
                                }
                                
                                Button {
                                    itemToDelete = item
                                    Haptic.medium()
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(Mono.C.red)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Mono.C.surfaceUp)
                                    .overlay(Capsule().strokeBorder(Mono.C.borderBright, lineWidth: 1))
                            )
                        }
                        .padding(.horizontal, Mono.S.md)
                        .padding(.top, 4)
                            
                        // Hero section
                        GoalDetailHero(item: item)
                            .padding(.horizontal, Mono.S.md)
                            .opacity(appeared ? 1 : 0)
                            .scaleEffect(appeared ? 1 : 0.93)
                        // Action button — full width
                        Group {
                            if item.isCompleted {
                                ActionButton(
                                    icon: "arrow.uturn.backward.circle.fill",
                                    label: "Mark as Active",
                                    filled: false,
                                    isAccent: false
                                ) {
                                    store.markGoalUncompleted(id: item.id)
                                    Haptic.success()
                                    dismiss()
                                }
                            } else if item.assignedAmount == 0 && !item.isFullyFunded {
                                ActionButton(
                                    icon: "arrow.right.circle.fill",
                                    label: "Assign Funds",
                                    filled: true,
                                    isAccent: true
                                ) {
                                    showAssign = true
                                    Haptic.medium()
                                }
                            } else {
                                HStack(spacing: Mono.S.md) {
                                    if item.assignedAmount > 0 {
                                        Button {
                                            showUnassign = true
                                            Haptic.medium()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.left.circle.fill")
                                                    .foregroundColor(Mono.C.negative)
                                                    .shadow(color: Mono.C.negative.opacity(0.8), radius: 8)
                                                Text("Unassign")
                                            }
                                            .font(Mono.T.mono(13, .semibold))
                                            .foregroundColor(Mono.C.text)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                                    .fill(Mono.C.surfaceUp)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                                            .strokeBorder(Mono.C.negative.opacity(0.5), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                    
                                    if !item.isFullyFunded {
                                        Button {
                                            showAssign = true
                                            Haptic.medium()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "arrow.right.circle.fill")
                                                    .foregroundColor(Mono.C.positive)
                                                    .shadow(color: Mono.C.positive.opacity(0.8), radius: 8)
                                                Text("Assign")
                                            }
                                            .font(Mono.T.mono(13, .semibold))
                                            .foregroundColor(Mono.C.text)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                                    .fill(Mono.C.surfaceUp)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                                            .strokeBorder(Mono.C.positive.opacity(0.5), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    } else {
                                        Button {
                                            showCompleteConfirm = true
                                            Haptic.medium()
                                        } label: {
                                            HStack(spacing: 6) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Mono.C.bg)
                                                Text("Complete")
                                            }
                                            .font(Mono.T.mono(13, .semibold))
                                            .foregroundColor(Mono.C.bg)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 14)
                                            .background(
                                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                                    .fill(Mono.C.text)
                                                    .shadow(color: .white.opacity(0.15), radius: 12)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, Mono.S.md)
                        .opacity(appeared ? 1 : 0)

                        // Stats grid
                        GoalStatsGrid(item: item)
                            .padding(.horizontal, Mono.S.md)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)

                        // Transaction history for this goal
                        if !store.transactionsForItem(itemID).isEmpty {
                            GoalTransactionHistory(itemID: itemID)
                                .padding(.horizontal, Mono.S.md)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 24)
                        }



                        Spacer(minLength: 100)
                    }
                    .padding(.top, Mono.S.sm)
                }

                // Celebration overlay
                if celebrateComplete {
                    CelebrationView()
                        .transition(.opacity)
                }

                if showAssign {
                    AssignFundsView(isPresented: $showAssign, item: item)
                        .transition(.opacity)
                        .zIndex(100)
                }
                
                if showUnassign {
                    UnassignFundsView(isPresented: $showUnassign, item: item)
                        .transition(.opacity)
                        .zIndex(100)
                }
            } else {
                Text("Goal not found")
                    .font(Mono.T.body)
                    .foregroundColor(Mono.C.textSec)
            }
        }

        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.3).delay(0.05)) {
                appeared = true
            }
        }
        .onChange(of: item?.isFullyFunded) { _, newVal in
            if newVal == true && item?.isCompleted == false {
                withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                    celebrateComplete = true
                }
                Haptic.success()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation { celebrateComplete = false }
                    showCompleteConfirm = true
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            if let item {
                CreateGoalView(editingItem: item)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(Mono.C.bg)
            }
        }
        .sheet(item: $itemToDelete) { snap in
            DeleteGoalConfirmSheet(item: snap)
                .presentationDetents([.fraction(0.65)])
                .presentationDragIndicator(.hidden)
                .presentationBackground {
                    Color(white: 0.035)
                }
                .presentationCornerRadius(20)
        }
        .sheet(isPresented: $showCompleteConfirm) {
            if let item {
                ConfirmCompleteSheet(item: item)
                    .presentationDetents([.fraction(0.55)])
                    .presentationDragIndicator(.hidden)
                    .presentationBackground {
                        Color(white: 0.035)
                    }
                    .presentationCornerRadius(20)
            }
        }
        .onChange(of: item?.id) { _, newID in
            if newID == nil { dismiss() }
        }
    }
}

// MARK: - Detail Hero

struct GoalDetailHero: View {
    let item: SavingsItem

    var body: some View {
        VStack(spacing: Mono.S.md) {
            // Icon + ring
            ZStack {
                ProgressRing(progress: item.progress, size: 100, lineWidth: 5)

                ZStack {
                    Circle()
                        .fill(item.isFullyFunded ? Mono.C.text : Mono.C.surfaceUp)
                        .frame(width: 74, height: 74)

                    Image(systemName: item.icon)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(item.isFullyFunded ? Mono.C.bg : Mono.C.textSec)
                }
            }
            .padding(.top, Mono.S.md)

            // Name
            Text(item.name)
                .font(Mono.T.mono(24, .bold))
                .foregroundColor(Mono.C.text)
                .multilineTextAlignment(.center)

            if !item.itemDescription.isEmpty {
                Text(item.itemDescription)
                    .font(Mono.T.mono(14, .regular))
                    .foregroundColor(Mono.C.textTert)
                    .multilineTextAlignment(.center)
            }

            // Amount progress
            VStack(spacing: Mono.S.sm) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(item.assignedAmount.indianFormatted)
                        .font(Mono.T.mono(34, .bold))
                        .foregroundColor(Mono.C.text)

                    Text("/ \(item.targetAmount.indianFormatted)")
                        .font(Mono.T.mono(16, .regular))
                        .foregroundColor(Mono.C.textTert)
                }

                MonoProgressBar(progress: item.progress, height: 6, showLabel: true)
                    .padding(.horizontal, Mono.S.xl)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.sm)
        }
        .frame(maxWidth: .infinity)
        .monoHeroCard()
    }
}

// MARK: - Stats Grid

struct GoalStatsGrid: View {
    let item: SavingsItem

    var body: some View {
        VStack(spacing: 1) {
            HStack(spacing: 1) {
                StatCell(label: "Remaining", value: item.remaining.indianFormattedCompact, icon: "arrow.up.right")
                    .frame(maxWidth: .infinity)
                Rectangle().fill(Mono.C.border).frame(width: 0.5)
                StatCell(label: "Progress", value: "\(Int(item.progress * 100))%", icon: "chart.bar")
                    .frame(maxWidth: .infinity)
            }

            MonoDivider()

            HStack(spacing: 1) {
                if let targetDate = item.targetDate {
                    StatCell(
                        label: "Target Date",
                        value: VaultDateFormatter.short.string(from: targetDate),
                        icon: "calendar"
                    )
                    .frame(maxWidth: .infinity)
                    Rectangle().fill(Mono.C.border).frame(width: 0.5)
                    StatCell(
                        label: "Time Left",
                        value: VaultDateFormatter.daysRemaining(targetDate),
                        icon: "clock"
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    StatCell(label: "Target Date", value: "Not set", icon: "calendar")
                        .frame(maxWidth: .infinity)
                    Rectangle().fill(Mono.C.border).frame(width: 0.5)
                    StatCell(label: "Created", value: VaultDateFormatter.short.string(from: item.createdAt), icon: "plus.circle")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .monoCard()
    }
}

struct StatCell: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Mono.C.textDim)
                OverlineLabel(text: label)
            }
            Text(value)
                .font(Mono.T.mono(18, .semibold))
                .foregroundColor(Mono.C.text)
        }
        .padding(Mono.S.md)
    }
}

// MARK: - Goal Transaction History

struct GoalTransactionHistory: View {
    @Environment(AppStore.self) private var store
    let itemID: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.md) {
            OverlineLabel(text: "Transactions", opacity: 0.45)
                .padding(.horizontal, 4)

            let transactions = store.transactionsForItem(itemID)
            VStack(spacing: 1) {
                ForEach(Array(transactions.prefix(5).enumerated()), id: \.element.id) { index, t in
                    TransactionRowView(transaction: t)
                        .padding(.horizontal, Mono.S.md)
                    if index < transactions.prefix(5).count - 1 {
                        MonoDivider().padding(.horizontal, Mono.S.lg)
                    }
                }
                
                if transactions.count > 5 {
                    MonoDivider().padding(.horizontal, Mono.S.lg)
                    NavigationLink(destination: GoalAllTransactionsView(itemID: itemID)) {
                        HStack {
                            Text("View All Transactions")
                                .font(Mono.T.mono(14, .semibold))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(Mono.C.text)
                        .padding(.horizontal, Mono.S.lg)
                        .padding(.vertical, 16)
                        .background(Color(white: 0.08))
                    }
                    .buttonStyle(.plain)
                }
            }
            .monoCard()
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let label: String
    var filled: Bool = false
    var isAccent: Bool = false
    let action: () -> Void

    @AppStorage("vault_monochrome") private var isMonochrome = false

    private var activeFill: Color {
        guard filled else { return Mono.C.surfaceUp }
        return (isAccent && !isMonochrome) ? Mono.C.accent : Mono.C.text
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(Mono.T.mono(14, .semibold))
            }
            .foregroundColor(filled ? Mono.C.bg : Mono.C.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                    .fill(activeFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .strokeBorder(filled ? .clear : Mono.C.border, lineWidth: 0.5)
                    )
                    .shadow(
                        color: (filled && isAccent && !isMonochrome) ? Mono.C.accent.opacity(0.5) : .clear,
                        radius: 14, x: 0, y: 0
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct DangerButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                Text(label)
                    .font(Mono.T.mono(13, .medium))
            }
            .foregroundColor(Mono.C.negative)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                    .fill(Mono.C.surfaceUp)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .strokeBorder(Mono.C.border.opacity(0.5), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Delete Goal Confirmation Sheet

struct DeleteGoalConfirmSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: SavingsItem

    @State private var confirmText = ""

    private var isConfirmed: Bool { confirmText == item.name }

    var body: some View {
        VStack(spacing: 0) {

            Capsule()
                .fill(Mono.C.borderBright)
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, Mono.S.md)

            HStack {
                Button("Cancel") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
                Spacer()
                Text("Delete Goal")
                    .font(Mono.T.mono(15, .semibold))
                    .foregroundColor(Mono.C.negative)
                Spacer()
                Text("Cancel").font(Mono.T.mono(14, .medium)).foregroundColor(.clear)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.lg)

            ZStack {
                RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                    .fill(Mono.C.negative.opacity(0.08))
                    .frame(width: 58, height: 58)
                Image(systemName: "trash.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(Mono.C.negative)
                    .shadow(color: Mono.C.negative.opacity(0.4), radius: 12)
            }
            .padding(.bottom, Mono.S.md)

            Text("This goal and all its fund assignments will be permanently deleted.")
                .font(Mono.T.mono(13, .regular))
                .foregroundColor(Mono.C.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Mono.S.xl)
                .padding(.bottom, Mono.S.xl)

            VStack(alignment: .leading, spacing: 6) {
                Text("Type \"\(item.name)\" to confirm")
                    .font(Mono.T.mono(11, .medium))
                    .foregroundColor(Mono.C.textDim)

                TextField("", text: $confirmText)
                    .font(Mono.T.mono(15, .regular))
                    .foregroundColor(isConfirmed ? Mono.C.negative : Mono.C.text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(Mono.S.md)
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .fill(Mono.C.surfaceUp)
                            .overlay(
                                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                                    .strokeBorder(
                                        isConfirmed ? Mono.C.negative.opacity(0.7) : Mono.C.border,
                                        lineWidth: isConfirmed ? 1.0 : 0.5
                                    )
                            )
                    )
                    .animation(.spring(duration: 0.25, bounce: 0.2), value: isConfirmed)
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.bottom, Mono.S.lg)

            Button {
                guard isConfirmed else { Haptic.error(); return }
                store.deleteSavingsItem(id: item.id)
                Haptic.success()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill").font(.system(size: 14))
                    Text("Delete Goal").font(Mono.T.mono(15, .semibold))
                }
                .foregroundColor(isConfirmed ? .white : Mono.C.textDim)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(isConfirmed ? Mono.C.negative : Mono.C.surfaceUp)
                        .shadow(color: Mono.C.negative.opacity(isConfirmed ? 0.3 : 0), radius: isConfirmed ? 16 : 0, y: isConfirmed ? 6 : 0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .strokeBorder(
                            isConfirmed ? .clear : Mono.C.border.opacity(0.5),
                            lineWidth: 0.5
                        )
                )
                .animation(.spring(duration: 0.3, bounce: 0.2), value: isConfirmed)
            }
            .buttonStyle(.plain)
            .disabled(!isConfirmed)
            .padding(.horizontal, Mono.S.md)
            .padding(.bottom, Mono.S.xl)
        }
    }
}

// MARK: - Celebration View

struct CelebrationView: View {
    @State private var particles: [ParticleData] = []
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var ringProgress: CGFloat = 0.0

    struct ParticleData: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: CGFloat
        var opacity: Double
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .environment(\.colorScheme, .dark)
            
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: Mono.S.xl) {
                ZStack {
                    ForEach(particles) { p in
                        Circle()
                            .fill(Mono.C.text.opacity(p.opacity))
                            .frame(width: p.size)
                            .offset(x: p.x, y: p.y)
                    }

                    ZStack {
                        Circle()
                            .stroke(Mono.C.text.opacity(0.15), lineWidth: 8)
                            .frame(width: 140, height: 140)
                        
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(Mono.C.text, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 52, weight: .bold))
                            .foregroundColor(Mono.C.text)
                            .shadow(color: .white.opacity(0.5), radius: 12)
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                }
                
                Text("GOAL FUNDED!")
                    .font(Mono.T.mono(24, .bold))
                    .foregroundColor(Mono.C.text)
                    .tracking(4)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                    .opacity(opacity)
                    .offset(y: opacity == 1 ? 0 : 20)
            }
        }
        .onAppear {
            particles = (0..<24).map { _ in
                ParticleData(
                    x: CGFloat.random(in: -140...140),
                    y: CGFloat.random(in: -140...140),
                    size: CGFloat.random(in: 4...14),
                    speed: CGFloat.random(in: 0.3...1.0),
                    opacity: Double.random(in: 0.4...1.0)
                )
            }
            withAnimation(.spring(duration: 0.6, bounce: 0.5)) {
                scale = 1.0
                opacity = 1.0
            }
            withAnimation(.linear(duration: 3.0)) {
                ringProgress = 1.0
            }
        }
    }
}

// MARK: - Confirm Complete Sheet

struct ConfirmCompleteSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    let item: SavingsItem

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {

            Capsule()
                .fill(Mono.C.borderBright)
                .frame(width: 36, height: 4)
                .padding(.top, 14)
                .padding(.bottom, Mono.S.lg)

            // Icon
            ZStack {
                Circle()
                    .fill(Mono.C.text)
                    .frame(width: 64, height: 64)

                Image(systemName: "checkmark")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Mono.C.bg)
            }
            .scaleEffect(appeared ? 1.0 : 0.5)
            .opacity(appeared ? 1 : 0)
            .padding(.bottom, Mono.S.md)

            Text("Goal Fully Funded!")
                .font(Mono.T.mono(20, .bold))
                .foregroundColor(Mono.C.text)
                .padding(.bottom, Mono.S.xs)

            Text(item.targetAmount.indianFormatted + " reached")
                .font(Mono.T.mono(14, .regular))
                .foregroundColor(Mono.C.textTert)
                .padding(.bottom, Mono.S.lg)

            Text("Mark this goal as completed?\nIt will move to your Completed tab.")
                .font(Mono.T.mono(13, .regular))
                .foregroundColor(Mono.C.textSec)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, Mono.S.xl)
                .padding(.bottom, Mono.S.xl)

            // Confirm button
            Button {
                store.markGoalCompleted(id: item.id)
                Haptic.success()
                dismiss()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                    Text("Mark Complete")
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
            .padding(.bottom, Mono.S.sm)

            // Keep Active button
            Button {
                dismiss()
            } label: {
                Text("Keep Active")
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Mono.S.md)
            .padding(.bottom, Mono.S.lg)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.4)) {
                appeared = true
            }
        }
    }
}

// MARK: - Goal All Transactions View

struct GoalAllTransactionsView: View {
    @Environment(AppStore.self) private var store
    let itemID: UUID
    
    var body: some View {
        ZStack {
            Mono.C.bg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 1) {
                    let transactions = store.transactionsForItem(itemID)
                    ForEach(Array(transactions.enumerated()), id: \.element.id) { index, t in
                        TransactionRowView(transaction: t)
                            .padding(.horizontal, Mono.S.md)
                        if index < transactions.count - 1 {
                            MonoDivider().padding(.horizontal, Mono.S.lg)
                        }
                    }
                }
                .monoCard()
                .padding(Mono.S.md)
            }
        }
        .navigationTitle("All Transactions")
        .navigationBarTitleDisplayMode(.inline)
    }
}
