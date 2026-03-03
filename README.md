# MicMute 🎤

A clean, minimal macOS menu bar app to mute / unmute all microphones system-wide. Works instantly — no permissions hassles, no Accessibility prompts.

## Features

- **Global hotkeys** (no Fn key needed) — toggle mute in any app  
- **Menu bar icon** — click to toggle, right-click for preferences  
- **Visual feedback** — brief translucent HUD overlay on every toggle  
- **Preferences window** — configure volume, start at login  
- **All input devices** — built-in mic, USB, webcam, etc.  
- **Customizable unmute volume** — choose 25% to 100% (defaults to 60%)  
- **Auto-launch at login** — via macOS `SMAppService`  
- **No Dock icon**, no terminal window — pure menu bar app  
- **Light & dark mode** — icon adapts automatically  
- **Tiny footprint** — ~100–200 KB binary  

## Hotkeys

| Shortcut | Action |
|----------|--------|
| `⌘⇧M` | Toggle microphone mute |

Both work globally — no need for Fn key, works in any app or fullscreen.

## Quick Start

### Install

```bash
chmod +x build_install.sh && ./build_install.sh
```

The script builds, packages, signs, and launches the app in one step.

**First launch:** macOS may ask for Microphone access — click **Allow**.

### Uninstall

```bash
# Kill the app
pkill -x MicMute

# Remove the app bundle
rm -rf /Applications/MicMute.app

# Remove from login items (optional)
defaults delete com.micmute.app
```

## Usage

**Left-click icon** → Toggle mute. A visual HUD briefly appears showing the new state.

**Right-click icon** → Open preferences window:
- Status indicator (red = muted, green = active)  
- Hotkey reference  
- Toggle auto-launch at login  
- Quit button  

## Architecture

Clean, modular Swift codebase — one responsibility per file:

| File | Purpose |
|------|---------|
| `main.swift` | Entry point (7 lines) |
| `Mic.swift` | Microphone state management & AppleScript control |
| `HotkeyManager.swift` | Carbon-based global hotkey registration |
| `MuteHUD.swift` | Translucent center-screen toggle feedback |
| `PreferencesWindow.swift` | Settings UI (status, volume, toggles) |
| `AppDelegate.swift` | App lifecycle & component wiring |

## Requirements

- **macOS 13.0+** (Ventura or later)  
- **Xcode Command Line Tools** (`xcode-select --install`)  
- **Swift 5.9+** (included with Xcode 15+)

## Build

```bash
swift build -c release
# Binary: .build/release/MicMute
```

## Technical Notes

- Uses **Carbon hotkeys** (not NSEvent) — works globally without Accessibility permission  
- Uses **AppleScript** for mic control — no private APIs, fully sandboxable  
- Runs as `.accessory` — no Dock icon, minimal system footprint  
- Preferences stored in `UserDefaults` — safe, standard macOS practice

## License

Open source — feel free to fork, modify, and redistribute.

## Credits

Built by [Claude](https://claude.ai) & [Gemini](https://gemini.google.com/).