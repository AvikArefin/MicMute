import AppKit
import ServiceManagement

// ─── AppleScript Helpers ──────────────────────────────────────────────────────

@discardableResult
func runAppleScript(_ source: String) -> NSAppleEventDescriptor? {
    var error: NSDictionary?
    let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
    return result
}

func setMicVolume(_ volume: Int) {
    runAppleScript("set volume input volume \(volume)")
}

func readMicVolume() -> Int {
    let result = runAppleScript("input volume of (get volume settings)")
    return Int(result?.int32Value ?? 0)
}

// ─── App Delegate ─────────────────────────────────────────────────────────────

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var isMuted = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Auto-launch at login (macOS 13+)
        if #available(macOS 13.0, *) {
            _ = try? SMAppService.mainApp.register()
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let btn = statusItem.button {
            btn.action = #selector(toggle)
            btn.target  = self
        }

        // Read real current state from system
        isMuted = (readMicVolume() == 0)
        updateIcon()
    }

    @objc func toggle() {
        isMuted.toggle()
        setMicVolume(isMuted ? 0 : 60)   // 0 = muted, 60 = 60% on unmute
        updateIcon()
    }

    func updateIcon() {
        guard let btn = statusItem.button else { return }
        let name = isMuted ? "mic.slash.fill" : "mic.fill"
        let img  = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        img?.isTemplate = true            // auto light/dark menu bar
        btn.image   = img
        btn.toolTip = isMuted ? "Mic muted – click to unmute" : "Mic active – click to mute"
    }
}

// ─── Entry Point ──────────────────────────────────────────────────────────────

let app      = NSApplication.shared
app.setActivationPolicy(.accessory)    // no Dock icon, no app switcher
let delegate = AppDelegate()
app.delegate = delegate
app.run()
