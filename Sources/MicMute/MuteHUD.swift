import AppKit

/// Translucent center-screen overlay that mimics the native macOS bezel style.
final class MuteHUD {

    private var window: NSWindow?
    private var iconView: NSImageView?
    private var labelView: NSTextField?
    private var dismissTimer: Timer?

    func flash(_ muted: Bool) {
        dismissTimer?.invalidate()
        buildIfNeeded()

        let symbol = muted ? "mic.slash.fill" : "mic.fill"
        
        // System HUDs use .semibold or .bold for the primary icon
        let config = NSImage.SymbolConfiguration(pointSize: 42, weight: .semibold)
        iconView?.image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        
        // Standard macOS HUDs are monochromatic; color is usually reserved for the icon itself if needed
        iconView?.contentTintColor = .labelColor
        labelView?.stringValue = muted ? "Muted" : "Unmuted"

        window?.center()
        window?.alphaValue = 1
        window?.orderFrontRegardless()

        // Slightly longer display time (1.2s) matches system feedback better
        dismissTimer = .scheduledTimer(withTimeInterval: 1.2, repeats: false) { [weak self] _ in
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.4
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                self?.window?.animator().alphaValue = 0
            } completionHandler: {
                self?.window?.orderOut(nil)
            }
        }
    }

    private func buildIfNeeded() {
        guard window == nil else { return }

        let win = NSWindow(
            contentRect: NSMakeRect(0, 0, 160, 160),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        win.isOpaque = false
        win.backgroundColor = .clear
        // .floating keeps it above normal windows
        // .statusBar keeps it above even full-screen windows
        win.level = .floating 
        win.ignoresMouseEvents = true
        win.isReleasedWhenClosed = false
        win.hasShadow = true

        let blur = NSVisualEffectView(frame: win.contentView!.bounds)
        blur.autoresizingMask = [.width, .height]
        
        // .hudWindow is the specific material for these overlays
        blur.material = .hudWindow
        blur.state = .active
        blur.wantsLayer = true
        blur.layer?.cornerRadius = 20 // macOS 11+ radius
        win.contentView?.addSubview(blur)

        // Using a StackView for perfect alignment (more modern than manual frames)
        let stack = NSStackView(frame: blur.bounds.insetBy(dx: 10, dy: 20))
        stack.orientation = .vertical
        stack.spacing = 12
        stack.alignment = .centerX
        stack.distribution = .fillProportionally
        blur.addSubview(stack)

        let iv = NSImageView()
        iv.imageScaling = .scaleProportionallyUpOrDown
        
        let lbl = NSTextField(labelWithString: "")
        lbl.font = .systemFont(ofSize: 15, weight: .semibold)
        lbl.textColor = .secondaryLabelColor // Subtle, native look
        
        stack.addArrangedSubview(iv)
        stack.addArrangedSubview(lbl)

        window = win
        iconView = iv
        labelView = lbl
    }
}