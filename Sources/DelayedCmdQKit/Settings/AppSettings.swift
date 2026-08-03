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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let stored = defaults.object(forKey: Key.holdDuration) as? TimeInterval
        holdDuration = HoldDuration.normalized(stored ?? HoldDuration.default)
        isPaused = defaults.bool(forKey: Key.isPaused)
        showsApplicationIcon = defaults.object(forKey: Key.showsApplicationIcon) as? Bool ?? true
        allowsContinuousQuit = defaults.bool(forKey: Key.allowsContinuousQuit)
    }
}
