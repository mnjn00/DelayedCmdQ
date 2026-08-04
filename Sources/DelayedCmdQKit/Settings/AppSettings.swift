import Combine
import Foundation

/// User-facing preferences, persisted to `UserDefaults`.
@MainActor
final class AppSettings: ObservableObject {
    enum Key {
        static let holdDuration = "holdDuration"
        static let isPaused = "isPaused"
        static let showsApplicationIcon = "showsApplicationIcon"
        static let allowsContinuousQuit = "allowsContinuousQuit"
        static let appearance = "appearance"
        static let language = "language"
        static let glassOpacity = "glassOpacity"
    }

    private let defaults: UserDefaults

    /// How long Cmd+Q has to be held before the front app is asked to quit.
    @Published var holdDuration: TimeInterval {
        didSet {
            let normalized = HoldDuration.normalized(holdDuration)
            guard normalized == holdDuration else {
                holdDuration = normalized
                return
            }
            defaults.set(holdDuration, forKey: Key.holdDuration)
        }
    }

    @Published var isPaused: Bool {
        didSet { defaults.set(isPaused, forKey: Key.isPaused) }
    }

    @Published var showsApplicationIcon: Bool {
        didSet { defaults.set(showsApplicationIcon, forKey: Key.showsApplicationIcon) }
    }

    /// When on, holding Cmd+Q past the first quit moves on to the next app that takes
    /// focus and quits that too. Off by default: quitting a whole stack of apps from
    /// one keypress is the opposite of what this app exists to prevent.
    @Published var allowsContinuousQuit: Bool {
        didSet { defaults.set(allowsContinuousQuit, forKey: Key.allowsContinuousQuit) }
    }

    /// How solid the glass coin behind the ring is drawn.
    @Published var glassOpacity: Double {
        didSet {
            let normalized = GlassOpacity.normalized(glassOpacity)
            guard normalized == glassOpacity else {
                glassOpacity = normalized
                return
            }
            defaults.set(glassOpacity, forKey: Key.glassOpacity)
        }
    }

    @Published var appearance: AppearanceMode {
        didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) }
    }

    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Key.language) }
    }

    /// Current strings. Views read this, so changing `language` re-renders them.
    var strings: Localization { language.localization }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let stored = defaults.object(forKey: Key.holdDuration) as? TimeInterval
        holdDuration = HoldDuration.normalized(stored ?? HoldDuration.default)
        isPaused = defaults.bool(forKey: Key.isPaused)
        showsApplicationIcon = defaults.object(forKey: Key.showsApplicationIcon) as? Bool ?? true
        allowsContinuousQuit = defaults.bool(forKey: Key.allowsContinuousQuit)
        let storedOpacity = defaults.object(forKey: Key.glassOpacity) as? Double
        glassOpacity = GlassOpacity.normalized(storedOpacity ?? GlassOpacity.default)
        appearance = Self.enumValue(defaults.string(forKey: Key.appearance), default: .system)
        language = Self.enumValue(defaults.string(forKey: Key.language), default: .system)
    }

    /// Falls back to the default when the stored string is missing or no longer a
    /// case, so a downgrade or a hand-edited plist cannot brick a preference.
    private static func enumValue<T: RawRepresentable>(
        _ raw: String?,
        default fallback: T
    ) -> T where T.RawValue == String {
        raw.flatMap(T.init(rawValue:)) ?? fallback
    }
}
