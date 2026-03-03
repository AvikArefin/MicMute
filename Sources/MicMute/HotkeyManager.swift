import Carbon.HIToolbox

// MARK: - Free function callback (required for C interop — closures cannot be used)

func carbonHotkeyHandler(
    _: EventHandlerCallRef?,
    _ event: EventRef?,
    _ userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }

    var hkID = EventHotKeyID()
    let status = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hkID
    )
    guard status == noErr else { return OSStatus(eventNotHandledErr) }

    let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
    DispatchQueue.main.async {
        switch hkID.id {
        case 1: delegate.toggleMic()    // ⌘⇧M
        default: break
        }
    }
    return noErr
}

// MARK: - HotkeyManager

/// Registers global hotkeys via Carbon — no Accessibility permission required.
///
/// Hotkeys (no Fn key ever needed):
///   ⌘⇧M  — toggle mute
final class HotkeyManager {

    private var handlerRef: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef?] = []

    func install(delegate: AppDelegate) {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind:  UInt32(kEventHotKeyPressed)
        )
        let ptr = Unmanaged.passUnretained(delegate).toOpaque()

        let result = InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotkeyHandler,
            1, &eventType, ptr, &handlerRef
        )
        guard result == noErr else {
            NSLog("[MicMute] InstallEventHandler failed: %d", result)
            return
        }

        let sig: FourCharCode = 0x4D4D5554   // "MMUT"
        register(kVK_ANSI_M, UInt32(cmdKey | shiftKey), sig, id: 1)   // ⌘⇧M → mute
    }

    private func register(_ keyCode: Int, _ mods: UInt32, _ sig: FourCharCode, id: UInt32) {
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(keyCode), mods,
            EventHotKeyID(signature: sig, id: id),
            GetApplicationEventTarget(), 0, &ref
        )
        if status == noErr {
            hotKeyRefs.append(ref)
        } else {
            NSLog("[MicMute] RegisterEventHotKey id=%d failed: %d", id, status)
        }
    }
}
