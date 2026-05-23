import SwiftUI

enum Mono {

    // MARK: - Colors
    enum C {
        static let bg          = Color(white: 0.035)
        static let surface     = Color(white: 0.075)
        static let surfaceUp   = Color(white: 0.115)
        static let surfaceTop  = Color(white: 0.155)
        static let border      = Color(white: 0.130)
        static let borderBright = Color(white: 0.220)

        static let white       = Color.white
        static let text        = Color(white: 1.00)
        static let textSec     = Color(white: 0.62)
        static let textTert    = Color(white: 0.38)
        static let textDim     = Color(white: 0.22)

        static let positive    = Color(white: 0.96)
        static let negative    = Color(white: 0.48)
        static let accent      = Color.white
    }

    // MARK: - Typography
    enum T {
        static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
            .system(size: size, weight: weight, design: .monospaced)
        }

        static let hero        = mono(56, .bold)
        static let heroSub     = mono(28, .semibold)
        static let bigNum      = mono(38, .bold)
        static let medNum      = mono(24, .semibold)
        static let smallNum    = mono(18, .medium)
        static let tinyNum     = mono(14, .medium)

        static let title       = mono(22, .bold)
        static let headline    = mono(17, .semibold)
        static let body        = mono(15, .regular)
        static let caption     = mono(12, .regular)
        static let label       = mono(11, .medium)
        static let overline    = mono(10, .semibold)
    }

    // MARK: - Spacing
    enum S {
        static let xs: CGFloat  = 4
        static let sm: CGFloat  = 8
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 24
        static let xl: CGFloat  = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: - Radius  (squircle — .continuous style + tighter radii)
    enum R {
        static let card:   CGFloat = 16
        static let inner:  CGFloat = 12
        static let button: CGFloat = 10
        static let pill:   CGFloat = 100
        static let icon:   CGFloat = 10
        static let small:  CGFloat = 7
    }

    // MARK: - Gradients
    enum G {
        static let hero = LinearGradient(
            colors: [Color(white: 0.18), Color(white: 0.07)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let card = LinearGradient(
            colors: [Color(white: 0.13), Color(white: 0.07)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let cardSubtle = LinearGradient(
            colors: [Color(white: 0.10), Color(white: 0.06)],
            startPoint: .top, endPoint: .bottom
        )
        static let sheen = LinearGradient(
            colors: [Color.white.opacity(0.00), Color.white.opacity(0.05), Color.white.opacity(0.00)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
        static let progressTrack = LinearGradient(
            colors: [Color(white: 0.18), Color(white: 0.12)],
            startPoint: .leading, endPoint: .trailing
        )
        static let progressFill = LinearGradient(
            colors: [Color(white: 0.95), Color(white: 0.72)],
            startPoint: .leading, endPoint: .trailing
        )
    }
}

// MARK: - View Modifiers

struct MonoCardStyle: ViewModifier {
    var elevated: Bool = false

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                    .fill(elevated ? Mono.G.card : Mono.G.cardSubtle)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                            .strokeBorder(Mono.C.border, lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.55), radius: 18, x: 0, y: 8)
                    .shadow(color: .white.opacity(0.03), radius: 1, x: 0, y: -1)
            )
    }
}

struct MonoHeroCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                    .fill(Mono.G.hero)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                            .fill(Mono.G.sheen)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.card, style: .continuous)
                            .strokeBorder(Mono.C.borderBright.opacity(0.5), lineWidth: 0.6)
                    )
                    .shadow(color: .black.opacity(0.65), radius: 28, x: 0, y: 14)
                    .shadow(color: .white.opacity(0.06), radius: 1, x: 0, y: -1)
            )
    }
}

struct MonoPillButtonStyle: ButtonStyle {
    var filled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Mono.T.mono(14, .semibold))
            .foregroundColor(filled ? Mono.C.bg : Mono.C.text)
            .padding(.horizontal, Mono.S.md)
            .padding(.vertical, Mono.S.sm)
            .background(
                Capsule(style: .continuous)
                    .fill(filled ? Mono.C.text : Mono.C.surfaceUp)
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Mono.C.border, lineWidth: 0.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(duration: 0.2, bounce: 0.4), value: configuration.isPressed)
    }
}

struct MonoIconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(width: 44, height: 44)
            .background(
                RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                    .fill(Mono.C.surfaceUp)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.icon, style: .continuous)
                            .strokeBorder(Mono.C.border, lineWidth: 0.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(duration: 0.18, bounce: 0.5), value: configuration.isPressed)
    }
}

extension View {
    func monoCard(elevated: Bool = false) -> some View {
        modifier(MonoCardStyle(elevated: elevated))
    }

    func monoHeroCard() -> some View {
        modifier(MonoHeroCardStyle())
    }
}

// MARK: - Overline Label

struct OverlineLabel: View {
    let text: String
    var opacity: Double = 0.4

    var body: some View {
        Text(text.uppercased())
            .font(Mono.T.overline)
            .foregroundColor(Mono.C.text.opacity(opacity))
            .tracking(2)
    }
}

// MARK: - Divider

struct MonoDivider: View {
    var body: some View {
        Rectangle()
            .fill(Mono.C.border)
            .frame(height: 0.5)
    }
}
