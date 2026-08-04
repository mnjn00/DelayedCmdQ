import AppKit
import Combine

/// Menu bar presence: current state, a pause switch, Settings and Quit.
@MainActor
final class StatusItemController: NSObject {
    private let settings: AppSettings
    private let authorization: AccessibilityAuthorization
    private let statusItem: NSStatusItem
    private var cancellables: Set<AnyCancellable> = []

    var onOpenSettings: () -> Void = {}

    init(settings: AppSettings, authorization: AccessibilityAuthorization) {
        self.settings = settings
        self.authorization = authorization
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        rebuildMenu()

        // Menu item titles are baked in at build time, so a language change needs a
        // fresh menu rather than a refresh.
        settings.$language
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildMenu() }
            .store(in: &cancellables)

        Publishers.CombineLatest3(
            settings.$isPaused,
            settings.$holdDuration,
            authorization.$isTrusted
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] _, _, _ in self?.refresh() }
        .store(in: &cancellables)
    }

    private var strings: Localization { settings.strings }

    func rebuildMenu() {
        statusItem.menu = buildMenu()
        refresh()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let status = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        status.isEnabled = false
        status.tag = MenuTag.status.rawValue
        menu.addItem(status)

        let permission = NSMenuItem(
            title: strings.menuOpenAccessibilitySettings,
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        permission.target = self
        permission.tag = MenuTag.permission.rawValue
        menu.addItem(permission)

        menu.addItem(.separator())

        let pause = NSMenuItem(
            title: strings.menuPause,
            action: #selector(togglePause),
            keyEquivalent: ""
        )
        pause.target = self
        pause.tag = MenuTag.pause.rawValue
        menu.addItem(pause)

        let settingsItem = NSMenuItem(
            title: strings.menuSettings,
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: strings.menuQuit,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quit.target = NSApp
        menu.addItem(quit)

        return menu
    }

    func refresh() {
        let inactive = settings.isPaused || !authorization.isTrusted

        statusItem.button?.image = StatusIcon.make(paused: inactive)
        statusItem.button?.toolTip =
            inactive ? strings.menuTooltipInactive : strings.menuTooltipActive

        item(.status)?.title = statusTitle
        item(.pause)?.state = settings.isPaused ? .on : .off
        item(.permission)?.isHidden = authorization.isTrusted
    }

    private var statusTitle: String {
        guard authorization.isTrusted else { return strings.menuStatusPermissionRequired }
        guard !settings.isPaused else { return strings.menuStatusPaused }
        return strings.menuStatusActive(settings.holdDuration)
    }

    private func item(_ tag: MenuTag) -> NSMenuItem? {
        statusItem.menu?.item(withTag: tag.rawValue)
    }

    @objc private func togglePause() {
        settings.isPaused.toggle()
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func openAccessibilitySettings() {
        authorization.request()
        authorization.openSystemSettings()
    }

    private enum MenuTag: Int {
        case status = 1
        case permission = 2
        case pause = 3
    }
}
