import SwiftUI

// MARK: - Challenges View

struct ChallengesView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss)     private var dismiss

    @State private var showJoinSheet = false
    @State private var joiningType: ActiveChallenge.ChallengeType?

    var body: some View {
        VStack(spacing: 0) {
            // Header
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
                    Text("Challenges")
                        .font(Mono.T.mono(17, .bold))
                        .foregroundColor(Mono.C.text)
                    Text("\(store.activeChallenges.filter { !$0.isCompleted }.count) active")
                        .font(Mono.T.mono(11, .regular))
                        .foregroundColor(Mono.C.textTert)
                }
                Spacer()
                Button("Done") { dismiss() }
                    .font(Mono.T.mono(14, .medium))
                    .foregroundColor(Mono.C.textSec)
            }
            .padding(.horizontal, Mono.S.lg)
            .padding(.bottom, Mono.S.lg)

            MonoDivider()

            ScrollView(showsIndicators: false) {
                VStack(spacing: Mono.S.md) {

                    // Active challenges
                    if !store.activeChallenges.isEmpty {
                        SectionHeader(title: "Active")
                            .padding(.horizontal, Mono.S.md)
                            .padding(.top, Mono.S.md)

                        ForEach(store.activeChallenges) { challenge in
                            ActiveChallengeCard(challenge: challenge)
                                .padding(.horizontal, Mono.S.md)
                        }
                    }

                    // Available to join
                    SectionHeader(title: "Available")
                        .padding(.horizontal, Mono.S.md)
                        .padding(.top, Mono.S.md)

                    ForEach(ActiveChallenge.ChallengeType.allCases, id: \.self) { type in
                        let isActive = store.activeChallenges.contains {
                            $0.type == type && !$0.isCompleted
                        }
                        AvailableChallengeRow(
                            type:     type,
                            isActive: isActive
                        ) {
                            if !isActive {
                                store.joinChallenge(type)
                                Haptic.success()
                            }
                        }
                        .padding(.horizontal, Mono.S.md)
                    }

                    Spacer(minLength: Mono.S.xxl)
                }
            }
        }
        .background(Mono.C.bg.ignoresSafeArea())
    }
}

// MARK: - Active Challenge Card

struct ActiveChallengeCard: View {
    @Environment(AppStore.self) private var store
    let challenge: ActiveChallenge

    @State private var showLeaveAlert = false

    private var progress: Double { store.challengeProgress(for: challenge) }

    private var daysLeft: Int {
        let deadline = challenge.startDate.addingTimeInterval(Double(challenge.type.durationDays) * 86400)
        return max(Calendar.current.dateComponents([.day], from: Date(), to: deadline).day ?? 0, 0)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Mono.S.md) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                        .fill(Mono.C.surfaceUp)
                        .frame(width: 44, height: 44)
                    Image(systemName: challenge.type.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(challenge.isCompleted ? Mono.C.textTert : Mono.C.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(challenge.type.title)
                            .font(Mono.T.mono(14, .semibold))
                            .foregroundColor(Mono.C.text)
                        if challenge.isCompleted {
                            Text("DONE")
                                .font(Mono.T.mono(9, .bold))
                                .foregroundColor(Mono.C.accent)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Mono.C.accent.opacity(0.15)))
                        }
                    }
                    Text(challenge.type.subtitle)
                        .font(Mono.T.mono(10, .regular))
                        .foregroundColor(Mono.C.textTert)
                        .lineLimit(1)
                }

                Spacer()

                if !challenge.isCompleted {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(daysLeft)d")
                            .font(Mono.T.mono(16, .bold))
                            .foregroundColor(daysLeft <= 3 ? Mono.C.red : Mono.C.textSec)
                        Text("left")
                            .font(Mono.T.mono(9, .regular))
                            .foregroundColor(Mono.C.textTert)
                    }
                }
            }
            .padding(Mono.S.md)

            // Progress bar
            VStack(spacing: 6) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Mono.C.surfaceTop)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(challenge.isCompleted ? Mono.C.textSec : Mono.C.accent)
                            .frame(width: geo.size.width * progress)
                            .animation(.spring(duration: 0.8, bounce: 0.1), value: progress)
                    }
                }
                .frame(height: 5)
                .padding(.horizontal, Mono.S.md)

                HStack {
                    Text(VaultDateFormatter.display.string(from: challenge.startDate))
                        .font(Mono.T.mono(9, .regular))
                        .foregroundColor(Mono.C.textDim)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(Mono.T.mono(9, .medium))
                        .foregroundColor(Mono.C.textDim)
                }
                .padding(.horizontal, Mono.S.md)
            }
            .padding(.bottom, Mono.S.sm)

            if !challenge.isCompleted {
                MonoDivider().padding(.horizontal, Mono.S.md)
                Button {
                    showLeaveAlert = true
                    Haptic.light()
                } label: {
                    Text("Leave Challenge")
                        .font(Mono.T.mono(12, .medium))
                        .foregroundColor(Mono.C.red.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
        }
        .monoCard()
        .confirmationDialog("Leave this challenge?", isPresented: $showLeaveAlert, titleVisibility: .visible) {
            Button("Leave", role: .destructive) {
                withAnimation(.spring(duration: 0.3)) {
                    store.leaveChallenge(id: challenge.id)
                }
                Haptic.medium()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Available Challenge Row

struct AvailableChallengeRow: View {
    let type: ActiveChallenge.ChallengeType
    let isActive: Bool
    let onJoin: () -> Void

    @State private var pressed = false

    var body: some View {
        HStack(spacing: Mono.S.md) {
            ZStack {
                RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                    .fill(isActive ? Mono.C.surfaceUp : Mono.C.surface)
                    .frame(width: 44, height: 44)
                Image(systemName: type.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isActive ? Mono.C.accent : Mono.C.textTert)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(type.title)
                    .font(Mono.T.mono(14, .semibold))
                    .foregroundColor(isActive ? Mono.C.textSec : Mono.C.text)
                Text(type.subtitle)
                    .font(Mono.T.mono(10, .regular))
                    .foregroundColor(Mono.C.textTert)
                    .lineLimit(1)
            }

            Spacer()

            if isActive {
                Text("Active")
                    .font(Mono.T.mono(10, .semibold))
                    .foregroundColor(Mono.C.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Mono.C.accent.opacity(0.12)))
            } else {
                Button(action: onJoin) {
                    Text("Join")
                        .font(Mono.T.mono(12, .semibold))
                        .foregroundColor(Mono.C.bg)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Mono.C.text))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(Mono.S.md)
        .monoCard()
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            OverlineLabel(text: title, opacity: 0.45)
            Spacer()
        }
    }
}
