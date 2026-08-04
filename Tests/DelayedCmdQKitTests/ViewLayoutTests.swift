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

    @Test("The HUD lays out at its documented canvas size")
    func hudLaysOut() {
        for progress in [0.0, 0.5, 1.0] {
            let view = NSHostingView(rootView: RingHUD(progress: progress, icon: nil))
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

    @Test("Settings lays out under a forced light or dark appearance")
    func settingsLaysOutInBothAppearances() {
        for appearanceName in [NSAppearance.Name.aqua, .darkAqua] {
            let settings = makeSettings(appearanceName.rawValue)

            let view = NSHostingView(
                rootView: SettingsView(
                    settings: settings,
                    authorization: AccessibilityAuthorization(),
                    loginItem: LoginItem()
                )
            )
            view.appearance = NSAppearance(named: appearanceName)
            view.layoutSubtreeIfNeeded()

            #expect(view.fittingSize.width == 380)
            #expect(view.fittingSize.height > 400)
        }
    }
}

@Suite("Appearance mode")
struct AppearanceModeTests {
    @Test("System means inherit, so it must not force an appearance")
    func systemInherits() {
        #expect(AppearanceMode.system.nsAppearance == nil)
    }

    @Test("Light and dark map to the matching AppKit appearances")
    func explicitModesMap() {
        #expect(AppearanceMode.light.nsAppearance?.name == .aqua)
        #expect(AppearanceMode.dark.nsAppearance?.name == .darkAqua)
    }

    @Test("Every mode has a title in every language")
    func titlesExist() {
        let languages: [Localization] = [.english, .korean, .japanese, .simplifiedChinese]
        for strings in languages {
            let titles = AppearanceMode.allCases.map { $0.title(strings) }
            #expect(titles.allSatisfy { !$0.isEmpty })
            #expect(Set(titles).count == titles.count)
        }
    }
}
