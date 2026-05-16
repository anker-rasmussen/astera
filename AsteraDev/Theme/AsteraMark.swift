import SwiftUI

/// The Astera mark: a three-star asterism (constellation) drawn in SwiftUI Canvas.
/// Mirrors the app icon so on-device chrome and the home-screen icon read as the same brand.
/// Used in chapter headers, on the welcome screen, the lock screen, and as a subtle accent.
struct AsteraMark: View {
    var size: CGFloat = 28
    var color: Color = AsteraColor.accent

    var body: some View {
        Canvas { context, canvasSize in
            draw(in: context, size: canvasSize)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// One star in the asterism, in normalised (0..1) coordinates.
    private struct StarSpec {
        let center: CGPoint
        /// Radius as a fraction of the smaller canvas dimension.
        let radius: CGFloat
    }

    /// Asymmetric three-star constellation: one anchor star (top), two smaller companions.
    /// Slight asymmetry gives the mark character, mirrors the app icon.
    private static let stars: [StarSpec] = [
        StarSpec(center: CGPoint(x: 0.52, y: 0.28), radius: 0.30),
        StarSpec(center: CGPoint(x: 0.22, y: 0.74), radius: 0.20),
        StarSpec(center: CGPoint(x: 0.78, y: 0.68), radius: 0.16)
    ]

    private func draw(in context: GraphicsContext, size canvasSize: CGSize) {
        let basis = min(canvasSize.width, canvasSize.height)
        for spec in Self.stars {
            let center = CGPoint(
                x: spec.center.x * canvasSize.width,
                y: spec.center.y * canvasSize.height
            )
            let outerRadius = spec.radius * basis
            let innerRadius = outerRadius * 0.382 // golden ratio for the inner points
            let path = starPath(center: center, outer: outerRadius, inner: innerRadius)
            context.fill(path, with: .color(color))
        }
    }

    private func starPath(center: CGPoint, outer: CGFloat, inner: CGFloat) -> Path {
        var path = Path()
        for i in 0..<10 {
            let angle: Double = -.pi / 2 + Double(i) * .pi / 5
            let r: CGFloat = i.isMultiple(of: 2) ? outer : inner
            let x: CGFloat = center.x + CGFloat(cos(angle)) * r
            let y: CGFloat = center.y + CGFloat(sin(angle)) * r
            let point = CGPoint(x: x, y: y)
            if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }
}

struct AsteraMarkSmall: View {
    var color: Color = AsteraColor.accent
    var body: some View {
        AsteraMark(size: 14, color: color)
    }
}

#Preview {
    VStack(spacing: 24) {
        AsteraMark(size: 96)
        AsteraMark(size: 56)
        AsteraMark(size: 28)
        AsteraMark(size: 14)
    }
    .padding(40)
    .background(AsteraColor.vellum)
}
