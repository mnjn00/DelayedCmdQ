import Foundation

/// UI language, either following the system or pinned by the user.
enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case english
    case korean
    case japanese
    case simplifiedChinese

    /// Shown in its own language, the way macOS lists languages.
    var endonym: String? {
        switch self {
        case .system: return nil
        case .english: return "English"
        case .korean: return "한국어"
        case .japanese: return "日本語"
        case .simplifiedChinese: return "简体中文"
        }
    }

    var localization: Localization {
        switch self {
        case .system: return Self.matchingSystem()
        case .english: return .english
        case .korean: return .korean
        case .japanese: return .japanese
        case .simplifiedChinese: return .simplifiedChinese
        }
    }

    /// First supported language in the user's preferred order, else English.
    ///
    /// Traditional Chinese falls back to Simplified rather than to English, since it
    /// is far closer to what a `zh-Hant` reader expects.
    static func matchingSystem(
        preferredLanguages: [String] = Locale.preferredLanguages
    ) -> Localization {
        for identifier in preferredLanguages {
            switch Locale(identifier: identifier).language.languageCode?.identifier {
            case "ko": return .korean
            case "ja": return .japanese
            case "zh": return .simplifiedChinese
            case "en": return .english
            default: continue
            }
        }
        return .english
    }
}
