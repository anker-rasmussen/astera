#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let size: CGFloat = 1024
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "AppIcon-1024.png"

let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    print("Failed to create CGContext")
    exit(1)
}

// Slight vellum-to-warm gradient background for depth (still reads as solid vellum at first glance).
let bgColors = [
    CGColor(red: 0.965, green: 0.937, blue: 0.890, alpha: 1),
    CGColor(red: 0.949, green: 0.918, blue: 0.863, alpha: 1)
] as CFArray
let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0, 1])!
context.drawLinearGradient(
    gradient,
    start: CGPoint(x: 0, y: size),
    end: CGPoint(x: size, y: 0),
    options: []
)

// Mulberry aster mark — 8 elongated petals radiating from centre.
let center = CGPoint(x: size / 2, y: size / 2)
let petalLength = size * 0.34
let petalWidth = size * 0.085
let innerGap = size * 0.04 // small gap so petals don't quite reach origin — feels less wagon-wheel
let mulberry = CGColor(red: 0.612, green: 0.290, blue: 0.322, alpha: 1)
let petals = 8

for index in 0..<petals {
    let angle = (Double(index) / Double(petals)) * .pi * 2
    context.saveGState()
    context.translateBy(x: center.x, y: center.y)
    context.rotate(by: CGFloat(angle))
    context.setFillColor(mulberry)
    // Petal extends radially outward along +x from a small inner gap.
    let rect = CGRect(x: innerGap, y: -petalWidth / 2, width: petalLength, height: petalWidth)
    let path = CGPath(roundedRect: rect, cornerWidth: petalWidth / 2, cornerHeight: petalWidth / 2, transform: nil)
    context.addPath(path)
    context.fillPath()
    context.restoreGState()
}

guard let image = context.makeImage() else {
    print("Failed to make CGImage")
    exit(1)
}

let url = URL(fileURLWithPath: outputPath)
guard let dest = CGImageDestinationCreateWithURL(
    url as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    print("Failed to create image destination")
    exit(1)
}
CGImageDestinationAddImage(dest, image, nil)
if CGImageDestinationFinalize(dest) {
    print("Wrote \(outputPath)")
} else {
    print("Failed to finalize image")
    exit(1)
}
