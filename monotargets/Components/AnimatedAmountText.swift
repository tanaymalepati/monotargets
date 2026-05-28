import SwiftUI

// MARK: - Animated Amount Display
// Each digit bounces in independently with a cascade stagger effect

struct AnimatedAmountText: View {
    let digits: String
    var fontSize: CGFloat = 52
    var weight: Font.Weight = .bold
    var color: Color = Mono.C.text

    @AppStorage("currency_code") private var currencyCode = "INR"
    private var symbol: String { CurrencyInfo.current.symbol }

    private var formatted: String {
        AmountFormatter.format(digits: digits)
    }

    var body: some View {
        HStack(spacing: 0) {
            Text(symbol)
                .font(.system(size: fontSize * 0.52, weight: weight, design: .monospaced))
                .foregroundColor(color.opacity(0.6))
                .baselineOffset(fontSize * 0.08)

            // Animated digits using transition
            HStack(spacing: 0) {
                ForEach(Array(formatted.enumerated()), id: \.offset) { index, char in
                    Text(String(char))
                        .font(.system(size: fontSize, weight: weight, design: .monospaced))
                        .foregroundColor(char == "," ? color.opacity(0.35) : color)
                        .id("\(index)_\(char)")
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.7)),
                                removal: .move(edge: .top).combined(with: .opacity).combined(with: .scale(scale: 0.7))
                            )
                        )
                }
            }
            .animation(.spring(duration: 0.35, bounce: 0.45), value: formatted)
        }
    }
}

// MARK: - Amount Input Field (custom numeric pad)

struct AmountInputField: View {
    @Binding var digits: String
    var placeholder: String = "0"
    var fontSize: CGFloat = 52
    var showCursor: Bool = true

    @AppStorage("currency_code") private var currencyCode = "INR"
    private var symbol: String { CurrencyInfo.current.symbol }

    @State private var cursorVisible: Bool = true

    private var formatted: String {
        AmountFormatter.format(digits: digits)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text(symbol)
                    .font(.system(size: fontSize * 0.52, weight: .bold, design: .monospaced))
                    .foregroundColor(digits.isEmpty ? Mono.C.textDim : Mono.C.text.opacity(0.6))
                    .baselineOffset(fontSize * 0.08)

                if digits.isEmpty {
                    Text(placeholder)
                        .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                        .foregroundColor(Mono.C.textDim)
                } else {
                    HStack(spacing: 0) {
                        ForEach(Array(formatted.enumerated()), id: \.offset) { index, char in
                            Text(String(char))
                                .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                                .foregroundColor(char == "," ? Mono.C.text.opacity(0.35) : Mono.C.text)
                                .id("\(index)_\(char)")
                                .transition(
                                    .asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity).combined(with: .scale(scale: 0.6)),
                                        removal: .opacity
                                    )
                                )
                        }
                    }
                    .animation(.spring(duration: 0.28, bounce: 0.5), value: formatted)
                }

                if showCursor {
                    Rectangle()
                        .fill(Mono.C.text)
                        .frame(width: 2.5, height: fontSize * 0.85)
                        .opacity(cursorVisible ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(), value: cursorVisible)
                        .padding(.leading, 2)
                }
            }
            .frame(maxWidth: .infinity)

            MonoDivider()
                .padding(.top, 8)
        }
        .onAppear {
            cursorVisible = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                cursorVisible = true
            }
        }
    }
}

// MARK: - Numeric Keypad

struct MonoNumpad: View {
    @Binding var digits: String
    var maxDigits: Int = 12
    var showConfirmKey: Bool = true
    /// Accent colour used for the brief flash on digit keys.
    /// Pass `Mono.C.accent` for assign views, `Mono.C.red` for unassign views.
    var accentColor: Color = Mono.C.textDim

    private let topKeys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
    ]

    var onConfirm: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(topKeys, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        NumpadKey(label: key, flashColor: accentColor) { handleKey(key) }
                    }
                }
            }
            // Bottom row
            if showConfirmKey {
                HStack(spacing: 10) {
                    NumpadKey(label: "⌫", flashColor: accentColor) { handleKey("⌫") }
                    NumpadKey(label: "0", flashColor: accentColor) { handleKey("0") }
                    NumpadKey(label: "✓", flashColor: accentColor) { handleKey("✓") }
                        .disabled(digits.isEmpty)
                }
            } else {
                GeometryReader { geo in
                    let spacing: CGFloat = 10
                    let colW = (geo.size.width - spacing * 2) / 3
                    HStack(spacing: spacing) {
                        NumpadKey(label: "⌫", flashColor: accentColor) { handleKey("⌫") }
                            .frame(width: colW)
                        NumpadKey(label: "0", flashColor: accentColor) { handleKey("0") }
                            .frame(width: colW * 2 + spacing)
                    }
                }
                .frame(height: 64)
            }
        }
        .padding(.horizontal, 4)
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫":
            if !digits.isEmpty {
                digits = String(digits.dropLast())
                Haptic.light()
            } else {
                Haptic.rigid()
            }
        case "✓":
            Haptic.success()
            onConfirm?()
        default:
            if digits.count < maxDigits {
                if digits == "0" && key != "0" { digits = key }
                else if !(digits.isEmpty && key == "0") { digits += key }
                Haptic.light()
            } else {
                Haptic.rigid()
            }
        }
    }
}

struct NumpadKey: View {
    let label: String
    /// Color the key briefly flashes when pressed (digit keys only).
    var flashColor: Color = Mono.C.textDim
    let action: () -> Void

    @State private var pressed = false
    @State private var flashOpacity: Double = 0
    @State private var textLit = false

    var isSpecial: Bool { label == "⌫" || label == "✓" }
    var isConfirm: Bool { label == "✓" }
    var isDigit:   Bool { !isSpecial }

    var body: some View {
        Button(action: {
            // Push-in scale
            withAnimation(.spring(duration: 0.09, bounce: 0.4)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
                withAnimation(.spring(duration: 0.28, bounce: 0.55)) { pressed = false }
            }
            // Colour flash on digit keys
            if isDigit {
                withAnimation(.easeOut(duration: 0.04)) { flashOpacity = 1; textLit = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                    withAnimation(.easeOut(duration: 0.28)) { flashOpacity = 0 }
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                    withAnimation(.easeOut(duration: 0.18)) { textLit = false }
                }
            }
            action()
        }) {
            ZStack {
                // Base fill
                RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                    .fill(isConfirm ? Mono.C.text : Mono.C.surfaceUp)
                    .overlay(
                        RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                            .strokeBorder(
                                isConfirm ? Mono.C.white.opacity(0.15) : Mono.C.border,
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                // Flash overlay (digit keys only)
                if isDigit {
                    RoundedRectangle(cornerRadius: Mono.R.button, style: .continuous)
                        .fill(flashColor.opacity(flashOpacity * 0.20))
                        .allowsHitTesting(false)
                }

                if label == "⌫" {
                    Image(systemName: "delete.left")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Mono.C.textSec)
                } else if label == "✓" {
                    Image(systemName: "checkmark")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Mono.C.bg)
                } else {
                    Text(label)
                        .font(Mono.T.mono(26, .medium))
                        .foregroundColor(textLit ? flashColor : Mono.C.text)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .scaleEffect(pressed ? 0.86 : 1.0)
            // Outer glow pops with the flash
            .shadow(
                color: isDigit ? flashColor.opacity(flashOpacity * 0.40) : .clear,
                radius: 10, x: 0, y: 0
            )
        }
        .buttonStyle(.plain)
    }
}
