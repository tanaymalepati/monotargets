import SwiftUI

// MARK: - Circular Progress Ring

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 56
    var lineWidth: CGFloat = 3.5
    var animated: Bool = true

    @AppStorage("vault_monochrome") private var isMonochrome = false
    @State private var displayProgress: Double = 0

    private var ringGradient: LinearGradient {
        isMonochrome
            ? LinearGradient(colors: [Color(white: 0.70), Color(white: 0.50)], startPoint: .leading, endPoint: .trailing)
            : Mono.G.progressFill
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Mono.C.surfaceTop, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: displayProgress)
                .stroke(
                    ringGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: isMonochrome ? .clear : Mono.C.accent.opacity(0.7), radius: 8, x: 0, y: 0)
                .animation(.spring(duration: 1.0, bounce: 0.2), value: displayProgress)
        }
        .frame(width: size, height: size)
        .onAppear {
            if animated {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    displayProgress = progress
                }
            } else {
                displayProgress = progress
            }
        }
        .onChange(of: progress) { _, new in
            withAnimation(.spring(duration: 0.8, bounce: 0.15)) {
                displayProgress = new
            }
        }
    }
}

// MARK: - Linear Progress Bar

struct MonoProgressBar: View {
    let progress: Double
    var height: CGFloat = 4
    var showLabel: Bool = false

    @AppStorage("vault_monochrome") private var isMonochrome = false
    @State private var displayProgress: Double = 0

    private var barGradient: LinearGradient {
        isMonochrome
            ? LinearGradient(colors: [Color(white: 0.70), Color(white: 0.50)], startPoint: .leading, endPoint: .trailing)
            : Mono.G.progressFill
    }

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                        .fill(Mono.C.surfaceTop)
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                        .fill(barGradient)
                        .frame(width: geo.size.width * displayProgress, height: height)
                        .shadow(color: isMonochrome ? .clear : Mono.C.accent.opacity(0.65), radius: 6, x: 0, y: 0)
                        .animation(.spring(duration: 1.0, bounce: 0.15), value: displayProgress)
                }
            }
            .frame(height: height)

            if showLabel {
                HStack {
                    Spacer()
                    Text("\(Int(displayProgress * 100))%")
                        .font(Mono.T.label)
                        .foregroundColor(Mono.C.textSec)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                displayProgress = progress
            }
        }
        .onChange(of: progress) { _, new in
            withAnimation(.spring(duration: 0.8, bounce: 0.1)) {
                displayProgress = new
            }
        }
    }
}

// MARK: - Segmented Balance Bar

struct BalanceSegmentBar: View {
    let assigned: Double
    let unassigned: Double
    var height: CGFloat = 6

    @AppStorage("vault_monochrome") private var isMonochrome = false

    private var total: Double { assigned + unassigned }
    private var assignedRatio: Double {
        total > 0 ? min(assigned / total, 1.0) : 0
    }

    private var segGradient: LinearGradient {
        isMonochrome
            ? LinearGradient(colors: [Color(white: 0.70), Color(white: 0.50)], startPoint: .leading, endPoint: .trailing)
            : Mono.G.progressFill
    }

    @State private var displayRatio: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(Mono.C.surfaceTop)
                    .frame(height: height)

                HStack(spacing: 1.5) {
                    if displayRatio > 0 {
                        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                            .fill(segGradient)
                            .frame(
                                width: max(geo.size.width * displayRatio - 1, 0),
                                height: height
                            )
                            .shadow(color: isMonochrome ? .clear : Mono.C.accent.opacity(0.65), radius: 6, x: 0, y: 0)
                    }

                    if displayRatio < 1.0 && displayRatio > 0 {
                        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                            .fill(Mono.C.surfaceTop)
                            .frame(
                                width: geo.size.width * (1 - displayRatio) - 1,
                                height: height
                            )
                    } else if displayRatio == 0 {
                        RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                            .fill(Mono.C.surfaceTop)
                            .frame(width: geo.size.width, height: height)
                    }
                }
                .animation(.spring(duration: 1.2, bounce: 0.1), value: displayRatio)
            }
        }
        .frame(height: height)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                displayRatio = assignedRatio
            }
        }
        .onChange(of: assignedRatio) { _, new in
            withAnimation(.spring(duration: 0.8, bounce: 0.1)) {
                displayRatio = new
            }
        }
    }
}
