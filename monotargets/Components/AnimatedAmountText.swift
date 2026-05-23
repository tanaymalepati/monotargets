import SwiftUI

// MARK: - Animated Amount Display
// Each digit bounces in independently with a cascade stagger effect

struct AnimatedAmountText: View {
    let digits: String
    var fontSize: CGFloat = 52
    var weight: Font.Weight = .bold
    var color: Color = Mono.C.text

    private var formatted: String {
        AmountFormatter.format(digits: digits)
    }

    var body: some View {
        HStack(spacing: 0) {
            Text("₹")
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

    @State private var cursorVisible: Bool = true

    private var formatted: String {
        AmountFormatter.format(digits: digits)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("₹")
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

    private let keys: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["⌫", "0", "✓"],
    ]

    var onConfirm: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        NumpadKey(label: key) {
                            handleKey(key)
                        }
                        .disabled(key == "✓" ? digits.isEmpty : false)
                    }
                }
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
    let action: () -> Void

    @State private var pressed = false

    var isSpecial: Bool { label == "⌫" || label == "✓" }
    var isConfirm: Bool { label == "✓" }

    var body: some View {
        Button(action: {
            withAnimation(.spring(duration: 0.12, bounce: 0.6)) { pressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(duration: 0.2, bounce: 0.3)) { pressed = false }
            }
            action()
        }) {
            ZStack {
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
                        .foregroundColor(Mono.C.text)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .scaleEffect(pressed ? 0.88 : 1.0)
        }
        .buttonStyle(.plain)
    }
}
