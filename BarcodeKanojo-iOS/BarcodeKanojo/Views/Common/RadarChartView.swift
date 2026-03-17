import SwiftUI

/// 5-axis radar/pentagon chart for kanojo stats.
/// Inputs: normalized values (0…100) and axis labels.
struct RadarChartView: View {

    let values: [CGFloat]
    let labels: [String]
    let maxValue: CGFloat

    /// Number of concentric grid lines (including outer border)
    private let gridLevels = 4

    init(values: [CGFloat], labels: [String], maxValue: CGFloat = 100) {
        self.values = values
        self.labels = labels
        self.maxValue = maxValue
    }

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2 - 30
            let axisCount = values.count

            ZStack {
                // Grid polygons
                ForEach(1...gridLevels, id: \.self) { level in
                    let fraction = CGFloat(level) / CGFloat(gridLevels)
                    PolygonShape(sides: axisCount, radius: radius * fraction)
                        .stroke(Color.gray.opacity(0.25), lineWidth: 1)
                        .offset(x: center.x - radius, y: center.y - radius)
                }

                // Axis lines from center
                ForEach(0..<axisCount, id: \.self) { i in
                    let angle = angleFor(index: i, total: axisCount)
                    let endX = center.x + radius * cos(angle)
                    let endY = center.y + radius * sin(angle)
                    Path { path in
                        path.move(to: center)
                        path.addLine(to: CGPoint(x: endX, y: endY))
                    }
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }

                // Data polygon (filled)
                DataPolygonShape(
                    values: values.map { min($0, maxValue) / maxValue },
                    radius: radius
                )
                .fill(Color.pink.opacity(0.25))
                .offset(x: center.x - radius, y: center.y - radius)

                // Data polygon (border)
                DataPolygonShape(
                    values: values.map { min($0, maxValue) / maxValue },
                    radius: radius
                )
                .stroke(Color.pink, lineWidth: 2)
                .offset(x: center.x - radius, y: center.y - radius)

                // Data points
                ForEach(0..<axisCount, id: \.self) { i in
                    let frac = min(values[i], maxValue) / maxValue
                    let angle = angleFor(index: i, total: axisCount)
                    let px = center.x + radius * frac * cos(angle)
                    let py = center.y + radius * frac * sin(angle)
                    Circle()
                        .fill(Color.pink)
                        .frame(width: 6, height: 6)
                        .position(x: px, y: py)
                }

                // Labels
                ForEach(0..<axisCount, id: \.self) { i in
                    let angle = angleFor(index: i, total: axisCount)
                    let labelRadius = radius + 20
                    let lx = center.x + labelRadius * cos(angle)
                    let ly = center.y + labelRadius * sin(angle)
                    Text(i < labels.count ? labels[i] : "")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                        .position(x: lx, y: ly)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    /// Angle for axis index (start from top, -π/2 offset so first axis is at top).
    private func angleFor(index: Int, total: Int) -> CGFloat {
        let slice = 2 * CGFloat.pi / CGFloat(total)
        return slice * CGFloat(index) - .pi / 2
    }
}

// MARK: - Regular Polygon Shape (for grid)

private struct PolygonShape: Shape {
    let sides: Int
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: radius, y: radius)
        guard sides >= 3 else { return path }
        for i in 0...sides {
            let angle = 2 * CGFloat.pi / CGFloat(sides) * CGFloat(i) - .pi / 2
            let point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Data Polygon Shape

private struct DataPolygonShape: Shape {
    /// Normalized values (0…1) for each axis.
    let values: [CGFloat]
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: radius, y: radius)
        let count = values.count
        guard count >= 3 else { return path }
        for i in 0...count {
            let idx = i % count
            let angle = 2 * CGFloat.pi / CGFloat(count) * CGFloat(idx) - .pi / 2
            let r = radius * values[idx]
            let point = CGPoint(
                x: center.x + r * cos(angle),
                y: center.y + r * sin(angle)
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
