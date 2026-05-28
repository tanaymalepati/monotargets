import SwiftUI

// MARK: - Achievement Badge
// Used in the cabinet grid and as a toast overlay

struct AchievementBadge: View {
    let achievement: Achievement
    var isEarned: Bool
    var size: BadgeSize = .medium

    enum BadgeSize { case small, medium, large }

    private var frameSize: CGFloat {
        switch size { case .small: return 52; case .medium: return 72; case .large: return 96 }
    }
    private var iconSize: CGFloat {
        switch size { case .small: return 18; case .medium: return 26; case .large: return 36 }
    }
    private var xpLabelSize: CGFloat {
        switch size { case .small: return 9; case .medium: return 10; case .large: return 12 }
    }

    @State private var appeared = false

    var body: some View {
        VStack(spacing: size == .small ? 4 : 6) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isEarned ? Mono.C.surfaceUp : Mono.C.surface)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isEarned ? Mono.C.accent.opacity(0.5) : Mono.C.border,
                                lineWidth: isEarned ? 1.5 : 0.5
                            )
                    )
                    .shadow(color: isEarned ? Mono.C.accent.opacity(0.25) : .clear, radius: 10)

                // Icon
                Image(systemName: achievement.icon)
                    .font(.system(size: iconSize, weight: .semibold))
                    .foregroundColor(isEarned ? Mono.C.accent : Mono.C.textTert)
                    .symbolEffect(.bounce, value: appeared)

                // Locked overlay
                if !isEarned {
                    Circle()
                        .fill(.black.opacity(0.4))
                    Image(systemName: "lock.fill")
                        .font(.system(size: iconSize * 0.55))
                        .foregroundColor(Mono.C.textTert)
                }
            }
            .frame(width: frameSize, height: frameSize)
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)

            if size != .small {
                VStack(spacing: 2) {
                    Text(achievement.title)
                        .font(Mono.T.mono(10, .semibold))
                        .foregroundColor(isEarned ? Mono.C.text : Mono.C.textTert)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)

                    if isEarned {
                        Text("+\(achievement.xp) XP")
                            .font(Mono.T.mono(xpLabelSize, .medium))
                            .foregroundColor(Mono.C.accent)
                    }
                }
                .frame(width: frameSize + 8)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.35).delay(0.05)) {
                appeared = true
            }
        }
    }
}

// MARK: - Achievement Toast (new unlock notification)

struct AchievementToast: View {
    let achievement: Achievement
    var onDismiss: () -> Void

    @State private var offset: CGFloat = 100
    @State private var opacity: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Mono.C.surfaceUp)
                    .overlay(Circle().strokeBorder(Mono.C.accent.opacity(0.5), lineWidth: 1.5))
                    .frame(width: 44, height: 44)
                Image(systemName: achievement.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Mono.C.accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("ACHIEVEMENT UNLOCKED")
                        .font(Mono.T.mono(9, .semibold))
                        .foregroundColor(Mono.C.accent)
                        .tracking(1.5)
                }
                Text(achievement.title)
                    .font(Mono.T.mono(14, .bold))
                    .foregroundColor(Mono.C.text)
                Text("+\(achievement.xp) XP")
                    .font(Mono.T.mono(12, .medium))
                    .foregroundColor(Mono.C.textSec)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Mono.C.textTert)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Mono.C.surfaceTop))
            }
        }
        .padding(14)
        .monoCard(elevated: true)
        .padding(.horizontal, 16)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                offset = 0
                opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation(.spring(duration: 0.4)) {
                    offset = 100
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    onDismiss()
                }
            }
        }
    }
}
