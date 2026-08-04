import AppKit
import SwiftUI

/// The circular surface the HUD ring sits on.
///
/// SwiftUI's `glassEffect` renders a frosted material inside a borderless
/// transparent panel — it blurs the backdrop but produces no rim, so over a light
/// window it reads as a flat grey disc. AppKit's `NSGlassEffectView` transmits the
/// backdrop instead of dissolving it, which is what a floating HUD wants.
struct CoinBackdrop: NSViewRepresentable {
    let diameter: CGFloat
    let usesGlass: Bool
    /// True for the floating overlay. False inside an ordinary opaque window, where
    /// sampling the desktop would punch a hole through the window itself.
    let blendsBehindWindow: Bool

    func makeNSView(context: Context) -> NSView {
        if usesGlass, #available(macOS 26.0, *) {
            let glass = NSGlassEffectView()
            glass.style = .regular
            glass.cornerRadius = diameter / 2
            return glass
        }

        let vibrancy = NSVisualEffectView()
        vibrancy.material = .hudWindow
        vibrancy.blendingMode = blendsBehindWindow ? .behindWindow : .withinWindow
        vibrancy.state = .active
        vibrancy.wantsLayer = true
        vibrancy.layer?.cornerRadius = diameter / 2
        vibrancy.layer?.masksToBounds = true
        return vibrancy
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if #available(macOS 26.0, *), let glass = nsView as? NSGlassEffectView {
            glass.cornerRadius = diameter / 2
            return
        }
        nsView.layer?.cornerRadius = diameter / 2
    }
}

/// The highlights a real lens has, drawn over the native surface: a rim that
/// brightens where light grazes the edge, a soft sheen up and to the left, and a
/// slightly heavier lip at the bottom.
///
/// `NSGlassEffectView` alone renders flat in a static borderless circle — no rim,
/// no specular. These are deliberately restrained; pushed any further the coin
/// stops reading as glass and starts reading as a pearl.
private struct SpecularSheen: View {
    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            .white.opacity(0.55), .white.opacity(0.10),
                            .white.opacity(0.04), .white.opacity(0.28),
                            .white.opacity(0.55),
                        ],
                        center: .center,
                        angle: .degrees(-45)
                    ),
                    lineWidth: 1.2
                )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white.opacity(0.18), .white.opacity(0.03), .clear],
                        center: UnitPoint(x: 0.32, y: 0.26),
                        startRadius: 0,
                        endRadius: 78
                    )
                )
                .blendMode(.plusLighter)

            Circle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.10)],
                        startPoint: .center,
                        endPoint: .bottom
                    )
                )
        }
        .allowsHitTesting(false)
    }
}

extension View {
    /// Places the receiver on a circular coin of the given diameter.
    func hudCoin(diameter: CGFloat, theme: AppTheme, blendsBehindWindow: Bool) -> some View {
        frame(width: diameter, height: diameter)
            .background(
                CoinBackdrop(
                    diameter: diameter,
                    usesGlass: theme.usesGlass,
                    blendsBehindWindow: blendsBehindWindow
                )
                // Not clipped: masking the representable would break the
                // behind-window sampling. The sheen is already circular.
                .overlay {
                    if theme.usesGlass { SpecularSheen() }
                }
                .shadow(color: .black.opacity(0.16), radius: 13, x: 0, y: 5)
            )
    }
}
