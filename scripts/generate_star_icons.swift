#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let outputDir = "/tmp/astera-icons"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let vellum = CGColor(red: 0.957, green: 0.925, blue: 0.875, alpha: 1)
let vellumWarm = CGColor(red: 0.949, green: 0.918, blue: 0.863, alpha: 1)
let mulberry = CGColor(red: 0.612, green: 0.290, blue: 0.322, alpha: 1)
let ink = CGColor(red: 0.176, green: 0.129, blue: 0.157, alpha: 1)

let colorSpace = CGColorSpaceCreateDeviceRGB()

func makeContext() -> CGContext {
    CGContext(
        data: nil,
        width: Int(size),
        height: Int(size),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
    )!
}

func paintBackground(_ ctx: CGContext) {
    let colors = [vellum, vellumWarm] as CFArray
    let g = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
}

func write(_ ctx: CGContext, to name: String) {
    guard let image = ctx.makeImage() else { return }
    let url = URL(fileURLWithPath: "\(outputDir)/\(name).png")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("Wrote \(url.path)")
}

/// Sharp-pointed N-star polygon. `points` = number of star points.
func starPath(center: CGPoint, points: Int, outerRadius: CGFloat, innerRadius: CGFloat, startAngle: Double = -.pi / 2) -> CGPath {
    let path = CGMutablePath()
    let total = points * 2
    for i in 0..<total {
        let angle = startAngle + Double(i) * .pi / Double(points)
        let radius = (i % 2 == 0) ? outerRadius : innerRadius
        let x = center.x + CGFloat(cos(angle)) * radius
        let y = center.y + CGFloat(sin(angle)) * radius
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
        else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    return path
}

/// Sparkle-shaped 4-point with curved concave sides (Notion/Linear style).
func sparklePath(center: CGPoint, outerRadius: CGFloat, valleyRadius: CGFloat) -> CGPath {
    let path = CGMutablePath()
    // 4 points: top, right, bottom, left
    let tipAngles: [CGFloat] = [-.pi / 2, 0, .pi / 2, .pi]
    let tips = tipAngles.map { CGPoint(
        x: center.x + cos($0) * outerRadius,
        y: center.y + sin($0) * outerRadius
    )}
    path.move(to: tips[0])
    for i in 0..<4 {
        let from = tips[i]
        let to = tips[(i + 1) % 4]
        // Mid-point pulled toward the center to create concave curve.
        let midAngle = (tipAngles[i] + tipAngles[(i + 1) % 4]) / 2 + (i == 3 ? -.pi : 0)
        let valleyCenter = CGPoint(
            x: center.x + cos(midAngle) * valleyRadius,
            y: center.y + sin(midAngle) * valleyRadius
        )
        // Use quad curve through valleyCenter from current point to next tip.
        _ = from
        path.addQuadCurve(to: to, control: valleyCenter)
    }
    path.closeSubpath()
    return path
}

// MARK: - A. Classic 5-point star

do {
    let ctx = makeContext()
    paintBackground(ctx)
    let center = CGPoint(x: size / 2, y: size / 2)
    ctx.setFillColor(mulberry)
    ctx.addPath(starPath(center: center, points: 5, outerRadius: size * 0.35, innerRadius: size * 0.14))
    ctx.fillPath()
    write(ctx, to: "star-a-5pt-classic")
}

// MARK: - B. Slim sparkle 4-point with curved concave sides

do {
    let ctx = makeContext()
    paintBackground(ctx)
    let center = CGPoint(x: size / 2, y: size / 2)
    ctx.setFillColor(mulberry)
    ctx.addPath(sparklePath(center: center, outerRadius: size * 0.40, valleyRadius: size * 0.05))
    ctx.fillPath()
    write(ctx, to: "star-b-sparkle")
}

// MARK: - C. Elongated 4-point star (slim spikes, more vertical)

do {
    let ctx = makeContext()
    paintBackground(ctx)
    let center = CGPoint(x: size / 2, y: size / 2)
    ctx.setFillColor(mulberry)
    // Use 4-point star polygon with very small inner radius for slim spikes.
    ctx.addPath(starPath(center: center, points: 4, outerRadius: size * 0.40, innerRadius: size * 0.06))
    ctx.fillPath()
    write(ctx, to: "star-c-slim-4pt")
}

// MARK: - D. Constellation: three dots forming a small triangle (asterism)

do {
    let ctx = makeContext()
    paintBackground(ctx)
    let center = CGPoint(x: size / 2, y: size / 2)
    ctx.setFillColor(mulberry)
    let dotRadius = size * 0.06
    let armRadius = size * 0.18
    // Three points at 90°, 210°, 330° (top + lower-left + lower-right)
    let angles: [Double] = [-.pi / 2, .pi * 7 / 6, -.pi / 6]
    for angle in angles {
        let x = center.x + CGFloat(cos(angle)) * armRadius
        let y = center.y + CGFloat(sin(angle)) * armRadius
        ctx.fillEllipse(in: CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
    }
    write(ctx, to: "star-d-constellation")
}

// MARK: - E. Single solid 5-point star, ink not mulberry (more editorial)

do {
    let ctx = makeContext()
    paintBackground(ctx)
    let center = CGPoint(x: size / 2, y: size / 2)
    ctx.setFillColor(ink)
    ctx.addPath(starPath(center: center, points: 5, outerRadius: size * 0.34, innerRadius: size * 0.13))
    ctx.fillPath()
    write(ctx, to: "star-e-5pt-ink")
}

print("\nDone. View at: \(outputDir)")
