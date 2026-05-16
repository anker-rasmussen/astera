import SwiftUI

/// Circular cycle visualisation. Each day is an arc segment in its phase colour;
/// today is marked with a small ink dot on the ring. Used as the signature visual
/// moment on the Home tab.
struct CyclePhaseRing: View {
    let cycleDay: Int
    let cycleLength: Int
    var diameter: CGFloat = 240
    var strokeWidth: CGFloat = 14

    private var calendar: Calendar { Calendar.current }

    var body: some View {
        ZStack {
            Canvas { context, canvasSize in
                let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
                let radius = (min(canvasSize.width, canvasSize.height) - strokeWidth) / 2

                let segmentRad = 2 * .pi / Double(cycleLength)
                let gapRad = segmentRad * 0.05  // tiny tick between days

                for day in 1...cycleLength {
                    let phase = CyclePhase.phase(forDay: day, in: cycleLength)
                    let startAngle = -.pi / 2 + Double(day - 1) * segmentRad + gapRad / 2
                    let endAngle = startAngle + segmentRad - gapRad

                    var path = Path()
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .radians(startAngle),
                        endAngle: .radians(endAngle),
                        clockwise: false
                    )

                    let isFuture = day > cycleDay
                    let opacity: Double = isFuture ? 0.32 : 1.0
                    context.stroke(
                        path,
                        with: .color(phase.color.opacity(opacity)),
                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt)
                    )
                }

                // Today indicator: a small ink dot sitting on the ring.
                if cycleDay >= 1 && cycleDay <= cycleLength {
                    let todayMidAngle = -.pi / 2 + (Double(cycleDay - 1) + 0.5) * segmentRad
                    let dotRadius: CGFloat = strokeWidth * 0.55
                    let dotCenter = CGPoint(
                        x: center.x + cos(todayMidAngle) * radius,
                        y: center.y + sin(todayMidAngle) * radius
                    )
                    let dotRect = CGRect(
                        x: dotCenter.x - dotRadius,
                        y: dotCenter.y - dotRadius,
                        width: dotRadius * 2,
                        height: dotRadius * 2
                    )
                    context.fill(Path(ellipseIn: dotRect), with: .color(AsteraColor.ink))
                    context.stroke(
                        Path(ellipseIn: dotRect.insetBy(dx: -3, dy: -3)),
                        with: .color(AsteraColor.vellum),
                        lineWidth: 3
                    )
                }
            }
            .frame(width: diameter, height: diameter)

            centerLabel
        }
        .frame(width: diameter, height: diameter)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Day \(cycleDay) of \(cycleLength), in \(currentPhase.name) phase")
    }

    private var currentPhase: CyclePhase {
        CyclePhase.phase(forDay: cycleDay, in: cycleLength)
    }

    private var centerLabel: some View {
        VStack(spacing: 2) {
            Text("Day")
                .font(.asteraSerifItalic(18))
                .foregroundStyle(AsteraColor.iron)
            Text("\(cycleDay)")
                .font(.asteraNumeric(72, weight: .medium))
                .foregroundStyle(AsteraColor.ink)
                .contentTransition(.numericText())
            HStack(spacing: 5) {
                Circle()
                    .fill(currentPhase.color)
                    .frame(width: 7, height: 7)
                Text(currentPhase.name)
                    .font(.asteraCaps(11))
                    .tracking(1.6)
                    .foregroundStyle(AsteraColor.iron)
            }
            .padding(.top, 2)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        CyclePhaseRing(cycleDay: 3, cycleLength: 28)
        CyclePhaseRing(cycleDay: 14, cycleLength: 28)
        CyclePhaseRing(cycleDay: 22, cycleLength: 28)
    }
    .padding(40)
    .background(AsteraColor.vellum)
}
