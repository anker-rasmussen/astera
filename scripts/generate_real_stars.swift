#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let outputDir = "/tmp/astera-icons"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Warmer blush palette
let vellum = CGColor(red: 0.973, green: 0.890, blue: 0.847, alpha: 1)
let vellumWarm = CGColor(red: 0.957, green: 0.855, blue: 0.808, alpha: 1)
let mulberry = CGColor(red: 0.690, green: 0.286, blue: 0.337, alpha: 1)
let ink = CGColor(red: 0.235, green: 0.137, blue: 0.165, alpha: 1)

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

/// 5-point sharp star centred on `c` with outer radius `outer`.
func star5(at c: CGPoint, outer: CGFloat, rotation: Double = 0) -> CGPath {
    let path = CGMutablePath()
    let inner = outer * 0.382  // golden ratio for a clean classic star
    let startAngle = -.pi / 2 + rotation
    for i in 0..<10 {
        let angle = startAngle + Double(i) * .pi / 5
        let r = (i % 2 == 0) ? outer : inner
        let x = c.x + CGFloat(cos(angle)) * r
        let y = c.y + CGFloat(sin(angle)) * r
        if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
        else { path.addLine(to: CGPoint(x: x, y: y)) }
    }
    path.closeSubpath()
    return path
}

// MARK: - 1. Three stars in an asterism (varying sizes, mulberry)

do {
    let ctx = makeContext()
    paintBackground(ctx)
    ctx.setFillColor(mulberry)

    let center = CGPoint(x: size / 2, y: size / 2)
    // Upper-left brightest, lower-right mid, top-right smaller. Like a real asterism.
    let stars: [(CGPoint, CGFloat, Double)] = [
        (CGPoint(x: center.x - size * 0.16, y: center.y - size * 0.12), size * 0.16, 0),  // big
        (CGPoint(x: center.x + size * 0.18, y: center.y + size * 0.10), size * 0.11, 0.12),  // mid
        (CGPoint(x: center.x + size * 0.04, y: center.y - size * 0.20), size * 0.085, -0.08)  // small
    ]
    for (pos, outer, rot) in stars {
        ctx.addPath(star5(at: pos, outer: outer, rotation: rot))
        ctx.fillPath()
    }
    write(ctx, to: "real-1-asterism-three")
}

// MARK: - 2. Single large 5-point star, classic, mulberry

do {
    let ctx = makeContext()
    paintBackground(ctx)
    ctx.setFillColor(mulberry)
    let center = CGPoint(x: size / 2, y: size / 2)
    ctx.addPath(star5(at: center, outer: size * 0.36))
    ctx.fillPath()
    write(ctx, to: "real-2-single-large")
}

// MARK: - 3. Two stars (big + small) — bright star with a small companion

do {
    let ctx = makeContext()
    paintBackground(ctx)
    ctx.setFillColor(mulberry)
    let center = CGPoint(x: size / 2, y: size / 2)
    ctx.addPath(star5(at: CGPoint(x: center.x - size * 0.08, y: center.y), outer: size * 0.22))
    ctx.fillPath()
    ctx.addPath(star5(at: CGPoint(x: center.x + size * 0.22, y: center.y - size * 0.18), outer: size * 0.09, rotation: 0.15))
    ctx.fillPath()
    write(ctx, to: "real-3-pair")
}

// MARK: - 4. Single star, ink — more publication-mark feel

do {
    let ctx = makeContext()
    paintBackground(ctx)
    ctx.setFillColor(ink)
    let center = CGPoint(x: size / 2, y: size / 2)
    ctx.addPath(star5(at: center, outer: size * 0.34))
    ctx.fillPath()
    write(ctx, to: "real-4-single-ink")
}

// MARK: - 5. Big star with sparkle accents (asterism flourish)

do {
    let ctx = makeContext()
    paintBackground(ctx)
    let center = CGPoint(x: size / 2, y: size / 2)
    ctx.setFillColor(mulberry)
    ctx.addPath(star5(at: center, outer: size * 0.28))
    ctx.fillPath()
    // Small sparkle accents at corners
    ctx.setFillColor(mulberry)
    ctx.addPath(star5(at: CGPoint(x: center.x + size * 0.28, y: center.y - size * 0.26), outer: size * 0.05, rotation: 0.2))
    ctx.fillPath()
    ctx.addPath(star5(at: CGPoint(x: center.x - size * 0.26, y: center.y + size * 0.26), outer: size * 0.04, rotation: -0.1))
    ctx.fillPath()
    write(ctx, to: "real-5-flourish")
}

print("\nDone. View at: \(outputDir)")
