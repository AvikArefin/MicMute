import AppKit
import ServiceManagement

/// Right-click preferences window.
/// Left-click the menu bar icon to toggle mute; right-click to open this.
final class PreferencesWindow: NSObject {

    // Callbacks wired up by AppDelegate
    var onToggle: (() -> Void)?
    var onIconChanged: ((Bool) -> Void)?

    private var window: NSWindow?

    // Dynamic controls
    private var statusIcon:  NSImageView!
    private var statusLabel: NSTextField!
    private var muteBtn:     NSButton!
    private var volumePopup: NSPopUpButton!
    private var iconCheck:   NSButton!
    private var loginCheck:  NSButton!

    private let volumeLevels = [25, 50, 60, 75, 100]

    // MARK: - Public

    func show() {
        if window == nil { build() }
        refresh()
        window!.center()
        window!.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func refresh() {
        guard window != nil else { return }
        let muted = Mic.shared.isMuted

        statusIcon.image = NSImage(
            systemSymbolName: muted ? "mic.slash.fill" : "mic.fill",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(.init(pointSize: 24, weight: .medium))
        statusIcon.contentTintColor = muted ? .systemRed : .systemGreen
        statusLabel.stringValue     = muted ? "Microphone is Muted" : "Microphone is Active"
        statusLabel.textColor       = muted ? .systemRed : .labelColor
        muteBtn.title               = muted ? "  Unmute  " : "  Mute  "

        if let idx = volumeLevels.firstIndex(of: Mic.shared.unmuteVolume) {
            volumePopup.selectItem(at: idx)
        }

        let showIcon = UserDefaults.standard.object(forKey: "showMenuBarIcon") as? Bool ?? true
        iconCheck.state = showIcon ? .on : .off

        if #available(macOS 13.0, *) {
            loginCheck.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        }
    }

    // MARK: - Build

    private func build() {
        let win = NSWindow(
            contentRect: NSMakeRect(0, 0, 320, 10),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        win.title                = "MicMute"
        win.isReleasedWhenClosed = false

        let stack = makeStack(axis: .vertical, spacing: 8)
        stack.alignment  = .centerX
        stack.edgeInsets = NSEdgeInsets(top: 24, left: 24, bottom: 24, right: 24)
        stack.translatesAutoresizingMaskIntoConstraints = false

        let cv = win.contentView!
        cv.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: cv.topAnchor),
            stack.leadingAnchor.constraint(equalTo: cv.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: cv.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: cv.bottomAnchor),
        ])

        addStatusSection(to: stack)
        stack.addArrangedSubview(makeDivider())
        stack.setCustomSpacing(14, after: stack.arrangedSubviews.last!)

        addShortcutsSection(to: stack)
        stack.addArrangedSubview(makeDivider())
        stack.setCustomSpacing(14, after: stack.arrangedSubviews.last!)

        addSettingsSection(to: stack)
        stack.addArrangedSubview(makeDivider())
        stack.setCustomSpacing(14, after: stack.arrangedSubviews.last!)

        let quitBtn = NSButton(title: "Quit MicMute",
                               target: NSApp,
                               action: #selector(NSApplication.terminate))
        quitBtn.bezelStyle = .rounded
        stack.addArrangedSubview(quitBtn)

        cv.layoutSubtreeIfNeeded()
        let fit = stack.fittingSize
        win.setContentSize(NSSize(width: max(320, fit.width), height: fit.height))
        window = win
    }

    // MARK: - Section builders

    private func addStatusSection(to stack: NSStackView) {
        let row = makeStack(axis: .horizontal, spacing: 8)
        row.alignment = .centerY

        statusIcon = NSImageView()
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusIcon.widthAnchor.constraint(equalToConstant: 28).isActive  = true
        statusIcon.heightAnchor.constraint(equalToConstant: 28).isActive = true

        statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = .systemFont(ofSize: 15, weight: .semibold)

        row.addArrangedSubview(statusIcon)
        row.addArrangedSubview(statusLabel)
        stack.addArrangedSubview(row)
        stack.setCustomSpacing(14, after: row)

        muteBtn = NSButton(title: "  Mute  ", target: self, action: #selector(muteTapped))
        muteBtn.bezelStyle  = .rounded
        muteBtn.controlSize = .large
        muteBtn.font        = .systemFont(ofSize: 14, weight: .medium)
        stack.addArrangedSubview(muteBtn)
        stack.setCustomSpacing(18, after: muteBtn)
    }

    private func addShortcutsSection(to stack: NSStackView) {
        stack.addArrangedSubview(sectionLabel("Keyboard Shortcuts"))
        stack.setCustomSpacing(6, after: stack.arrangedSubviews.last!)

        let box = makeStack(axis: .vertical, spacing: 4)
        box.alignment = .leading

        let shortcuts: [(key: String, description: String)] = [
            ("⌘⇧M", "Toggle mute"),
            ("⌥⌘M", "Toggle menu bar icon"),
        ]
        for (key, desc) in shortcuts {
            let row = makeStack(axis: .horizontal, spacing: 12)
            row.alignment = .firstBaseline

            let kLbl = NSTextField(labelWithString: key)
            kLbl.font      = .monospacedSystemFont(ofSize: 11, weight: .medium)
            kLbl.textColor = .tertiaryLabelColor
            kLbl.alignment = .right
            kLbl.translatesAutoresizingMaskIntoConstraints = false
            kLbl.widthAnchor.constraint(equalToConstant: 44).isActive = true

            let dLbl = NSTextField(labelWithString: desc)
            dLbl.font      = .systemFont(ofSize: 12)
            dLbl.textColor = .secondaryLabelColor

            row.addArrangedSubview(kLbl)
            row.addArrangedSubview(dLbl)
            box.addArrangedSubview(row)
        }
        stack.addArrangedSubview(box)
        stack.setCustomSpacing(18, after: box)
    }

    private func addSettingsSection(to stack: NSStackView) {
        stack.addArrangedSubview(sectionLabel("Settings"))
        stack.setCustomSpacing(8, after: stack.arrangedSubviews.last!)

        // Unmute volume row
        let volRow = makeStack(axis: .horizontal, spacing: 8)
        volRow.alignment = .centerY

        let volLbl = NSTextField(labelWithString: "Unmute volume")
        volLbl.font = .systemFont(ofSize: 13)

        volumePopup = NSPopUpButton()
        for v in volumeLevels { volumePopup.addItem(withTitle: "\(v)%") }
        volumePopup.target = self
        volumePopup.action = #selector(volumeChanged)

        volRow.addArrangedSubview(volLbl)
        volRow.addArrangedSubview(volumePopup)
        stack.addArrangedSubview(volRow)

        // Show in menu bar
        iconCheck = NSButton(checkboxWithTitle: "Show in menu bar",
                             target: self, action: #selector(iconCheckChanged))
        iconCheck.font = .systemFont(ofSize: 13)
        stack.addArrangedSubview(iconCheck)

        // Start at login
        loginCheck = NSButton(checkboxWithTitle: "Start at login",
                              target: self, action: #selector(loginCheckChanged))
        loginCheck.font = .systemFont(ofSize: 13)
        stack.addArrangedSubview(loginCheck)
        stack.setCustomSpacing(18, after: loginCheck)
    }

    // MARK: - Actions

    @objc private func muteTapped()     { onToggle?() }

    @objc private func volumeChanged()  {
        let idx = volumePopup.indexOfSelectedItem
        if volumeLevels.indices.contains(idx) {
            Mic.shared.unmuteVolume = volumeLevels[idx]
        }
    }

    @objc private func iconCheckChanged() {
        let wantShow = (iconCheck.state == .on)
        if !wantShow {
            let alert = NSAlert()
            alert.messageText     = "Hide Menu Bar Icon?"
            alert.informativeText =
                "MicMute keeps running in the background.\n\n" +
                "Restore the icon anytime:\n" +
                "  • Press ⌥⌘M\n" +
                "  • Or re-open MicMute from /Applications"
            alert.addButton(withTitle: "Hide")
            alert.addButton(withTitle: "Cancel")
            guard alert.runModal() == .alertFirstButtonReturn else {
                iconCheck.state = .on
                return
            }
        }
        onIconChanged?(wantShow)
    }

    @objc private func loginCheckChanged() {
        if #available(macOS 13.0, *) {
            if loginCheck.state == .on {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }

    // MARK: - UI helpers

    private func makeStack(axis: NSUserInterfaceLayoutOrientation, spacing: CGFloat) -> NSStackView {
        let s = NSStackView()
        s.orientation = axis
        s.spacing     = spacing
        return s
    }

    private func makeDivider() -> NSView {
        let v = NSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.separatorColor.cgColor
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive   = true
        v.widthAnchor.constraint(equalToConstant: 272).isActive  = true
        return v
    }

    private func sectionLabel(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font      = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .secondaryLabelColor
        return l
    }
}
