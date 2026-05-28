import SwiftUI

// MARK: - Streak Badge
// Flame icon with animated streak counter

struct StreakBadge: View {
    let streakCount: Int
    var size: BadgeSize = .medium

    enum BadgeSize { case small, medium, large }

    private var iconSize: CGFloat {
        switch size { case .small: return 16; case .medium: return 22; case .large: return 32 }
    }
    private var numSize: CGFloat {
        switch size { case .small: return 14; case .medium: return 20; case .large: return 28 }
    }
    private var labelSize: CGFloat {
        switch size { case .small: return 9; case .medium: return 11; case .large: return 13 }
    }

    @State private var flameScale: Double = 1.0
    @State private var appeared = false

    var body: some View {
        HStack(spacing: size == .small ? 4 : 6) {
            Image(systemName: streakCount > 0 ? "flame.fill" : "flame")
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundStyle(
                    streakCount > 0
                        ? LinearGradient(colors: [Color(red: 1, green: 0.65, blue: 0), Color(red: 1, green: 0.3, blue: 0)],
                                         startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [Mono.C.textTert], startPoint: .top, endPoint: .bottom)
                )
                .scaleEffect(flameScale)
                .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: flameScale)
                .onAppear {
                    if streakCount > 0 { flameScale = 1.08 }
                }

            VStack(alignment: .leading, spacing: 1) {
                Text("\(streakCount)")
                    .font(Mono.T.mono(numSize, .bold))
                    .foregroundColor(streakCount > 0 ? Mono.C.text : Mono.C.textTert)
                    .contentTransition(.numericText(countsDown: false))

                if size != .small {
                    Text(streakCount == 1 ? "day streak" : "day streak")
                        .font(Mono.T.mono(labelSize, .regular))
                        .foregroundColor(Mono.C.textTert)
                }
            }
        }
    }
}

// MARK: - Streak Ring (for HomeView hero area)

struct StreakRingBadge: View {
    let streakCount: Int
    let longestStreak: Int
    var size: CGFloat = 80

    @State private var animatedFraction: Double = 0
    @State private var flameScale: Double = 1.0

    private var fraction: Double {
        guard longestStreak > 0 else { return 0 }
        return min(Double(streakCount) / Double(max(longestStreak, 1)), 1.0)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Mono.C.surfaceTop, lineWidth: 6)

            Circle()
                .trim(from: 0, to: animatedFraction)
                .stroke(
                    LinearGradient(
                        colors: [Color(red: 1, green: 0.65, blue: 0), Color(red: 1, green: 0.2, blue: 0)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 1) {
                Image(systemName: "flame.fill")
                    .font(.system(size: size * 0.22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(red: 1, green: 0.65, blue: 0), Color(red: 1, green: 0.3, blue: 0)],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .scaleEffect(flameScale)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: flameScale)
                    .onAppear { if streakCount > 0 { flameScale = 1.12 } }

                Text("\(streakCount)")
                    .font(Mono.T.mono(size * 0.22, .bold))
                    .foregroundColor(Mono.C.text)
                    .contentTransition(.numericText(countsDown: false))
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(duration: 1.0, bounce: 0.2).delay(0.15)) {
                animatedFraction = fraction
            }
        }
        .onChange(of: streakCount) { _, _ in
            withAnimation(.spring(duration: 0.6)) {
                animatedFraction = fraction
            }
        }
    }
}
