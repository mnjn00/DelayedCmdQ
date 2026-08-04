import AppKit
import Foundation
import SwiftUI
import Testing

@testable import DelayedCmdQKit

/// Layout smoke tests.
///
/// These build the real view hierarchies through `NSHostingView`, which is what
/// catches an unsatisfiable layout or a crash inside an availability-gated branch —
/// on macOS 26 that includes the Liquid Glass path in `GlassCoinBackground`.
@Suite("View layout")
@MainActor
struct ViewLayoutTests {
    private func makeSettings(_ name: String) -> AppSettings {
        let suite = "DelayedCmdQTests.layout.\(name).\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return AppSettings(defaults: defaults)
    }

    @Test("The HUD lays out at its documented canvas size in every theme")
    func hudLaysOut() {
        for theme in AppTheme.allCases {
            let view = NSHostingView(
                rootView: RingHUD(progress: 0.5, icon: nil, theme: theme)
            )
            view.layoutSubtreeIfNeeded()

            #expect(view.fittingSize.width == RingMetrics.canvas)
            #expect(view.fittingSize.height == RingMetrics.canvas)
        }
    }

    @Test("The HUD lays out the same with an icon in the middle")
    func hudLaysOutWithIcon() {
        let icon = NSWorkspace.shared.icon(for: .applicationBundle)
        let view = NSHostingView(rootView: RingHUD(progress: 0.4, icon: icon))
        view.layoutSubtreeIfNeeded()

        #expect(view.fittingSize.width == RingMetrics.canvas)
        #expect(view.fittingSize.height == RingMetrics.canvas)
    }

    @Test("Settings builds and lays out in every language", arguments: AppLanguage.allCases)
    func settingsLaysOut(language: AppLanguage) {
        let settings = makeSettings(language.rawValue)
        settings.language = language

        let view = NSHostingView(
            rootView: SettingsView(
                settings: settings,
                authorization: AccessibilityAuthorization(),
                loginItem: LoginItem()
            )
        )
        view.layoutSubtreeIfNeeded()

        // The window is a fixed width; only the height is content-driven, and the
        // longer CJK subtitles must not collapse or overflow it.
        #expect(view.fittingSize.width == 380)
        #expect(view.fittingSize.height > 400)
        #expect(view.fittingSize.height < 900)
    }

    @Test("Settings lays out under every theme")
    func settingsLaysOutInEveryTheme() {
        for theme in AppTheme.allCases {
            let settings = makeSettings(theme.rawValue)
            settings.theme = theme

            let view = NSHostingView(
                rootView: SettingsView(
                    settings: settings,
                    authorization: AccessibilityAuthorization(),
                    loginItem: LoginItem()
                )
            )
            view.appearance = theme.nsAppearance ?? NSAppearance(named: .darkAqua)
            view.layoutSubtreeIfNeeded()

            #expect(view.fittingSize.width == 380)
            #expect(view.fittingSize.height > 400)
        }
    }
}

@Suite("Theme")
struct AppThemeTests {
    @Test("Liquid follows the system, so it must not force an appearance")
    func liquidInherits() {
        #expect(AppTheme.liquid.nsAppearance == nil)
    }

    @Test("Light and dark map to the matching AppKit appearances")
    func explicitThemesMap() {
        #expect(AppTheme.light.nsAppearance?.name == .aqua)
        #expect(AppTheme.dark.nsAppearance?.name == .darkAqua)
    }

    /// Glass is translucent and takes its tone from the backdrop, so it belongs to
    /// the one theme that does not pin an appearance.
    @Test("Only the Liquid theme draws glass")
    func onlyLiquidUsesGlass() {
        #expect(AppTheme.liquid.usesGlass)
        #expect(!AppTheme.light.usesGlass)
        #expect(!AppTheme.dark.usesGlass)
    }

    @Test("Every theme has a distinct title in every language")
    func titlesExist() {
        let languages: [Localization] = [.english, .korean, .japanese, .simplifiedChinese]
        for strings in languages {
            let titles = AppTheme.allCases.map { $0.title(strings) }
            #expect(titles.allSatisfy { !$0.isEmpty })
            #expect(Set(titles).count == titles.count)
        }
    }

    @Test("There are exactly three themes")
    func threeThemes() {
        #expect(AppTheme.allCases.count == 3)
    }
}
