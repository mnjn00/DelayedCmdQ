import AppKit

/// Accessory apps do not display a menu bar, but `NSApplication` still routes key
/// equivalents through the main menu. Installing one is what makes ⌘, ⌘W and our
/// own ⌘Q work while the Settings window has focus.
@MainActor
enum MainMenu {
    static func install(
        strings: Localization,
        settingsTarget: AnyObject,
        settingsAction: Selector
    ) {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        let settings = NSMenuItem(
            title: strings.menuSettings,
            action: settingsAction,
            keyEquivalent: ","
        )
        settings.target = settingsTarget
        appMenu.addItem(settings)
        appMenu.addItem(.separator())
        appMenu.addItem(
            withTitle: strings.menuQuit,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appItem.submenu = appMenu
        mainMenu.addItem(appItem)

        mainMenu.addItem(editMenuItem(strings: strings))
        mainMenu.addItem(windowMenuItem(strings: strings))

        NSApp.mainMenu = mainMenu
    }

    private static func editMenuItem(strings: Localization) -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: strings.menuEdit)
        menu.addItem(withTitle: strings.menuUndo, action: Selector(("undo:")), keyEquivalent: "z")
        menu.addItem(.separator())
        menu.addItem(withTitle: strings.menuCut, action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        menu.addItem(
            withTitle: strings.menuCopy,
            action: #selector(NSText.copy(_:)),
            keyEquivalent: "c"
        )
        menu.addItem(
            withTitle: strings.menuPaste,
            action: #selector(NSText.paste(_:)),
            keyEquivalent: "v"
        )
        menu.addItem(
            withTitle: strings.menuSelectAll,
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        item.submenu = menu
        return item
    }

    private static func windowMenuItem(strings: Localization) -> NSMenuItem {
        let item = NSMenuItem()
        let menu = NSMenu(title: strings.menuWindow)
        menu.addItem(
            withTitle: strings.menuClose,
            action: #selector(NSWindow.performClose(_:)),
            keyEquivalent: "w"
        )
        item.submenu = menu
        return item
    }
}
