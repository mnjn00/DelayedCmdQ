import AppKit
import Foundation

/// Draws the menu bar glyph: the same outlined ring the HUD uses, so the two read
/// as one idea. Rendered as a template image, which means only alpha matters and
/// the system handles light/dark and menu bar tinting.
enum StatusIcon {
    private static let size = NSSize(width: 18, height: 18)

    static func make(paused: Bool) -> NSImage {
        let image = NSImage(size: size, flipped: false) { rect in
            let lineWidth: CGFloat = 1.5
            let radius = (min(rect.width, rect.height) - lineWidth) / 2 - 2
            let center = NSPoint(x: rect.midX, y: rect.midY)

            let track = NSBezierPath()
            track.appendArc(withCenter: center, radius: radius, startAngle: 0, endAngle: 360)
            track.lineWidth = lineWidth
            NSColor.black.withAlphaComponent(paused ? 0.32 : 0.28).setStroke()
            track.stroke()

            guard !paused else { return true }

            let fill = NSBezierPath()
            // Three quarters, starting at twelve o'clock and running clockwise.
            fill.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: 90,
                endAngle: -180,
                clockwise: true
            )
            fill.lineWidth = lineWidth
            fill.lineCapStyle = .round
            NSColor.black.setStroke()
            fill.stroke()

            return true
        }
        image.isTemplate = true
        return image
    }
}
