import AppKit

/// Light/dark override for this app's own windows.
///
/// Setting `NSApp.appearance` scopes the choice to us: the Settings window and the
/// overlay panel follow it, and the rest of the system is untouched.
enum AppearanceMode: String, CaseIterable, Sendable {
    case system
    case light
    case dark

    /// `nil` means "inherit", which is how AppKit spells "follow the system".
    var nsAppearance: NSAppearance? {
        switch self {
        case .system: return nil
        case .light: return NSAppearance(named: .aqua)
        case .dark: return NSAppearance(named: .darkAqua)
        }
    }

    func title(_ strings: Localization) -> String {
        switch self {
        case .system: return strings.appearanceSystem
        case .light: return strings.appearanceLight
        case .dark: return strings.appearanceDark
        }
    }
}
