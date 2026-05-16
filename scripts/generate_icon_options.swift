#!/usr/bin/env swift

import Foundation
import CoreGraphics
import CoreText
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let outputDir = "/tmp/astera-icons"
try? FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let vellum = CGColor(red: 0.957, green: 0.925, blue: 0.875, alpha: 1)
let vellumWarm = CGColor(red: 0.949, green: 0.918, blue: 0.863, alpha: 1)
let mulberry = CGColor(red: 0.612, green: 0.290, blue: 0.322, alpha: 1)
let mulberryDeep = CGColor(red: 0.475, green: 0.200, blue: 0.235, alpha: 1)
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

func paintBackground(_ ctx: CGContext, gradient: Bool = true) {
    if gradient {
        let colors = [vellum, vellumWarm] as CFArray
        let g = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!
        ctx.drawLinearGradient(g, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    } else {
        ctx.setFillColor(vellum)
        ctx.fill(CGRect(x: 0, y: 0, width: size, height: size))
    }
}

func write(_ ctx: CGContext, to name: String) {
    guard let image = ctx.makeImage() else { return }
    let url = URL(fileURLWithPath: "\(outputDir)/\(name).png")
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
    print("Wrote \(url.path)")
}

func drawCenteredText(_ ctx: CGContext, text: String, fontName: String, fontSize: CGFloat, color: CGColor, yOffset: CGFloat = 0) {
    let font = CTFontCreateWithName(fontName as CFString, fontSize, nil)
    let attrs: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: color
    ]
    let attributed = CFAttributedStringCreate(nil, text as CFString, attrs as CFDictionary)!
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    let x = (size - bounds.width) / 2 - bounds.origin.x
    let y = (size - bounds.height) / 2 - bounds.origin.y + yOffset
    ctx.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, ctx)
}

// MARK: - Option A: italic serif lowercase "a"

do {
    let ctx = makeContext()
    paintBackground(ctx)
    drawCenteredText(ctx, text: "a", fontName: "Baskerville-BoldItalic", fontSize: 780, color: mulberry, yOffset: -40)
    write(ctx, to: "option-a-lowercase-a")
}

// MARK: - Option B: italic serif uppercase "A."

do {
    let ctx = makeContext()
    paintBackground(ctx)
    drawCenteredText(ctx, text: "A.", fontName: "Baskerville-SemiBoldItalic", fontSize: 640, color: mulberry, yOffset: -30)
    write(ctx, to: "option-b-uppercase-A-period")
}

// MARK: - Option C: refined aster with 14 thin organic petals

do {
    let ctx = makeContext()
    paintBackground(ctx)
    let center = CGPoint(x: size / 2, y: size / 2)
    let baseLength = size * 0.36
    let petalWidth = size * 0.055
    let innerGap = size * 0.05
    let petals = 14
    ctx.setFillColor(mulberry)
    for index in 0..<petals {
        let angle = (Double(index) / Double(petals)) * .pi * 2
        let lengthMul: CGFloat = index.isMultiple(of: 2) ? 1.0 : 0.78  // alternating long/short for organic feel
        let length = baseLength * lengthMul
        ctx.saveGState()
        ctx.translateBy(x: center.x, y: center.y)
        ctx.rotate(by: CGFloat(angle))
        let rect = CGRect(x: innerGap, y: -petalWidth / 2, width: length, height: petalWidth)
        let path = CGPath(roundedRect: rect, cornerWidth: petalWidth / 2, cornerHeight: petalWidth / 2, transform: nil)
        ctx.addPath(path)
        ctx.fillPath()
        ctx.restoreGState()
    }
    // small mulberry centre dot
    let dotRadius = size * 0.025
    ctx.fillEllipse(in: CGRect(x: center.x - dotRadius, y: center.y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
    write(ctx, to: "option-c-organic-aster")
}

// MARK: - Option D: colophon — italic "A" with hairline rule beneath

do {
    let ctx = makeContext()
    paintBackground(ctx)
    drawCenteredText(ctx, text: "A", fontName: "Baskerville-SemiBoldItalic", fontSize: 560, color: ink, yOffset: 30)
    // Hairline rule beneath
    let ruleWidth = size * 0.30
    let ruleHeight: CGFloat = 8
    let ruleY = size * 0.30
    ctx.setFillColor(mulberry)
    let ruleRect = CGRect(x: (size - ruleWidth) / 2, y: ruleY, width: ruleWidth, height: ruleHeight)
    ctx.addPath(CGPath(roundedRect: ruleRect, cornerWidth: ruleHeight / 2, cornerHeight: ruleHeight / 2, transform: nil))
    ctx.fillPath()
    write(ctx, to: "option-d-colophon-A")
}

print("\nDone. View at: \(outputDir)")
