import SwiftUI

// MARK: - Sparkline Chart
// Lightweight line chart for weekly savings data

struct SparklineChart: View {
    let values: [Double]
    var lineColor: Color = Mono.C.accent
    var showDots: Bool   = true
    var height: CGFloat  = 48

    @State private var appeared = false

    private var normalised: [Double] {
        let mx = values.max() ?? 1
        guard mx > 0 else { return values.map { _ in 0 } }
        return values.map { $0 / mx }
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let n = normalised
            let count = n.count
            guard count > 1 else { return AnyView(EmptyView()) }

            let step  = w / CGFloat(count - 1)
            let points: [CGPoint] = n.enumerated().map { i, v in
                CGPoint(x: CGFloat(i) * step, y: h - CGFloat(v) * h * 0.9 - h * 0.05)
            }

            return AnyView(
                ZStack {
                    // Fill under the line
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: h))
                        for pt in points { path.addLine(to: pt) }
                        path.addLine(to: CGPoint(x: points.last!.x, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [lineColor.opacity(0.25), lineColor.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .opacity(appeared ? 1 : 0)

                    // Line
                    Path { path in
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            // Smooth bezier
                            let prev = points[i - 1]
                            let curr = points[i]
                            let cp1  = CGPoint(x: prev.x + step * 0.4, y: prev.y)
                            let cp2  = CGPoint(x: curr.x - step * 0.4, y: curr.y)
                            path.addCurve(to: curr, control1: cp1, control2: cp2)
                        }
                    }
                    .trim(from: 0, to: appeared ? 1 : 0)
                    .stroke(lineColor, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))

                    // Dots at data points
                    if showDots {
                        ForEach(0..<points.count, id: \.self) { i in
                            Circle()
                                .fill(lineColor)
                                .frame(width: 4, height: 4)
                                .position(points[i])
                                .opacity(appeared ? 1 : 0)
                                .scaleEffect(appeared ? 1 : 0)
                                .animation(.spring(duration: 0.4, bounce: 0.4).delay(Double(i) * 0.05 + 0.5), value: appeared)
                        }
                    }
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 0.8).delay(0.2)) {
                        appeared = true
                    }
                }
            )
        }
        .frame(height: height)
    }
}

// MARK: - Bar Chart (week-over-week spend)

struct WeeklyBarChart: View {
    let values: [Double]
    var barColor: Color  = Mono.C.accent
    var height: CGFloat  = 56

    @State private var appeared = false

    private var maxVal: Double { values.max() ?? 1 }

    var body: some View {
        GeometryReader { geo in
            let barWidth  = (geo.size.width / CGFloat(values.count)) * 0.55
            let gap       = (geo.size.width / CGFloat(values.count)) * 0.45

            HStack(alignment: .bottom, spacing: gap) {
                ForEach(0..<values.count, id: \.self) { i in
                    let fraction = maxVal > 0 ? min(values[i] / maxVal, 1.0) : 0
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [barColor, barColor.opacity(0.5)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: barWidth, height: appeared ? max(fraction * height, 4) : 4)
                        .animation(.spring(duration: 0.5, bounce: 0.2).delay(Double(i) * 0.04 + 0.1), value: appeared)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: height, alignment: .bottom)
        }
        .frame(height: height)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                appeared = true
            }
        }
    }
}
