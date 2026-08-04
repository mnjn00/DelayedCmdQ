import SwiftUI

/// Backing surface for the HUD coin.
///
/// On macOS 26 (Tahoe) and later this is real Liquid Glass, so the HUD refracts and
/// picks up specular highlights from whatever is behind it the way system HUDs do.
/// Earlier releases have no such API, and fall back to the vibrancy material that
/// was the native look at the time — the ring geometry is identical either way.
struct GlassCoinBackground: ViewModifier {
    let diameter: CGFloat

    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .frame(width: diameter, height: diameter)
                .glassEffect(.regular, in: Circle())
        } else {
            content
                .frame(width: diameter, height: diameter)
                .background(legacyCoin)
        }
    }

    private var legacyCoin: some View {
        Circle()
            .fill(.regularMaterial)
            .overlay(Circle().strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
            .shadow(color: .black.opacity(0.16), radius: 13, x: 0, y: 5)
    }
}

extension View {
    /// Places the receiver on a circular glass coin of the given diameter.
    func glassCoin(diameter: CGFloat) -> some View {
        modifier(GlassCoinBackground(diameter: diameter))
    }
}
