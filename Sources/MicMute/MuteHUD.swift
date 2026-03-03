import AppKit

/// Translucent center-screen overlay that briefly appears on every mute toggle.
final class MuteHUD {

    private var window: NSWindow?
    private var iconView: NSImageView?
    private var labelView: NSTextField?
    private var dismissTimer: Timer?

    func flash(_ muted: Bool) {
        dismissTimer?.invalidate()
        buildIfNeeded()

        let symbol = muted ? "mic.slash.fill" : "mic.fill"
        iconView?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: 48, weight: .medium))
        iconView?.contentTintColor = muted ? .systemRed : .systemGreen
        labelView?.stringValue     = muted ? "Muted" : "Unmuted"

        window?.center()
        window?.alphaValue = 1
        window?.orderFrontRegardless()

        dismissTimer = .scheduledTimer(withTimeInterval: 0.8, repeats: false) { [weak self] _ in
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.3
                self?.window?.animator().alphaValue = 0
            } completionHandler: {
                self?.window?.orderOut(nil)
            }
        }
    }

    // MARK: - Private

    private func buildIfNeeded() {
        guard window == nil else { return }

        let win = NSWindow(
            contentRect: NSMakeRect(0, 0, 140, 140),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque             = false
        win.backgroundColor      = .clear
        win.level                = .screenSaver
        win.ignoresMouseEvents   = true
        win.isReleasedWhenClosed = false
        win.hasShadow            = true

        let blur = NSVisualEffectView(frame: win.contentView!.bounds)
        blur.autoresizingMask = [.width, .height]
        blur.material         = .hudWindow
        blur.state            = .active
        blur.wantsLayer       = true
        blur.layer?.cornerRadius    = 18
        blur.layer?.masksToBounds   = true
        win.contentView!.addSubview(blur)

        let iv = NSImageView(frame: NSMakeRect(30, 40, 80, 80))
        blur.addSubview(iv)

        let lbl = NSTextField(labelWithString: "")
        lbl.frame     = NSMakeRect(0, 10, 140, 22)
        lbl.alignment = .center
        lbl.font      = .systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = .labelColor
        blur.addSubview(lbl)

        window    = win
        iconView  = iv
        labelView = lbl
    }
}
