import SwiftUI

/// The Astera mark: a 5-point star drawn in SwiftUI Canvas. Used as the brand ornament
/// in chapter headers, on the welcome screen, and as a subtle accent throughout the app.
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

    private func draw(in context: GraphicsContext, size canvasSize: CGSize) {
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let outerRadius = min(canvasSize.width, canvasSize.height) * 0.48
        let innerRadius = outerRadius * 0.382

        var path = Path()
        for i in 0..<10 {
            let angle: Double = -.pi / 2 + Double(i) * .pi / 5
            let r: CGFloat = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let x: CGFloat = center.x + CGFloat(cos(angle)) * r
            let y: CGFloat = center.y + CGFloat(sin(angle)) * r
            let point = CGPoint(x: x, y: y)
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        context.fill(path, with: .color(color))
    }
}

struct AsteraMarkSmall: View {
    var color: Color = AsteraColor.accent
    var body: some View {
        AsteraMark(size: 12, color: color)
    }
}

#Preview {
    VStack(spacing: 24) {
        AsteraMark(size: 80)
        AsteraMark(size: 40)
        AsteraMark(size: 20)
    }
    .padding(40)
    .background(AsteraColor.vellum)
}
