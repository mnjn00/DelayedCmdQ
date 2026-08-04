import AppKit
import SwiftUI

/// The circular surface the HUD ring sits on.
///
/// SwiftUI's `glassEffect` blends against whatever is behind it *within the same
/// window*. The overlay is a borderless, fully transparent panel, so there is nothing
/// there to sample and the effect collapses into a flat grey disc. AppKit's
/// `NSGlassEffectView` samples what is behind the *window*, which is what a floating
/// HUD needs — and `NSVisualEffectView` does the same on releases that predate
/// Liquid Glass.
struct GlassBackdrop: NSViewRepresentable {
    let diameter: CGFloat
    /// True for the floating overlay. False inside an ordinary opaque window, where
    /// sampling the desktop would punch a hole through the window itself.
    let blendsBehindWindow: Bool

    func makeNSView(context: Context) -> NSView {
        if #available(macOS 26.0, *) {
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

extension View {
    /// Places the receiver on a circular glass coin of the given diameter.
    func glassCoin(diameter: CGFloat, blendsBehindWindow: Bool) -> some View {
        frame(width: diameter, height: diameter)
            .background(
                GlassBackdrop(diameter: diameter, blendsBehindWindow: blendsBehindWindow)
                    .shadow(color: .black.opacity(0.16), radius: 13, x: 0, y: 5)
            )
    }
}
