#!/usr/bin/env swift
//
// Renders the README assets: an animated GIF of the ring filling, plus light and
// dark stills. Usage: swift Scripts/MakeDemo.swift <output-directory>
//

import AppKit
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

let canvas: CGFloat = 152
let coin: CGFloat = 108
let ring: CGFloat = 76
let lineWidth: CGFloat = 3
let iconSize: CGFloat = 30

struct RingHUD: View {
    let progress: Double
    let icon: NSImage?
    var opacity: Double = 1
    var scale: CGFloat = 1

    var body: some View {
        ZStack {
            Circle()
                .fill(.regularMaterial)
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
                .frame(width: coin, height: coin)
                .shadow(color: .black.opacity(0.16), radius: 13, x: 0, y: 5)

            ZStack {
                Circle().stroke(Color.primary.opacity(0.12), lineWidth: lineWidth)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: ring, height: ring)

            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: iconSize, height: iconSize)
                    .opacity(0.9)
            }
        }
        .frame(width: canvas, height: canvas)
        .scaleEffect(scale)
        .opacity(opacity)
    }
}

func desktop(dark: Bool) -> LinearGradient {
    LinearGradient(
        colors: dark
            ? [Color(red: 0.11, green: 0.13, blue: 0.19), Color(red: 0.04, green: 0.05, blue: 0.08)]
            : [Color(red: 0.97, green: 0.96, blue: 0.94), Color(red: 0.82, green: 0.85, blue: 0.90)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct Frame: View {
    let progress: Double
    let icon: NSImage?
    let opacity: Double
    let scale: CGFloat
    let dark: Bool

    var body: some View {
        ZStack {
            desktop(dark: dark)
            RingHUD(progress: progress, icon: icon, opacity: opacity, scale: scale)
        }
        .frame(width: 420, height: 236)
        .environment(\.colorScheme, dark ? .dark : .light)
    }
}

struct Still: View {
    let steps: [Double]
    let icon: NSImage?
    let dark: Bool

    var body: some View {
        ZStack {
            desktop(dark: dark)
            HStack(spacing: 4) {
                ForEach(steps, id: \.self) { RingHUD(progress: $0, icon: icon) }
            }
        }
        .frame(width: canvas * CGFloat(steps.count) + 4 * CGFloat(steps.count - 1), height: 176)
        .environment(\.colorScheme, dark ? .dark : .light)
    }
}

@MainActor
func cgImage(_ view: some View, scale: CGFloat) -> CGImage? {
    let renderer = ImageRenderer(content: view)
    renderer.scale = scale
    return renderer.cgImage
}

@MainActor
func writePNG(_ view: some View, to url: URL) throws {
    guard let image = cgImage(view, scale: 2),
          let destination = CGImageDestinationCreateWithURL(
              url as CFURL, UTType.png.identifier as CFString, 1, nil
          )
    else { throw CocoaError(.fileWriteUnknown) }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
}

/// Ease-out so the fill reads as a deliberate hold rather than a linear meter.
func easeOut(_ t: Double) -> Double { 1 - pow(1 - t, 1.6) }

@MainActor
func writeGIF(icon: NSImage?, dark: Bool, to url: URL) throws {
    let fillFrames = 30
    let holdFrames = 8
    let fadeFrames = 6
    let restFrames = 6
    let total = fillFrames + holdFrames + fadeFrames + restFrames

    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL, UTType.gif.identifier as CFString, total, nil
    ) else { throw CocoaError(.fileWriteUnknown) }

    CGImageDestinationSetProperties(destination, [
        kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: 0],
    ] as CFDictionary)

    for index in 0..<total {
        let progress: Double
        var opacity: Double = 1
        var scale: CGFloat = 1

        switch index {
        case 0..<fillFrames:
            progress = Double(index) / Double(fillFrames - 1)
        case fillFrames..<(fillFrames + holdFrames):
            progress = 1
        case (fillFrames + holdFrames)..<(fillFrames + holdFrames + fadeFrames):
            let t = Double(index - fillFrames - holdFrames) / Double(fadeFrames)
            progress = 1
            opacity = 1 - t
            scale = 1 + 0.08 * t
        default:
            progress = 0
            opacity = 0
        }

        let frame = Frame(
            progress: progress,
            icon: icon,
            opacity: opacity,
            scale: scale,
            dark: dark
        )
        guard let image = cgImage(frame, scale: 2) else { throw CocoaError(.fileWriteUnknown) }

        let delay = index < fillFrames ? 0.04 : 0.06
        CGImageDestinationAddImage(destination, image, [
            kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFUnclampedDelayTime: delay],
        ] as CFDictionary)
    }

    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
}

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

// A real app icon in the middle is what the HUD actually shows.
let genericIcon = NSWorkspace.shared.icon(forFile: "/Applications/Safari.app")
let steps: [Double] = [0, 0.25, 0.5, 0.75, 1.0]

try MainActor.assumeIsolated {
    for progress in [(true, "demo-dark.gif"), (false, "demo-light.gif")] {
        try writeGIF(
            icon: genericIcon,
            dark: progress.0,
            to: outputDirectory.appendingPathComponent(progress.1)
        )
    }
    try writePNG(
        Still(steps: steps, icon: genericIcon, dark: true),
        to: outputDirectory.appendingPathComponent("ring-dark.png")
    )
    try writePNG(
        Still(steps: steps, icon: genericIcon, dark: false),
        to: outputDirectory.appendingPathComponent("ring-light.png")
    )
}

print("wrote assets to \(outputDirectory.path)")
