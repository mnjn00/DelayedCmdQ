import Foundation

/// Every piece of user-facing text, as a value.
///
/// The app ships its strings in code rather than in `.lproj` bundles because the
/// language is a user preference that has to take effect immediately. Swapping
/// `Bundle.main` at runtime is the usual trick for that and it is fragile; a plain
/// value is switchable, testable, and exhaustive at compile time — a new field
/// cannot be forgotten in one of the four languages.
struct Localization: Sendable, Equatable {
    // Menu bar
    let menuStatusPermissionRequired: String
    let menuStatusPaused: String
    let menuStatusActiveFormat: String
    let menuOpenAccessibilitySettings: String
    let menuPause: String
    let menuSettings: String
    let menuQuit: String
    let menuTooltipActive: String
    let menuTooltipInactive: String

    // Standard menus, reachable by key equivalent while Settings has focus
    let menuEdit: String
    let menuUndo: String
    let menuCut: String
    let menuCopy: String
    let menuPaste: String
    let menuSelectAll: String
    let menuWindow: String
    let menuClose: String

    // Settings
    let holdSummaryFormat: String
    let durationSecondsFormat: String
    let previewHint: String
    let delayTitle: String
    let continuousQuitTitle: String
    let continuousQuitSubtitle: String
    let pauseTitle: String
    let pauseSubtitle: String
    let launchAtLoginTitle: String
    let showAppIconTitle: String
    let showAppIconSubtitle: String
    let appearanceTitle: String
    let appearanceSystem: String
    let appearanceLight: String
    let appearanceDark: String
    let languageTitle: String
    let languageSystem: String

    // Permission
    let accessibilityGranted: String
    let accessibilityRequired: String
    let openSystemSettings: String
    let eventTapFailure: String
}

extension Localization {
    /// Formats a hold duration, e.g. `1.0s` or `1.0초`.
    func duration(_ seconds: TimeInterval) -> String {
        String(format: durationSecondsFormat, seconds)
    }

    /// One-line explanation under the ring preview in Settings.
    func holdSummary(_ seconds: TimeInterval) -> String {
        String(format: holdSummaryFormat, duration(seconds))
    }

    /// Menu bar status line while the app is armed.
    func menuStatusActive(_ seconds: TimeInterval) -> String {
        String(format: menuStatusActiveFormat, duration(seconds))
    }
}
