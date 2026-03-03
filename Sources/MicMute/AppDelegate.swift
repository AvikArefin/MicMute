import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private let mic     = Mic.shared
    private let hotkeys = HotkeyManager()
    private let hud     = MuteHUD()
    private let prefs   = PreferencesWindow()

    // MARK: - Preferences

    private var showIcon: Bool {
        get { UserDefaults.standard.object(forKey: "showMenuBarIcon") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "showMenuBarIcon")
            statusItem.isVisible = newValue
        }
    }

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        migrateDefaults()

        if #available(macOS 13.0, *) {
            try? SMAppService.mainApp.register()
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.isVisible = showIcon

        if let btn = statusItem.button {
            btn.target = self
            btn.action = #selector(onClick)
            btn.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        mic.sync()
        mic.onChange = { [weak self] muted in
            self?.updateMenuBarIcon()
            self?.hud.flash(muted)
            self?.prefs.refresh()
        }
        updateMenuBarIcon()

        prefs.onToggle = { [weak self] in self?.toggleMic() }
        prefs.onIconChanged = { [weak self] show in
            self?.showIcon = show
            if show { self?.updateMenuBarIcon() }
        }

        hotkeys.install(delegate: self)
    }

    /// Re-opening the .app while running restores the icon and shows preferences.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        showIcon = true
        updateMenuBarIcon()
        prefs.show()
        return false
    }

    // MARK: - Hotkey targets (called from HotkeyManager callback)

    func toggleMic() { mic.toggle() }

    func toggleIcon() {
        showIcon.toggle()
        if showIcon { updateMenuBarIcon() }
    }

    // MARK: - Private

    @objc private func onClick() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            prefs.show()
        } else {
            toggleMic()
        }
    }

    private func updateMenuBarIcon() {
        guard let btn = statusItem.button else { return }
        let symbol = mic.isMuted ? "mic.slash.fill" : "mic.fill"
        let image  = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)
        image?.isTemplate = true
        btn.image   = image
        btn.toolTip = mic.isMuted ? "Mic muted – click to unmute"
                                  : "Mic active – click to mute"
    }

    /// Clears stale UserDefaults written by older versions (e.g. a hidden icon the
    /// user has no way to recover without knowing the hotkey).
    private func migrateDefaults() {
        let defaults = UserDefaults.standard
        let versionKey = "prefsVersion"
        if defaults.integer(forKey: versionKey) < 3 {
            defaults.removeObject(forKey: "showMenuBarIcon")
            defaults.set(3, forKey: versionKey)
        }
    }
}
