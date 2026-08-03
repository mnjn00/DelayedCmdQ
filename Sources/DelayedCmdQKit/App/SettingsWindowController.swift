import AppKit
import SwiftUI

/// Lazily creates the single Settings window and brings it forward.
@MainActor
final class SettingsWindowController {
    private let settings: AppSettings
    private let authorization: AccessibilityAuthorization
    private let loginItem: LoginItem
    private var window: NSWindow?

    init(settings: AppSettings, authorization: AccessibilityAuthorization, loginItem: LoginItem) {
        self.settings = settings
        self.authorization = authorization
        self.loginItem = loginItem
    }

    func show() {
        let window = existingWindow()
        // An accessory app has to activate itself; ordering front is not enough to
        // give the window keyboard focus.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
        window.center()
    }

    private func existingWindow() -> NSWindow {
        if let window { return window }

        let root = SettingsView(
            settings: settings,
            authorization: authorization,
            loginItem: loginItem
        )
        let controller = NSHostingController(rootView: root)
        let window = NSWindow(contentViewController: controller)
        window.title = "Delayed Cmd+Q"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true

        self.window = window
        return window
    }
}
