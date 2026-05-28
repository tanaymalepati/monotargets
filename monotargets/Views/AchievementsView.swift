import SwiftUI

// MARK: - Achievements View (cabinet sheet)

struct AchievementsView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: Achievement.AchievementCategory? = nil

    private var filtered: [Achievement] {
        guard let cat = selectedCategory else { return Achievement.all }
        return Achievement.all.filter { $0.category == cat }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                Rectangle()
                    .fill(LinearGradient(colors: [Color.white.opacity(0.10), .clear], startPoint: .top, endPoint: .bottom))
                    .frame(height: 1)

                Capsule()
                    .fill(Color(white: 0.40))
                    .frame(width: 44, height: 6)
                    .padding(.top, 14)
                    .padding(.bottom, 16)

                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Achievement Cabinet")
                            .font(Mono.T.mono(17, .bold))
                            .foregroundColor(Mono.C.text)
                        Text("\(store.earnedAchievements.count) of \(Achievement.all.count) unlocked · \(store.totalXP) XP")
                            .font(Mono.T.mono(11, .regular))
                            .foregroundColor(Mono.C.textTert)
                    }
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(Mono.T.mono(14, .medium))
                        .foregroundColor(Mono.C.textSec)
                }
                .padding(.horizontal, Mono.S.lg)
                .padding(.bottom, Mono.S.md)

                // Level + XP bar
                VStack(spacing: 8) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(Mono.C.accent)
                            Text("Level \(store.currentLevel.number) · \(store.currentLevel.title)")
                                .font(Mono.T.mono(12, .semibold))
                                .foregroundColor(Mono.C.text)
                        }
                        Spacer()
                        if let next = store.nextLevel {
                            Text("\(store.totalXP) / \(next.minXP) XP")
                                .font(Mono.T.mono(10, .regular))
                                .foregroundColor(Mono.C.textTert)
                        } else {
                            Text("\(store.totalXP) XP · MAX")
                                .font(Mono.T.mono(10, .medium))
                                .foregroundColor(Mono.C.accent)
                        }
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3).fill(Mono.C.surfaceTop).frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    LinearGradient(colors: [Mono.C.accent, Mono.C.accent.opacity(0.6)],
                                                   startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: geo.size.width * store.levelProgress, height: 6)
                                .animation(.spring(duration: 0.8, bounce: 0.2), value: store.levelProgress)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, Mono.S.lg)
                .padding(.bottom, Mono.S.md)
            }

            MonoDivider()

            // Category filter pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterPill(label: "All", isSelected: selectedCategory == nil) {
                        withAnimation(.spring(duration: 0.25)) { selectedCategory = nil }
                    }
                    ForEach(Achievement.AchievementCategory.allCases, id: \.self) { cat in
                        FilterPill(label: cat.rawValue, isSelected: selectedCategory == cat) {
                            withAnimation(.spring(duration: 0.25)) {
                                selectedCategory = selectedCategory == cat ? nil : cat
                            }
                        }
                    }
                }
                .padding(.horizontal, Mono.S.lg)
                .padding(.vertical, Mono.S.md)
            }

            // Badge grid
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 20) {
                    ForEach(filtered) { ach in
                        let earned = store.earnedAchievements.contains(ach.id)
                        AchievementBadge(achievement: ach, isEarned: earned, size: .medium)
                            .onTapGesture {
                                Haptic.light()
                            }
                    }
                }
                .padding(.horizontal, Mono.S.lg)
                .padding(.top, Mono.S.sm)
                .padding(.bottom, Mono.S.xxl)
            }
        }
        .background(Mono.C.bg.ignoresSafeArea())
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
            Haptic.light()
        }) {
            Text(label)
                .font(Mono.T.mono(12, .semibold))
                .foregroundColor(isSelected ? Mono.C.bg : Mono.C.textSec)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Mono.C.text : Mono.C.surfaceUp)
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(isSelected ? .clear : Mono.C.border, lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.2, bounce: 0.3), value: isSelected)
    }
}
