import AppKit
import SwiftUI

/// The HUD: an outline-only circle that fills clockwise from twelve o'clock.
struct ProgressRingView: View {
    @ObservedObject var model: OverlayModel

    var body: some View {
        RingHUD(
            progress: model.progress,
            icon: model.icon,
            theme: model.theme
        )
            .scaleEffect(model.isVisible ? 1 : RingMetrics.hiddenScale)
            .opacity(model.isVisible ? 1 : 0)
            .frame(width: RingMetrics.canvas, height: RingMetrics.canvas)
    }
}

/// Metrics kept in one place so the HUD, the settings preview and the panel size
/// stay in agreement.
enum RingMetrics {
    static let canvas: CGFloat = 152
    static let coin: CGFloat = 108
    static let ring: CGFloat = 76
    static let lineWidth: CGFloat = 3
    static let icon: CGFloat = 30
    static let hiddenScale: CGFloat = 0.88

    static let appearAnimation: Animation = .spring(response: 0.3, dampingFraction: 0.82)
    static let disappearAnimation: Animation = .easeOut(duration: 0.18)
    static let disappearDuration: TimeInterval = 0.2
}

/// Ring and icon only, with no surface of its own.
struct RingFace: View {
    let progress: Double
    let icon: NSImage?

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: RingMetrics.lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    Color.primary,
                    style: StrokeStyle(lineWidth: RingMetrics.lineWidth, lineCap: .round)
                )
                // SwiftUI trims clockwise from three o'clock; rotate so the fill
                // starts at the top the way a clock face reads.
                .rotationEffect(.degrees(-90))

            if let icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: RingMetrics.icon, height: RingMetrics.icon)
                    .opacity(0.9)
            }
        }
        .frame(width: RingMetrics.ring, height: RingMetrics.ring)
    }
}

struct RingHUD: View {
    let progress: Double
    let icon: NSImage?
    /// The floating overlay samples the desktop; the Settings preview must not.
    var blendsBehindWindow: Bool = true
    var theme: AppTheme = .liquid

    var body: some View {
        RingFace(progress: progress, icon: icon)
            .hudCoin(
                diameter: RingMetrics.coin,
                theme: theme,
                blendsBehindWindow: blendsBehindWindow
            )
            .frame(width: RingMetrics.canvas, height: RingMetrics.canvas)
            .accessibilityHidden(true)
    }
}
