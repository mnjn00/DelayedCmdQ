import Foundation
import Testing

@testable import DelayedCmdQKit

@Suite("Settings persistence")
@MainActor
struct AppSettingsTests {
    private func makeDefaults(_ name: String) -> UserDefaults {
        let suite = "DelayedCmdQTests.\(name).\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test("A fresh install uses the documented defaults")
    func usesDefaults() {
        let settings = AppSettings(defaults: makeDefaults("fresh"))
        #expect(settings.holdDuration == HoldDuration.default)
        #expect(settings.isPaused == false)
        #expect(settings.showsApplicationIcon == true)
        #expect(settings.allowsContinuousQuit == false)
        #expect(settings.appearance == .system)
        #expect(settings.language == .system)
        #expect(settings.glassOpacity == GlassOpacity.default)
    }

    @Test("Changes round-trip through UserDefaults")
    func persistsChanges() {
        let defaults = makeDefaults("roundtrip")

        let settings = AppSettings(defaults: defaults)
        settings.holdDuration = 2.5
        settings.isPaused = true
        settings.showsApplicationIcon = false
        settings.allowsContinuousQuit = true
        settings.appearance = .dark
        settings.language = .japanese
        settings.glassOpacity = 0.5

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.holdDuration == 2.5)
        #expect(reloaded.isPaused == true)
        #expect(reloaded.showsApplicationIcon == false)
        #expect(reloaded.allowsContinuousQuit == true)
        #expect(reloaded.appearance == .dark)
        #expect(reloaded.language == .japanese)
        #expect(reloaded.glassOpacity == 0.5)
    }

    @Test("An unrecognised stored enum falls back instead of bricking the preference")
    func repairsUnknownEnumValues() {
        let defaults = makeDefaults("unknown-enum")
        defaults.set("neon", forKey: AppSettings.Key.appearance)
        defaults.set("klingon", forKey: AppSettings.Key.language)

        let settings = AppSettings(defaults: defaults)
        #expect(settings.appearance == .system)
        #expect(settings.language == .system)
    }

    @Test("Changing the language swaps the strings the UI reads")
    func languageDrivesStrings() {
        let settings = AppSettings(defaults: makeDefaults("strings"))

        settings.language = .korean
        #expect(settings.strings == .korean)

        settings.language = .simplifiedChinese
        #expect(settings.strings == .simplifiedChinese)
    }

    @Test("An out-of-range stored value is repaired on load")
    func repairsStoredValue() {
        let defaults = makeDefaults("repair")
        defaults.set(999.0, forKey: AppSettings.Key.holdDuration)

        let settings = AppSettings(defaults: defaults)
        #expect(settings.holdDuration == HoldDuration.range.upperBound)
    }

    @Test("Assigning an out-of-range value clamps it")
    func clampsAssignment() {
        let settings = AppSettings(defaults: makeDefaults("clamp"))

        settings.holdDuration = 100
        #expect(settings.holdDuration == HoldDuration.range.upperBound)

        settings.holdDuration = 0
        #expect(settings.holdDuration == HoldDuration.range.lowerBound)
    }

    @Test("A clamped assignment persists the clamped value, not the raw one")
    func persistsClampedValue() {
        let defaults = makeDefaults("clamped-persist")

        let settings = AppSettings(defaults: defaults)
        settings.holdDuration = 100

        let reloaded = AppSettings(defaults: defaults)
        #expect(reloaded.holdDuration == HoldDuration.range.upperBound)
    }
}
