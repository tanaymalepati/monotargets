import SwiftUI

// MARK: - Circular Progress Ring

struct ProgressRing: View {
    let progress: Double
    var size: CGFloat = 56
    var lineWidth: CGFloat = 3.5
    var animated: Bool = true

    @State private var displayProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(Mono.C.surfaceTop, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: displayProgress)
                .stroke(
                    Mono.G.progressFill,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
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

    @State private var displayProgress: Double = 0

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                        .fill(Mono.C.surfaceTop)
                        .frame(height: height)

                    RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                        .fill(Mono.G.progressFill)
                        .frame(width: geo.size.width * displayProgress, height: height)
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

    private var total: Double { assigned + unassigned }
    private var assignedRatio: Double {
        total > 0 ? min(assigned / total, 1.0) : 0
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
                            .fill(Mono.G.progressFill)
                            .frame(
                                width: max(geo.size.width * displayRatio - 1, 0),
                                height: height
                            )
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
