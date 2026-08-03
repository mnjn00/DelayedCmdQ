import AppKit

/// Entry point for the executable target.
public enum AppLauncher {
    @MainActor
    public static func run() {
        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        // Menu bar only: no Dock tile, no app switcher entry.
        application.setActivationPolicy(.accessory)
        application.run()
        // Keep the delegate alive for the lifetime of the run loop.
        withExtendedLifetime(delegate) {}
    }
}
