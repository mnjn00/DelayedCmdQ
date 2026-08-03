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

        statusItem.menu = buildMenu()
        refresh()

        settings.$isPaused
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        authorization.$isTrusted
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let status = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        status.isEnabled = false
        status.tag = MenuTag.status.rawValue
        menu.addItem(status)

        let permission = NSMenuItem(
            title: "손쉬운 사용 권한 열기",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        permission.target = self
        permission.tag = MenuTag.permission.rawValue
        menu.addItem(permission)

        menu.addItem(.separator())

        let pause = NSMenuItem(title: "일시 중지", action: #selector(togglePause), keyEquivalent: "")
        pause.target = self
        pause.tag = MenuTag.pause.rawValue
        menu.addItem(pause)

        let settingsItem = NSMenuItem(
            title: "설정...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Delayed Cmd+Q 종료",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quit.target = NSApp
        menu.addItem(quit)

        return menu
    }

    func refresh() {
        let paused = settings.isPaused || !authorization.isTrusted

        statusItem.button?.image = StatusIcon.make(paused: paused)
        statusItem.button?.toolTip = paused ? "Delayed Cmd+Q - 비활성" : "Delayed Cmd+Q - 활성"

        item(.status)?.title = statusTitle
        item(.pause)?.state = settings.isPaused ? .on : .off
        item(.permission)?.isHidden = authorization.isTrusted
    }

    private var statusTitle: String {
        guard authorization.isTrusted else { return "손쉬운 사용 권한이 필요합니다" }
        guard !settings.isPaused else { return "일시 중지됨" }
        return "⌘Q를 \(HoldDuration.text(settings.holdDuration)) 누르면 종료"
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
