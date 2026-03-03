import AppKit

/// Controls system microphone input volume.
/// All state mutations go through this singleton.
final class Mic {

    static let shared = Mic()

    private(set) var isMuted = false

    /// Called on every toggle — use to update UI.
    var onChange: ((Bool) -> Void)?

    let unmuteVolume = 55

    private init() { sync() }

    func toggle() {
        isMuted.toggle()
        setInputVolume(isMuted ? 0 : unmuteVolume)
        onChange?(isMuted)
    }

    /// Re-reads the real system state (call once on launch).
    func sync() { isMuted = (getInputVolume() == 0) }

    // MARK: - Private

    private func setInputVolume(_ v: Int) {
        runAS("set volume input volume \(v)")
    }

    private func getInputVolume() -> Int {
        Int(runAS("input volume of (get volume settings)")?.int32Value ?? 0)
    }

    @discardableResult
    private func runAS(_ source: String) -> NSAppleEventDescriptor? {
        var error: NSDictionary?
        return NSAppleScript(source: source)?.executeAndReturnError(&error)
    }
}
