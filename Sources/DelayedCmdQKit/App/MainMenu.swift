import AppKit

/// Accessory apps do not display a menu bar, but `NSApplication` still routes key
/// equivalents through the main menu. Installing one is what makes ⌘, ⌘W and our
/// own ⌘Q work while the Settings window has focus.
@MainActor
enum MainMenu {
    static func install(settingsTarget: AnyObject, settingsAction: Selector) {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        let settings = NSMenuItem(title: "설정...", action: settingsAction, keyEquivalent: ",")
        settings.target = settingsTarget
        appMenu.addItem(settings)
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: "Delayed Cmd+Q 종료",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        mainMenu.addItem(editMenuItem())
        mainMenu.addItem(windowMenuItem())

        NSApp.mainMenu = mainMenu
    }

    private static func editMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "편집")
        menu.addItem(withTitle: "실행 취소", action: Selector(("undo:")), keyEquivalent: "z")
        menu.addItem(.separator())
        menu.addItem(withTitle: "오려두기", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(withTitle: "복사하기", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        menu.addItem(withTitle: "붙여넣기", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        menu.addItem(
            withTitle: "전체 선택",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        item.submenu = menu
        return item
    }

    private static func windowMenuItem() -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: "윈도우")
        menu.addItem(
            withTitle: "닫기",
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )
        item.submenu = menu
        return item
    }
}
