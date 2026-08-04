import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private let authorization = AccessibilityAuthorization()
    private let loginItem = LoginItem()

    private var coordinator: QuitCoordinator?
    private var statusItemController: StatusItemController?
    private var settingsWindowController: SettingsWindowController?
    private var cancellables: Set<AnyCancellable> = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        applyAppearance()

        let coordinator = QuitCoordinator(settings: settings, authorization: authorization)
        let statusItemController = StatusItemController(
            settings: settings,
            authorization: authorization
        )
        let settingsWindowController = SettingsWindowController(
            settings: settings,
            authorization: authorization,
            loginItem: loginItem
        )

        statusItemController.onOpenSettings = { settingsWindowController.show() }
        authorization.onTrustGranted = { coordinator.start() }

        self.coordinator = coordinator
        self.statusItemController = statusItemController
        self.settingsWindowController = settingsWindowController

        installMainMenu()

        settings.$theme
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.applyAppearance() }
            .store(in: &cancellables)

        settings.$language
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.installMainMenu() }
            .store(in: &cancellables)

        authorization.beginMonitoring()
        coordinator.start()

        // First launch: no permission yet, so prompt and open Settings so the app
        // explains itself instead of sitting silently in the menu bar.
        if !authorization.isTrusted {
            authorization.request()
            settingsWindowController.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
    }

    /// Scopes the light/dark override to this app's own windows.
    private func applyAppearance() {
        NSApp.appearance = settings.theme.nsAppearance
    }

    private func installMainMenu() {
        MainMenu.install(
            strings: settings.strings,
            settingsTarget: self,
            settingsAction: #selector(openSettings)
        )
    }

    @objc private func openSettings() {
        settingsWindowController?.show()
    }
}
