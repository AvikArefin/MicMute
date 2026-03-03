import AppKit
import ServiceManagement

/// A professionally-designed macOS preferences popover.
final class PreferencesWindow: NSObject {

    private var popover: NSPopover?

    // Dynamic controls
    private var statusIcon:  NSImageView!
    private var statusLabel: NSTextField!
    private var loginCheck:  NSButton!

    // MARK: - Public

    func show(relativeTo button: NSButton) {
        if popover == nil { build() }
        refresh()
        popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        NSApp.activate(ignoringOtherApps: true)
    }

    func refresh() {
        guard popover != nil else { return }
        let muted = Mic.shared.isMuted

        statusIcon.image = NSImage(
            systemSymbolName: muted ? "mic.slash.fill" : "mic.fill",
            accessibilityDescription: nil
        )?.withSymbolConfiguration(.init(pointSize: 18, weight: .semibold))
        
        statusIcon.contentTintColor = muted ? .systemRed : .systemGreen
        statusLabel.stringValue     = muted ? "Microphone Muted" : "Microphone Active"
        statusLabel.textColor       = muted ? .systemRed : .labelColor

        if #available(macOS 13.0, *) {
            loginCheck.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
        }
    }

    // MARK: - Build

    private func build() {
        let controller = NSViewController()
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        controller.view = view

        // 1. Header (Status) - Preserved as requested
        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.labelColor.withAlphaComponent(0.04).cgColor
        
        statusIcon = NSImageView()
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        
        let headerStack = NSStackView(views: [statusIcon, statusLabel])
        headerStack.spacing = 10
        headerStack.alignment = .centerY
        headerStack.translatesAutoresizingMaskIntoConstraints = false
        
        headerView.addSubview(headerStack)
        NSLayoutConstraint.activate([
            headerStack.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerStack.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 54)
        ])

        // 2. Settings Row (Login)
        let loginLabel = bodyLabel("Start at Login")
        loginCheck = NSButton(checkboxWithTitle: "", target: self, action: #selector(loginCheckChanged))
        loginCheck.controlSize = .small
        let loginRow = NSStackView(views: [loginLabel, loginCheck])
        loginRow.spacing = 8

        // 3. Shortcut Section (Simplified & Centered)
        let shortcutKey = bodyLabel("⌘⇧M")
        shortcutKey.font = .monospacedSystemFont(ofSize: 11, weight: .bold)
        shortcutKey.textColor = .secondaryLabelColor
        let shortcutDesc = bodyLabel("Toggle Mute")
        shortcutDesc.textColor = .secondaryLabelColor
        
        let shortcutRow = NSStackView(views: [shortcutKey, shortcutDesc])
        shortcutRow.spacing = 6

        // 4. Footer (Proper Button)
        let quitBtn = NSButton(title: "Quit MicMute", target: NSApp, action: #selector(NSApplication.terminate))
        quitBtn.bezelStyle = .rounded
        quitBtn.controlSize = .regular
        quitBtn.translatesAutoresizingMaskIntoConstraints = false

        // Main Vertical Stack (Centering everything)
        let mainStack = NSStackView(views: [headerView, loginRow, shortcutRow, quitBtn])
        mainStack.orientation = .vertical
        mainStack.spacing = 14
        mainStack.alignment = .centerX
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.setCustomSpacing(20, after: headerView)
        mainStack.setCustomSpacing(20, after: shortcutRow)
        
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            
            headerView.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            view.widthAnchor.constraint(equalToConstant: 240)
        ])

        popover = NSPopover()
        popover?.contentViewController = controller
        popover?.behavior = .transient
    }

    // MARK: - Actions

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

    private func bodyLabel(_ text: String) -> NSTextField {
        let l = NSTextField(labelWithString: text)
        l.font = .systemFont(ofSize: 12)
        l.translatesAutoresizingMaskIntoConstraints = false
        // Removed the widthAnchor constraint to prevent text cropping
        return l
    }
}