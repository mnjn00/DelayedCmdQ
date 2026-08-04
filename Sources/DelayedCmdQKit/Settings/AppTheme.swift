import AppKit

/// The HUD's look. One control, because the surface and the light/dark choice are
/// the same decision: Liquid Glass is translucent and takes its tone from whatever
/// is behind it, so pinning it light or dark would defeat the point.
enum AppTheme: String, CaseIterable, Sendable {
    /// Liquid Glass, following the system's light/dark setting.
    case liquid
    /// A solid light surface.
    case light
    /// A solid dark surface.
    case dark

    /// `nil` means "inherit", which is how AppKit spells "follow the system".
    var nsAppearance: NSAppearance? {
        switch self {
        case .liquid: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    /// Only the Liquid theme draws the glass surface; the other two are opaque
    /// enough that glass would read as noise.
    var usesGlass: Bool { self == .liquid }

    func title(_ strings: Localization) -> String {
        switch self {
        case .liquid: return strings.themeLiquid
        case .light: return strings.themeLight
        case .dark: return strings.themeDark
        }
    }
}
