import Foundation
import Testing

@testable import DelayedCmdQKit

@Suite("Localization")
struct LocalizationTests {
    private static let all: [(name: String, strings: Localization)] = [
        ("english", .english),
        ("korean", .korean),
        ("japanese", .japanese),
        ("simplifiedChinese", .simplifiedChinese),
    ]

    @Test("Every language defines every string")
    func noBlankStrings() {
        for entry in Self.all {
            for child in Mirror(reflecting: entry.strings).children {
                guard let label = child.label, let value = child.value as? String else { continue }
                #expect(!value.trimmingCharacters(in: .whitespaces).isEmpty,
                        "\(entry.name).\(label) is blank")
            }
        }
    }

    /// A format string missing its specifier renders the wrong text; an extra one
    /// reads uninitialised memory. Both are silent at compile time.
    @Test("Duration formats carry exactly one float specifier")
    func durationFormatsAreWellFormed() {
        for entry in Self.all {
            let format = entry.strings.durationSecondsFormat
            #expect(format.components(separatedBy: "%.1f").count == 2, "\(entry.name)")
            #expect(!format.contains("%@"), "\(entry.name)")
        }
    }

    @Test("Formats that take the duration carry exactly one string specifier")
    func summaryFormatsAreWellFormed() {
        for entry in Self.all {
            for (label, format) in [
                ("holdSummaryFormat", entry.strings.holdSummaryFormat),
                ("menuStatusActiveFormat", entry.strings.menuStatusActiveFormat),
            ] {
                #expect(format.components(separatedBy: "%@").count == 2,
                        "\(entry.name).\(label)")
                #expect(!format.contains("%.1f"), "\(entry.name).\(label)")
            }
        }
    }

    @Test("Substitution produces the duration and drops every specifier")
    func substitutionWorks() {
        for entry in Self.all {
            let duration = entry.strings.duration(1.5)
            #expect(duration.contains("1.5"), "\(entry.name)")

            for rendered in [entry.strings.holdSummary(1.5), entry.strings.menuStatusActive(1.5)] {
                #expect(rendered.contains(duration), "\(entry.name)")
                #expect(!rendered.contains("%"), "\(entry.name)")
            }
        }
    }

    @Test("Languages are actually distinct translations")
    func languagesDiffer() {
        let titles = Self.all.map(\.strings.delayTitle)
        #expect(Set(titles).count == titles.count)
    }

    @Test("Every language mentions the shortcut it is describing")
    func summariesMentionTheShortcut() {
        for entry in Self.all {
            #expect(entry.strings.holdSummaryFormat.contains("⌘Q"), "\(entry.name)")
            #expect(entry.strings.menuStatusActiveFormat.contains("⌘Q"), "\(entry.name)")
        }
    }
}

@Suite("Language selection")
struct AppLanguageTests {
    @Test("A pinned language ignores the system preference")
    func pinnedLanguagesResolveDirectly() {
        #expect(AppLanguage.english.localization == .english)
        #expect(AppLanguage.korean.localization == .korean)
        #expect(AppLanguage.japanese.localization == .japanese)
        #expect(AppLanguage.simplifiedChinese.localization == .simplifiedChinese)
    }

    @Test(
        "System mode picks the first supported preferred language",
        arguments: [
            (["ko-KR", "en-US"], Localization.korean),
            (["ja-JP"], Localization.japanese),
            (["zh-Hans-CN", "en"], Localization.simplifiedChinese),
            (["en-GB", "ko-KR"], Localization.english),
            // Unsupported languages are skipped rather than ending the search.
            (["de-DE", "fr-FR", "ja-JP"], Localization.japanese),
        ]
    )
    func systemModeMatchesPreference(preferred: [String], expected: Localization) {
        #expect(AppLanguage.matchingSystem(preferredLanguages: preferred) == expected)
    }

    @Test("Traditional Chinese falls back to Simplified, not English")
    func traditionalChineseFallsBackToSimplified() {
        #expect(AppLanguage.matchingSystem(preferredLanguages: ["zh-Hant-TW"]) == .simplifiedChinese)
    }

    @Test("An unsupported or empty preference falls back to English")
    func unsupportedFallsBackToEnglish() {
        #expect(AppLanguage.matchingSystem(preferredLanguages: []) == .english)
        #expect(AppLanguage.matchingSystem(preferredLanguages: ["de-DE", "fr"]) == .english)
    }

    @Test("Only the system option lacks an endonym")
    func endonyms() {
        #expect(AppLanguage.system.endonym == nil)
        for language in AppLanguage.allCases where language != .system {
            #expect(language.endonym?.isEmpty == false)
        }
    }
}
