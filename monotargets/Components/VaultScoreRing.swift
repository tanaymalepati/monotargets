import SwiftUI

// MARK: - Vault Score Ring
// Animated arc ring displaying 0–1000 Vault Score

struct VaultScoreRing: View {
    let score: Int
    var size: CGFloat = 120
    var lineWidth: CGFloat = 10

    @State private var animatedFraction: Double = 0

    private var fraction: Double { Double(score) / 1000.0 }

    private var scoreColor: Color {
        switch score {
        case 0..<300:   return Color(white: 0.45)
        case 300..<600: return Mono.C.accent.opacity(0.7)
        default:        return Mono.C.accent
        }
    }

    var body: some View {
        ZStack {
            // Track
            Circle()
                .trim(from: 0.1, to: 0.9)
                .stroke(Mono.C.surfaceTop, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(90))

            // Fill
            Circle()
                .trim(from: 0.1, to: 0.1 + animatedFraction * 0.8)
                .stroke(
                    AngularGradient(
                        colors: [scoreColor.opacity(0.6), scoreColor],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(90))

            // Score label
            VStack(spacing: 2) {
                Text("\(score)")
                    .font(Mono.T.mono(size * 0.25, .bold))
                    .foregroundColor(Mono.C.text)
                    .contentTransition(.numericText(countsDown: false))
                Text("/ 1000")
                    .font(Mono.T.mono(size * 0.09, .regular))
                    .foregroundColor(Mono.C.textTert)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(duration: 1.2, bounce: 0.2).delay(0.1)) {
                animatedFraction = fraction
            }
        }
        .onChange(of: score) { _, _ in
            withAnimation(.spring(duration: 0.6, bounce: 0.1)) {
                animatedFraction = fraction
            }
        }
    }
}

// MARK: - Compact score badge (used inline)

struct VaultScoreChip: View {
    let score: Int

    private var label: String {
        switch score {
        case 0..<200:   return "Starting Out"
        case 200..<400: return "Building Up"
        case 400..<600: return "On Track"
        case 600..<800: return "Solid Saver"
        default:        return "Vault Master"
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Mono.C.accent)
            Text("\(score)")
                .font(Mono.T.mono(13, .bold))
                .foregroundColor(Mono.C.text)
            Text(label)
                .font(Mono.T.mono(11, .regular))
                .foregroundColor(Mono.C.textSec)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule(style: .continuous)
                .fill(Mono.C.surfaceUp)
                .overlay(Capsule(style: .continuous).strokeBorder(Mono.C.border, lineWidth: 0.5))
        )
    }
}
