import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    @State private var heroScale: CGFloat = 0.88
    @State private var heroOpacity: Double = 0
    @State private var cardsOffset: CGFloat = 28
    @State private var selectedGoal: SavingsItem?
    @State private var showAchievements = false
    @State private var showChallenges   = false
    @Namespace private var zoomNamespace

    var body: some View {
        ZStack(alignment: .bottom) {
            Mono.C.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Mono.S.lg) {

                    // ── Vault Hero (balance + score) ─────────────────
                    VaultHeroCard(
                        showAchievements: $showAchievements,
                        showChallenges:   $showChallenges
                    )
                    .scaleEffect(heroScale)
                    .opacity(heroOpacity)
                    .padding(.horizontal, Mono.S.md)
                    .padding(.top, Mono.S.sm)

                    // ── Streak + Level row ───────────────────────────
                    StreakLevelRow()
                        .padding(.horizontal, Mono.S.md)
                        .offset(y: cardsOffset)
                        .opacity(cardsOffset == 0 ? 1 : 0)

                    // ── Weekly Recap (Mondays only) ──────────────────
                    if store.showWeeklyRecap {
                        WeeklyRecapCard()
                            .padding(.horizontal, Mono.S.md)
                            .offset(y: cardsOffset)
                            .opacity(cardsOffset == 0 ? 1 : 0)
                    }

                    // ── Monthly Overview (spending + health combined) ─
                    MonthlyOverviewCard()
                        .padding(.horizontal, Mono.S.md)
                        .offset(y: cardsOffset)
                        .opacity(cardsOffset == 0 ? 1 : 0)

                    // ── Active Challenges preview ────────────────────
                    if !store.activeChallenges.isEmpty {
                        ActiveChallengesPreviewCard(showChallenges: $showChallenges)
                            .padding(.horizontal, Mono.S.md)
                            .offset(y: cardsOffset)
                            .opacity(cardsOffset == 0 ? 1 : 0)
                    }

                    // ── Pinned Goals ─────────────────────────────────
                    FavoriteGoalsSection(namespace: zoomNamespace) { selectedGoal = $0 }
                        .offset(y: cardsOffset)
                        .opacity(cardsOffset == 0 ? 1 : 0)

                    // ── Achievements preview ─────────────────────────
                    AchievementsPreviewCard(showAll: $showAchievements)
                        .padding(.horizontal, Mono.S.md)
                        .offset(y: cardsOffset)
                        .opacity(cardsOffset == 0 ? 1 : 0)

                    Spacer(minLength: 100)
                }
            }

            // ── Achievement unlock toasts ────────────────────────────
            if let top = store.newlyUnlockedAchievements.first {
                AchievementToast(achievement: top) {
                    store.dismissUnlockedAchievement(top.id)
                }
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .navigationDestination(item: $selectedGoal) { item in
            GoalDetailView(itemID: item.id)
                .navigationTransition(.zoom(sourceID: item.id, in: zoomNamespace))
        }
        .sheet(isPresented: $showAchievements) {
            AchievementsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Mono.C.bg)
                .presentationCornerRadius(24)
        }
        .sheet(isPresented: $showChallenges) {
            ChallengesView()
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Mono.C.bg)
                .presentationCornerRadius(24)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.3).delay(0.08)) {
                heroScale   = 1.0
                heroOpacity = 1.0
            }
            withAnimation(.spring(duration: 0.6, bounce: 0.2).delay(0.25)) {
                cardsOffset = 0
            }
        }
    }
}

// MARK: - Vault Hero Card (balance + score ring)

struct VaultHeroCard: View {
    @Environment(AppStore.self) private var store
    @AppStorage("user_name") private var userName = ""
    @Binding var showAchievements: Bool
    @Binding var showChallenges: Bool

    @State private var innerScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            // Top row: greeting + vault score ring
            HStack(alignment: .top, spacing: Mono.S.md) {
                // Left: balance
                VStack(alignment: .leading, spacing: Mono.S.xs) {
                    if !userName.isEmpty {
                        Text("Hey, \(userName).")
                            .font(Mono.T.mono(13, .regular))
                            .foregroundColor(Mono.C.textTert)
                    }
                    OverlineLabel(text: "Total Balance")
                        .padding(.bottom, 2)

                    AnimatedAmountText(
                        digits: String(Int(max(store.totalBalance, 0))),
                        fontSize: 44,
                        weight: .bold
                    )

                    Text(VaultDateFormatter.display.string(from: Date()))
                        .font(Mono.T.label)
                        .foregroundColor(Mono.C.textTert)
                }

                Spacer()

                // Right: score ring
                Button { showAchievements = true } label: {
                    VaultScoreRing(score: store.vaultScore, size: 88, lineWidth: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.top, Mono.S.lg)
            .padding(.bottom, Mono.S.md)

            MonoDivider().padding(.horizontal, Mono.S.lg)

            // Balance breakdown
            HStack(spacing: 0) {
                BalanceStat(label: "Unassigned", amount: store.totalUnassigned, icon: "circle.dotted")
                    .frame(maxWidth: .infinity)
                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 48)
                BalanceStat(label: "Assigned", amount: store.totalAssigned, icon: "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .padding(.top, Mono.S.md)
            .padding(.bottom, Mono.S.sm)

            // Progress bar
            BalanceSegmentBar(assigned: store.totalAssigned, unassigned: store.totalUnassigned)
                .padding(.horizontal, Mono.S.lg)
                .padding(.bottom, Mono.S.md)

            MonoDivider().padding(.horizontal, Mono.S.lg)

            // Bottom stats row
            HStack(spacing: 0) {
                MiniStat(value: "\(store.savingsItems.count)", label: "Goals")
                    .frame(maxWidth: .infinity)
                MiniStat(value: "\(store.completedGoals)", label: "Funded")
                    .frame(maxWidth: .infinity)
                MiniStat(value: "\(store.transactions.count)", label: "Entries")
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, Mono.S.md)
            .padding(.horizontal, Mono.S.lg)
        }
        .monoHeroCard()
        .scaleEffect(innerScale)
        .onTapGesture {
            withAnimation(.spring(duration: 0.15, bounce: 0.6)) { innerScale = 0.97 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(duration: 0.3, bounce: 0.4)) { innerScale = 1.0 }
            }
        }
    }
}

// MARK: - Streak + Level Row

struct StreakLevelRow: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        HStack(spacing: 10) {
            // Streak card
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom, spacing: 6) {
                    Image(systemName: store.streakCount > 0 ? "flame.fill" : "flame")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            store.streakCount > 0
                                ? LinearGradient(colors: [Color(red:1,green:0.65,blue:0), Color(red:1,green:0.3,blue:0)], startPoint:.top, endPoint:.bottom)
                                : LinearGradient(colors: [Mono.C.textTert], startPoint:.top, endPoint:.bottom)
                        )
                    Text("\(store.streakCount)")
                        .font(Mono.T.mono(26, .bold))
                        .foregroundColor(Mono.C.text)
                        .contentTransition(.numericText(countsDown: false))
                }
                Text("day streak")
                    .font(Mono.T.mono(10, .regular))
                    .foregroundColor(Mono.C.textTert)
                    .padding(.top, 2)
                Spacer(minLength: 0)
                HStack(spacing: 3) {
                    Image(systemName: "medal")
                        .font(.system(size: 9))
                        .foregroundColor(Mono.C.textDim)
                    Text("Best \(store.longestStreak)d")
                        .font(Mono.T.mono(9, .medium))
                        .foregroundColor(Mono.C.textDim)
                }
            }
            .padding(Mono.S.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 96)
            .monoCard()

            // Level card
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Mono.C.accent)
                    Text("LVL \(store.currentLevel.number)")
                        .font(Mono.T.mono(13, .bold))
                        .foregroundColor(Mono.C.text)
                }
                Text(store.currentLevel.title)
                    .font(Mono.T.mono(11, .regular))
                    .foregroundColor(Mono.C.textSec)
                    .padding(.top, 3)
                Spacer(minLength: 0)
                // XP bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Mono.C.surfaceTop).frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(LinearGradient(colors: [Mono.C.accent, Mono.C.accent.opacity(0.6)],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * store.levelProgress, height: 4)
                            .animation(.spring(duration: 0.8, bounce: 0.2), value: store.levelProgress)
                    }
                }
                .frame(height: 4)
                Text("\(store.totalXP) XP")
                    .font(Mono.T.mono(9, .medium))
                    .foregroundColor(Mono.C.textDim)
                    .padding(.top, 4)
            }
            .padding(Mono.S.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 96)
            .monoCard()
        }
    }
}

// MARK: - Weekly Recap Card

struct WeeklyRecapCard: View {
    @Environment(AppStore.self) private var store
    @AppStorage("vault_monochrome") private var isMonochrome = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Mono.C.accent)
                    OverlineLabel(text: "Weekly Recap", opacity: 0.7)
                }
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        store.dismissWeeklyRecap()
                    }
                    Haptic.light()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Mono.C.textTert)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Mono.C.surfaceTop))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.top, Mono.S.md)
            .padding(.bottom, Mono.S.sm)

            MonoDivider().padding(.horizontal, Mono.S.md)

            HStack(spacing: 0) {
                RecapStat(
                    icon: "arrow.down.circle.fill",
                    label: "Saved",
                    value: store.thisMonthNet.indianFormattedCompact,
                    positive: store.thisMonthNet >= 0
                )
                .frame(maxWidth: .infinity)

                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 44)

                RecapStat(
                    icon: "flame.fill",
                    label: "Streak",
                    value: "\(store.streakCount)d",
                    positive: store.streakCount > 0
                )
                .frame(maxWidth: .infinity)

                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 44)

                RecapStat(
                    icon: "bolt.fill",
                    label: "Score",
                    value: "\(store.vaultScore)",
                    positive: store.vaultScore >= 500
                )
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, Mono.S.sm)
        }
        .monoCard()
        .overlay(
            RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                .strokeBorder(Mono.C.accent.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct RecapStat: View {
    let icon: String
    let label: String
    let value: String
    var positive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(positive ? Mono.C.accent : Mono.C.textTert)
            Text(value)
                .font(Mono.T.mono(16, .bold))
                .foregroundColor(Mono.C.text)
            Text(label.uppercased())
                .font(Mono.T.overline)
                .foregroundColor(Mono.C.textTert)
                .tracking(1.5)
        }
        .padding(.vertical, Mono.S.sm)
    }
}

// MARK: - Savings Health Card (sparkline + projection)

// MARK: - Monthly Overview Card (spending + sparkline combined)

struct MonthlyOverviewCard: View {
    @Environment(AppStore.self) private var store
    @AppStorage("vault_monochrome") private var isMonochrome = false

    private var rate: Int { Int(store.thisMonthSavingsRate * 100) }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                OverlineLabel(text: "This Month", opacity: 0.45)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: rate >= 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(abs(rate))% savings rate")
                        .font(Mono.T.mono(10, .medium))
                }
                .foregroundColor(rate >= 30 ? (isMonochrome ? Mono.C.positive : Mono.C.accent) : Mono.C.textDim)
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.top, Mono.S.md)
            .padding(.bottom, Mono.S.sm)

            // IN / OUT / NET row
            HStack(spacing: 0) {
                InsightStat(label: "In",  amount: store.thisMonthInflow,
                            color: isMonochrome ? Mono.C.positive : Mono.C.accent,
                            icon: "arrow.down.circle.fill").frame(maxWidth: .infinity)
                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 44)
                InsightStat(label: "Out", amount: store.thisMonthOutflow,
                            color: isMonochrome ? Mono.C.negative : Mono.C.red,
                            icon: "arrow.up.circle.fill").frame(maxWidth: .infinity)
                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 44)
                InsightStat(label: "Net", amount: abs(store.thisMonthNet),
                            color: store.thisMonthNet >= 0 ? (isMonochrome ? Mono.C.positive : Mono.C.accent) : (isMonochrome ? Mono.C.negative : Mono.C.red),
                            icon: store.thisMonthNet >= 0 ? "plus" : "minus").frame(maxWidth: .infinity)
            }
            .padding(.bottom, Mono.S.sm)

            // Category top-3
            if !store.thisMonthSpendByCategory.isEmpty {
                MonoDivider().padding(.horizontal, Mono.S.md)
                let top   = Array(store.thisMonthSpendByCategory.prefix(3))
                let total = top.reduce(0.0) { $0 + $1.1 }
                HStack(spacing: 4) {
                    ForEach(Array(top.enumerated()), id: \.offset) { i, pair in
                        let pct = total > 0 ? pair.1 / total : 0
                        HStack(spacing: 3) {
                            Image(systemName: pair.0.icon).font(.system(size: 9, weight: .medium))
                            Text(pair.0.label).font(Mono.T.mono(9, .medium))
                            Text("\(Int(pct * 100))%").font(Mono.T.mono(9, .regular)).foregroundColor(Mono.C.textDim)
                        }
                        .foregroundColor(i == 0 ? (isMonochrome ? Mono.C.textSec : Mono.C.red.opacity(0.9)) : Mono.C.textTert)
                        if i < top.count - 1 { Spacer() }
                    }
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.vertical, Mono.S.sm)
            }

            MonoDivider().padding(.horizontal, Mono.S.md)

            // Sparkline + projection
            HStack(alignment: .center, spacing: Mono.S.md) {
                VStack(alignment: .leading, spacing: 3) {
                    OverlineLabel(text: "8-week trend", opacity: 0.35)
                    SparklineChart(values: store.eightWeekSparkline, height: 36)
                }
                .frame(maxWidth: .infinity)

                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 52)

                VStack(alignment: .trailing, spacing: 2) {
                    OverlineLabel(text: "12M Proj.", opacity: 0.35)
                    Text(store.twelveMonthProjection.indianFormattedCompact)
                        .font(Mono.T.mono(18, .bold))
                        .foregroundColor(Mono.C.textSec)
                        .minimumScaleFactor(0.7)
                }
                .frame(width: 90, alignment: .trailing)
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.vertical, Mono.S.md)
        }
        .monoCard()
    }
}

struct SavingsHealthCard: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OverlineLabel(text: "Savings Health", opacity: 0.45)
                Spacer()
                Text("8-week trend")
                    .font(Mono.T.mono(10, .regular))
                    .foregroundColor(Mono.C.textDim)
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.top, Mono.S.md)
            .padding(.bottom, Mono.S.sm)

            // Sparkline
            SparklineChart(values: store.eightWeekSparkline)
                .padding(.horizontal, Mono.S.md)
                .padding(.bottom, Mono.S.sm)

            MonoDivider().padding(.horizontal, Mono.S.md)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 3) {
                    OverlineLabel(text: "Savings Rate", opacity: 0.4)
                    let rate = Int(store.thisMonthSavingsRate * 100)
                    Text("\(rate)%")
                        .font(Mono.T.mono(20, .bold))
                        .foregroundColor(rate >= 30 ? Mono.C.accent : Mono.C.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, Mono.S.md)

                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 44)

                VStack(alignment: .trailing, spacing: 3) {
                    OverlineLabel(text: "12M Proj.", opacity: 0.4)
                    Text(store.twelveMonthProjection.indianFormattedCompact)
                        .font(Mono.T.mono(20, .bold))
                        .foregroundColor(Mono.C.textSec)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, Mono.S.md)
            }
            .padding(.vertical, Mono.S.md)
        }
        .monoCard()
    }
}

// MARK: - Active Challenges Preview Card

struct ActiveChallengesPreviewCard: View {
    @Environment(AppStore.self) private var store
    @Binding var showChallenges: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Mono.C.accent)
                    OverlineLabel(text: "Active Challenges", opacity: 0.7)
                }
                Spacer()
                Button {
                    showChallenges = true
                    Haptic.light()
                } label: {
                    Text("View All")
                        .font(Mono.T.mono(11, .medium))
                        .foregroundColor(Mono.C.textSec)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.top, Mono.S.md)
            .padding(.bottom, Mono.S.sm)

            ForEach(Array(store.activeChallenges.prefix(3))) { challenge in
                VStack(spacing: 0) {
                    MonoDivider().padding(.horizontal, Mono.S.md)
                    HStack(spacing: Mono.S.md) {
                        Image(systemName: challenge.type.icon)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Mono.C.accent)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(challenge.type.title)
                                .font(Mono.T.mono(13, .semibold))
                                .foregroundColor(Mono.C.text)
                            let progress = store.challengeProgress(for: challenge)
                            MonoProgressBar(progress: progress, height: 3)
                            Text("\(Int(progress * 100))% complete")
                                .font(Mono.T.mono(10, .regular))
                                .foregroundColor(Mono.C.textTert)
                        }
                    }
                    .padding(.horizontal, Mono.S.md)
                    .padding(.vertical, 10)
                }
            }
        }
        .monoCard()
        .contentShape(Rectangle())
        .onTapGesture {
            showChallenges = true
            Haptic.light()
        }
    }
}

// MARK: - Achievements Preview Card

struct AchievementsPreviewCard: View {
    @Environment(AppStore.self) private var store
    @Binding var showAll: Bool

    private var recent: [Achievement] {
        store.earnedAchievements.compactMap { id in
            Achievement.all.first { $0.id == id }
        }.suffix(4).reversed()
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Mono.C.accent)
                    OverlineLabel(text: "Achievements", opacity: 0.7)
                }
                Spacer()
                Text("\(store.earnedAchievements.count)/\(Achievement.all.count)")
                    .font(Mono.T.mono(11, .regular))
                    .foregroundColor(Mono.C.textDim)
                Button {
                    showAll = true
                    Haptic.light()
                } label: {
                    Text("Cabinet →")
                        .font(Mono.T.mono(11, .medium))
                        .foregroundColor(Mono.C.textSec)
                }
                .buttonStyle(.plain)
                .padding(.leading, 6)
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.top, Mono.S.md)
            .padding(.bottom, Mono.S.sm)

            MonoDivider().padding(.horizontal, Mono.S.md)

            if recent.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "trophy")
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Mono.C.textDim)
                    Text("Start saving to earn badges")
                        .font(Mono.T.mono(12, .regular))
                        .foregroundColor(Mono.C.textTert)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Mono.S.lg)
            } else {
                HStack(spacing: Mono.S.lg) {
                    ForEach(recent) { ach in
                        AchievementBadge(achievement: ach, isEarned: true, size: .small)
                    }
                    // Locked slots
                    let remaining = min(4 - recent.count, Achievement.all.count - store.earnedAchievements.count)
                    ForEach(0..<max(0, remaining), id: \.self) { i in
                        if let locked = Achievement.all.first(where: { !store.earnedAchievements.contains($0.id) }) {
                            AchievementBadge(achievement: locked, isEarned: false, size: .small)
                        }
                    }
                }
                .padding(.vertical, Mono.S.md)
                .padding(.horizontal, Mono.S.md)
            }
        }
        .monoCard()
        .contentShape(Rectangle())
        .onTapGesture {
            showAll = true
            Haptic.light()
        }
    }
}

// MARK: - BalanceHeroCard (legacy — kept for backward compat)

struct BalanceHeroCard: View {
    @Environment(AppStore.self) private var store
    @AppStorage("user_name") private var userName = ""

    @State private var innerScale: CGFloat = 1.0

    var body: some View {
        VaultHeroCard(
            showAchievements: .constant(false),
            showChallenges:   .constant(false)
        )
    }
}

struct BalanceStat: View {
    let label: String
    let amount: Double
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Mono.C.textTert)
                OverlineLabel(text: label)
            }
            Text(amount.indianFormattedCompact)
                .font(Mono.T.mono(22, .semibold))
                .foregroundColor(Mono.C.text)
        }
        .padding(.horizontal, Mono.S.lg)
        .padding(.bottom, Mono.S.sm)
    }
}

struct MiniStat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(Mono.T.mono(18, .bold))
                .foregroundColor(Mono.C.text)
            Text(label.uppercased())
                .font(Mono.T.overline)
                .foregroundColor(Mono.C.textTert)
                .tracking(1.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Favourite Goals Section

struct FavoriteGoalsSection: View {
    @Environment(AppStore.self) private var store
    let namespace: Namespace.ID
    let onNavigate: (SavingsItem) -> Void

    private var favorites: [SavingsItem] {
        store.savingsItems.filter { $0.isFavorite }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Mono.S.md) {
            HStack {
                OverlineLabel(text: "Pinned Goals", opacity: 0.5)
                Spacer()
                if !favorites.isEmpty {
                    Text("\(favorites.count) pinned")
                        .font(Mono.T.label)
                        .foregroundColor(Mono.C.textDim)
                }
            }
            .padding(.horizontal, Mono.S.md)

            if favorites.isEmpty {
                VStack(spacing: Mono.S.sm) {
                    Image(systemName: "star")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(Mono.C.textDim)
                    Text("No pinned goals")
                        .font(Mono.T.mono(14, .medium))
                        .foregroundColor(Mono.C.textSec)
                    Text("Tap ★ on any goal to pin it here")
                        .font(Mono.T.caption)
                        .foregroundColor(Mono.C.textTert)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Mono.S.xxl)
                .monoCard()
                .padding(.horizontal, Mono.S.md)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(favorites.enumerated()), id: \.element.id) { index, item in
                        FavoriteGoalCard(item: item, namespace: namespace) { onNavigate(item) }
                            .padding(.horizontal, Mono.S.md)
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(
                                .spring(duration: 0.4, bounce: 0.3).delay(Double(index) * 0.06),
                                value: favorites.count
                            )
                    }
                }
            }
        }
    }
}

struct FavoriteGoalCard: View {
    let item: SavingsItem
    let namespace: Namespace.ID
    let onOpen: () -> Void

    @Environment(AppStore.self) private var store
    @AppStorage("vault_monochrome")  private var isMonochrome = false
    @AppStorage("smart_eta_enabled") private var etaEnabled   = true
    @State private var holdProgress: Double = 0
    @State private var showHoldRing: Bool   = false
    @State private var jitterWork: DispatchWorkItem?
    @State private var holdStartTime: Date?

    var body: some View {
        HStack(spacing: Mono.S.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                    .fill(item.isFullyFunded ? Mono.C.text : Mono.C.surfaceTop)
                    .frame(width: 44, height: 44)
                Image(systemName: item.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(item.isFullyFunded ? Mono.C.bg : Mono.C.textSec)
            }

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Text(item.name)
                        .font(Mono.T.mono(14, .semibold))
                        .foregroundColor(Mono.C.text)
                        .lineLimit(1)
                    if item.isBoostActive {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Mono.C.accent)
                    }
                }
                MonoProgressBar(progress: item.progress, height: 3)
                if etaEnabled, !item.isFullyFunded, let eta = store.goalETA(for: item.id) {
                    Text(eta)
                        .font(Mono.T.mono(10, .regular))
                        .foregroundColor(Mono.C.textDim)
                        .transition(.opacity)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(item.progress * 100))%")
                    .font(Mono.T.mono(14, .semibold))
                    .foregroundColor(Mono.C.textSec)
                Text(item.assignedAmount.indianFormattedCompact)
                    .font(Mono.T.mono(11, .regular))
                    .foregroundColor(Mono.C.textTert)
            }

            if showHoldRing {
                ZStack {
                    Circle().stroke(Mono.C.surfaceTop, lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: holdProgress)
                        .stroke(
                            isMonochrome ? Mono.C.text : Mono.C.accent,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 28, height: 28)
                .transition(.scale(scale: 0.4).combined(with: .opacity))
            }
        }
        .padding(Mono.S.md)
        .monoCard(elevated: true)
        .matchedTransitionSource(id: item.id, in: namespace)
        .onLongPressGesture(minimumDuration: 1.0, pressing: { isPressing in
            if isPressing {
                holdStartTime = Date()
                withAnimation(.spring(duration: 0.25, bounce: 0.3)) { showHoldRing = true }
                withAnimation(.linear(duration: 1.0)) { holdProgress = 1.0 }
                let work = DispatchWorkItem {
                    Haptic.light()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { Haptic.medium() }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { Haptic.light() }
                }
                jitterWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
            } else {
                let elapsed = holdStartTime.map { Date().timeIntervalSince($0) } ?? 0
                holdStartTime = nil
                if elapsed < 0.92 {
                    jitterWork?.cancel()
                    jitterWork = nil
                    withAnimation(.spring(duration: 0.3)) {
                        holdProgress = 0.0
                        showHoldRing = false
                    }
                }
            }
        }, perform: {
            jitterWork?.cancel()
            jitterWork = nil
            holdStartTime = nil
            Haptic.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { onOpen() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.2)) {
                    holdProgress = 0
                    showHoldRing = false
                }
            }
        })
    }
}

// MARK: - Spending Insights Card

struct SpendingInsightsCard: View {
    @Environment(AppStore.self) private var store
    @AppStorage("vault_monochrome") private var isMonochrome = false

    private var rate: Int { Int(store.thisMonthSavingsRate * 100) }
    private var hasData: Bool { store.thisMonthInflow > 0 || store.thisMonthOutflow > 0 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                OverlineLabel(text: "This Month", opacity: 0.45)
                Spacer()
                if hasData {
                    HStack(spacing: 4) {
                        Image(systemName: rate >= 0 ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 9, weight: .bold))
                        Text("\(abs(rate))% savings rate")
                            .font(Mono.T.mono(10, .medium))
                    }
                    .foregroundColor(rate >= 30 ? (isMonochrome ? Mono.C.positive : Mono.C.accent)
                                               : Mono.C.textDim)
                }
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.top, Mono.S.md)
            .padding(.bottom, Mono.S.sm)

            HStack(spacing: 0) {
                InsightStat(label: "In",  amount: store.thisMonthInflow,
                            color: isMonochrome ? Mono.C.positive : Mono.C.accent,
                            icon: "arrow.down.circle.fill")
                    .frame(maxWidth: .infinity)
                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 44)
                InsightStat(label: "Out", amount: store.thisMonthOutflow,
                            color: isMonochrome ? Mono.C.negative : Mono.C.red,
                            icon: "arrow.up.circle.fill")
                    .frame(maxWidth: .infinity)
                Rectangle().fill(Mono.C.border).frame(width: 0.5, height: 44)
                InsightStat(label: "Net", amount: abs(store.thisMonthNet),
                            color: store.thisMonthNet >= 0
                                ? (isMonochrome ? Mono.C.positive : Mono.C.accent)
                                : (isMonochrome ? Mono.C.negative : Mono.C.red),
                            icon: store.thisMonthNet >= 0 ? "plus" : "minus")
                    .frame(maxWidth: .infinity)
            }
            .padding(.bottom, Mono.S.md)

            if !store.thisMonthSpendByCategory.isEmpty {
                MonoDivider().padding(.horizontal, Mono.S.md)
                let top   = Array(store.thisMonthSpendByCategory.prefix(3))
                let total = top.reduce(0.0) { $0 + $1.1 }

                HStack(spacing: 4) {
                    ForEach(Array(top.enumerated()), id: \.offset) { i, pair in
                        let pct = total > 0 ? pair.1 / total : 0
                        HStack(spacing: 3) {
                            Image(systemName: pair.0.icon)
                                .font(.system(size: 9, weight: .medium))
                            Text(pair.0.label)
                                .font(Mono.T.mono(9, .medium))
                            Text("\(Int(pct * 100))%")
                                .font(Mono.T.mono(9, .regular))
                                .foregroundColor(Mono.C.textDim)
                        }
                        .foregroundColor(i == 0 ? (isMonochrome ? Mono.C.textSec : Mono.C.red.opacity(0.9)) : Mono.C.textTert)
                        if i < top.count - 1 { Spacer() }
                    }
                }
                .padding(.horizontal, Mono.S.md)
                .padding(.vertical, Mono.S.sm)
            }
        }
        .monoCard()
    }
}

private struct InsightStat: View {
    let label: String
    let amount: Double
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(color)
                OverlineLabel(text: label, opacity: 0.4)
            }
            Text(amount.currencyFormattedCompact)
                .font(Mono.T.mono(15, .semibold))
                .foregroundColor(amount > 0 ? color : Mono.C.textDim)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .padding(.vertical, Mono.S.sm)
    }
}

// MARK: - Empty State Card

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: Mono.S.sm) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Mono.C.textDim)
                .padding(.bottom, 4)
            Text(title)
                .font(Mono.T.mono(15, .semibold))
                .foregroundColor(Mono.C.textSec)
            Text(subtitle)
                .font(Mono.T.caption)
                .foregroundColor(Mono.C.textTert)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Mono.S.xxl)
        .monoCard()
    }
}

// MARK: - Transaction Row

struct TransactionRowView: View {
    @Environment(AppStore.self) private var store
    @AppStorage("vault_monochrome") private var isMonochrome = false
    @AppStorage("currency_code")    private var currencyCode = "INR"
    let transaction: Transaction
    @State private var showDetail = false

    var body: some View {
        HStack(spacing: Mono.S.md) {
            ZStack {
                Circle()
                    .fill(Mono.C.surfaceUp)
                    .frame(width: 36, height: 36)
                Image(systemName: transaction.type.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(
                        transaction.type.isRedAction
                            ? (isMonochrome ? Mono.C.negative : Mono.C.red)
                            : (isMonochrome ? Mono.C.positive : Mono.C.accent)
                    )
                    .shadow(
                        color: !isMonochrome
                            ? (transaction.type.isRedAction ? Mono.C.red.opacity(0.6) : Mono.C.accent.opacity(0.5))
                            : .clear,
                        radius: 6
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? transaction.type.label : transaction.note)
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.text)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(VaultDateFormatter.relativeDate(transaction.date))
                        .font(Mono.T.mono(11, .regular))
                        .foregroundColor(Mono.C.textTert)

                    if let payee = transaction.payee, !payee.isEmpty {
                        Text("·")
                            .foregroundColor(Mono.C.textTert)
                            .font(Mono.T.mono(11, .regular))
                        Text(payee)
                            .font(Mono.T.mono(11, .regular))
                            .foregroundColor(Mono.C.textTert)
                            .lineLimit(1)
                    }

                    if let pm = transaction.paymentMethod {
                        Image(systemName: pm.icon)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(Mono.C.textDim)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text((transaction.type.isRedAction ? "-" : "+") + transaction.amount.indianFormattedNoSymbol)
                    .font(Mono.T.mono(15, .semibold))
                    .foregroundColor(
                        transaction.type.isRedAction
                            ? (isMonochrome ? Mono.C.negative : Mono.C.red)
                            : (isMonochrome ? Mono.C.positive : Mono.C.accent)
                    )
                    .shadow(
                        color: !isMonochrome
                            ? (transaction.type.isRedAction ? Mono.C.red.opacity(0.5) : Mono.C.accent.opacity(0.4))
                            : .clear,
                        radius: 6
                    )
                Text(CurrencyInfo.current.symbol)
                    .font(Mono.T.mono(10, .medium))
                    .foregroundColor(Mono.C.textDim)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Mono.C.textDim)
        }
        .padding(.vertical, Mono.S.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            showDetail = true
            Haptic.light()
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                    store.deleteTransaction(id: transaction.id)
                }
                Haptic.medium()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .sheet(isPresented: $showDetail) {
            TransactionDetailSheet(transaction: transaction)
                .presentationDetents([.fraction(0.68), .large])
                .presentationDragIndicator(.hidden)
                .presentationBackground { Color(white: 0.065) }
                .presentationCornerRadius(24)
        }
    }
}

// MARK: - Transaction Detail Sheet

struct TransactionDetailSheet: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @AppStorage("vault_monochrome") private var isMonochrome = false

    let transaction: Transaction
    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var amountColor: Color {
        transaction.type.isRedAction
            ? (isMonochrome ? Mono.C.negative : Mono.C.red)
            : (isMonochrome ? Mono.C.positive : Mono.C.accent)
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(LinearGradient(colors: [Color.white.opacity(0.10), .clear], startPoint: .top, endPoint: .bottom))
                .frame(height: 1)

            Capsule()
                .fill(Color(white: 0.45))
                .frame(width: 44, height: 6)
                .padding(.top, 14)
                .padding(.bottom, 20)

            HStack {
                Text("Transaction")
                    .font(Mono.T.mono(15, .semibold))
                    .foregroundColor(Mono.C.text)
                Spacer()
                Button("Done") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.lg)

            // Amount hero
            VStack(spacing: 10) {
                HStack(spacing: 6) {
                    Image(systemName: transaction.type.symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(amountColor)
                    Text(transaction.type.label.uppercased())
                        .font(Mono.T.overline)
                        .foregroundColor(Mono.C.textDim)
                        .tracking(2)
                }
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(transaction.type.isRedAction ? "-\(CurrencyInfo.current.symbol)" : "+\(CurrencyInfo.current.symbol)")
                        .font(Mono.T.mono(22, .medium))
                        .foregroundColor(amountColor.opacity(0.55))
                    Text(transaction.amount.indianFormattedNoSymbol)
                        .font(Mono.T.mono(46, .bold))
                        .foregroundColor(amountColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .shadow(color: !isMonochrome ? amountColor.opacity(0.65) : .clear, radius: 18)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Mono.S.lg)
            .monoCard(elevated: true)
            .padding(.horizontal, Mono.S.md)

            // Meta rows
            VStack(spacing: 0) {
                DetailRow(icon: "text.alignleft", label: "Note",
                          value: transaction.note.isEmpty ? "—" : transaction.note)
                MonoDivider().padding(.horizontal, Mono.S.md)
                DetailRow(icon: "calendar",   label: "Date",
                          value: VaultDateFormatter.full.string(from: transaction.date))
                if let payee = transaction.payee, !payee.isEmpty {
                    MonoDivider().padding(.horizontal, Mono.S.md)
                    DetailRow(icon: "storefront", label: "Payee", value: payee)
                }
                if let pm = transaction.paymentMethod {
                    MonoDivider().padding(.horizontal, Mono.S.md)
                    DetailRow(icon: pm.icon, label: "Method", value: pm.label)
                }
                if !transaction.tags.isEmpty {
                    MonoDivider().padding(.horizontal, Mono.S.md)
                    DetailRow(icon: "tag", label: "Tags", value: transaction.tags.joined(separator: ", "))
                }
                MonoDivider().padding(.horizontal, Mono.S.md)
                DetailRow(icon: "number", label: "ID",
                          value: String(transaction.id.uuidString.prefix(8)).uppercased())
            }
            .monoCard()
            .padding(.horizontal, Mono.S.md)
            .padding(.top, Mono.S.md)

            Spacer(minLength: Mono.S.lg)

            VStack(spacing: 8) {
                Button {
                    showEdit = true
                    Haptic.medium()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil.circle.fill").font(.system(size: 15))
                        Text("Edit Transaction").font(Mono.T.mono(15, .semibold))
                    }
                    .foregroundColor(Mono.C.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: Mono.R.inner, style: .continuous)
                            .fill(Mono.C.text)
                            .shadow(color: .white.opacity(0.08), radius: 10)
                    )
                }
                .buttonStyle(.plain)

                DangerButton(icon: "trash", label: "Delete Transaction") {
                    showDeleteConfirm = true
                }
            }
            .padding(.horizontal, Mono.S.md)
            .padding(.bottom, Mono.S.xl)
        }
        .confirmationDialog("Delete this transaction?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                store.deleteTransaction(id: transaction.id)
                Haptic.medium()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showEdit) {
            EditTransactionView(transaction: transaction)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Mono.C.bg)
        }
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: Mono.S.md) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Mono.C.textDim)
                .frame(width: 18)
            Text(label)
                .font(Mono.T.mono(13, .regular))
                .foregroundColor(Mono.C.textTert)
            Spacer()
            Text(value)
                .font(Mono.T.mono(13, .medium))
                .foregroundColor(Mono.C.textSec)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(Mono.S.md)
    }
}
