# MicMute 🎤

Minimal macOS menu bar app — single click to mute / unmute **all** microphones system-wide.

| State   | Icon        |
|---------|-------------|
| Active  | `mic.fill` (solid mic) |
| Muted   | `mic.slash.fill` (mic with slash) |

## Features

- **Single-click toggle** in the menu bar — nothing else
- **All input devices** affected (built-in, USB, webcam, etc.)
- **60 % volume** restored on unmute (not 100 %)
- **Auto-launches at every login** via `SMAppService`
- **No Dock icon**, no menu, no terminal window
- Adapts icon to light / dark menu bar automatically (SF Symbols template)

## Requirements

- macOS 13 Ventura or later
- Xcode Command Line Tools (`xcode-select --install`)

## Install (one command)

```bash
chmod +x build_install.sh && ./build_install.sh
```

That script:
1. Compiles a release binary with `swift build -c release`
2. Packages it into `/Applications/MicMute.app`
3. Ad-hoc signs the bundle
4. Launches the app immediately

On first launch macOS will ask for **Microphone** access — click **Allow**.

## Uninstall

```bash
Kill the running app
pkill -x MicMute

# Remove the app
rm -rf /Applications/MicMute.app

# Remove from login items (or use System Settings → General → Login Items)
defaults delete com.micmute.app
```

## Size

The compiled binary is well under 500 KB (typically ~100–200 KB).
