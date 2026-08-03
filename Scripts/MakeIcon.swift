#!/usr/bin/env swift
//
// Renders AppIcon.icns: the same three-quarter ring used in the menu bar and HUD.
// Usage: swift Scripts/MakeIcon.swift <output-directory>
//

import AppKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 2 else {
    FileHandle.standardError.write("usage: MakeIcon.swift <output-directory>\n".data(using: .utf8)!)
    exit(1)
}

let outputDirectory = URL(fileURLWithPath: arguments[1], isDirectory: true)
let iconset = outputDirectory.appendingPathComponent("AppIcon.iconset", isDirectory: true)

try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func drawIcon(size: CGFloat) -> NSBitmapImageRep {
    let pixels = Int(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    // macOS icon artwork sits in a squircle inset from the canvas edge.
    let margin = size * 0.086
    let plate = NSRect(x: margin, y: margin, width: size - margin * 2, height: size - margin * 2)
    let cornerRadius = plate.width * 0.2237

    let platePath = NSBezierPath(
        roundedRect: plate,
        xRadius: cornerRadius,
        yRadius: cornerRadius
    )
    let gradient = NSGradient(
        starting: NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.19, alpha: 1),
        ending: NSColor(calibratedRed: 0.07, green: 0.07, blue: 0.08, alpha: 1)
    )!
    gradient.draw(in: platePath, angle: -90)

    let center = NSPoint(x: plate.midX, y: plate.midY)
    let lineWidth = plate.width * 0.062
    let radius = plate.width * 0.29

    let track = NSBezierPath()
    track.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
    track.lineWidth = lineWidth
    NSColor(calibratedWhite: 1, alpha: 0.16).setStroke()
    track.stroke()

    let fill = NSBezierPath()
    fill.appendArc(
        withCenter: center,
        radius: radius,
        startAngle: 90,
        endAngle: -180,
        clockwise: true
    )
    fill.lineWidth = lineWidth
    fill.lineCapStyle = .round
    NSColor(calibratedWhite: 1, alpha: 0.96).setStroke()
    fill.stroke()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let variants: [(name: String, size: CGFloat)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for variant in variants {
    let rep = drawIcon(size: variant.size)
    guard let data = rep.representation(using: .png, properties: [:]) else {
        FileHandle.standardError.write("failed to encode \(variant.name)\n".data(using: .utf8)!)
        exit(1)
    }
    try data.write(to: iconset.appendingPathComponent("\(variant.name).png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = [
    "--convert", "icns",
    "--output", outputDirectory.appendingPathComponent("AppIcon.icns").path,
    iconset.path,
]
try iconutil.run()
iconutil.waitUntilExit()

try? FileManager.default.removeItem(at: iconset)
exit(iconutil.terminationStatus)
