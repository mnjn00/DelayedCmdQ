import AppKit
import SwiftUI

/// The circular surface the HUD ring sits on.
///
/// SwiftUI's `glassEffect` renders a frosted material here rather than true Liquid
/// Glass: inside a borderless, fully transparent panel it blurs the backdrop but
/// produces none of the edge refraction or specular rim, so over a light window it
/// reads as a flat grey disc. AppKit's `NSGlassEffectView` is the real thing, and
/// `NSVisualEffectView` with behind-window blending is the closest equivalent on
/// releases that predate Liquid Glass.
struct GlassBackdrop: NSViewRepresentable {
    let diameter: CGFloat
    /// True for the floating overlay. False inside an ordinary opaque window, where
    /// sampling the desktop would punch a hole through the window itself.
    let blendsBehindWindow: Bool
    /// How solid the surface is drawn, from `GlassOpacity`.
    let opacity: Double

    func makeNSView(context: Context) -> NSView {
        let view: NSView

        if #available(macOS 26.0, *) {
            let glass = NSGlassEffectView()
            glass.style = .regular
            glass.cornerRadius = diameter / 2
            view = glass
        } else {
            let vibrancy = NSVisualEffectView()
            vibrancy.material = .hudWindow
            vibrancy.blendingMode = blendsBehindWindow ? .behindWindow : .withinWindow
            vibrancy.state = .active
            vibrancy.wantsLayer = true
            vibrancy.layer?.cornerRadius = diameter / 2
            vibrancy.layer?.masksToBounds = true
            view = vibrancy
        }

        view.alphaValue = opacity
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.alphaValue = opacity

        if #available(macOS 26.0, *), let glass = nsView as? NSGlassEffectView {
            glass.cornerRadius = diameter / 2
            return
        }
        nsView.layer?.cornerRadius = diameter / 2
    }
}

extension View {
    /// Places the receiver on a circular glass coin of the given diameter.
    func glassCoin(
        diameter: CGFloat,
        blendsBehindWindow: Bool,
        opacity: Double
    ) -> some View {
        frame(width: diameter, height: diameter)
            .background(
                GlassBackdrop(
                    diameter: diameter,
                    blendsBehindWindow: blendsBehindWindow,
                    opacity: opacity
                )
                // Scale the shadow with the surface, so a nearly transparent coin
                // does not sit on a shadow that implies a solid object.
                .shadow(color: .black.opacity(0.16 * opacity), radius: 13, x: 0, y: 5)
            )
    }
}
