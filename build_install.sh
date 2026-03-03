#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  build_install.sh  –  Build MicMute and install to /Applications
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MicMute"
BUNDLE_ID="com.micmute.app"
APP_BUNDLE="/Applications/${APP_NAME}.app"

# Kill any existing instance so the NEW binary is what launches
echo "▶ Stopping existing MicMute…"
pkill -x "$APP_NAME" 2>/dev/null || true
sleep 0.5

echo "▶ Building release binary…"
cd "$SCRIPT_DIR"
swift build -c release 2>&1

BINARY=".build/release/${APP_NAME}"

echo "▶ Creating app bundle at ${APP_BUNDLE}…"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BINARY}"   "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Info.plist"  "${APP_BUNDLE}/Contents/Info.plist"

# ── Code-sign (ad-hoc) so macOS doesn't block it ──────────────
echo "▶ Signing (ad-hoc)…"
codesign --force --deep --sign - "${APP_BUNDLE}" 2>/dev/null \
  || echo "  (codesign skipped – Gatekeeper may prompt on first launch)"

echo "▶ Done!  Launching ${APP_NAME}…"
open "${APP_BUNDLE}"

echo ""
echo "✅  MicMute installed and running."
echo ""
echo "   Left-click icon  → toggle mute"
echo "   Right-click icon → preferences window"
echo "   ⌘⇧M              → toggle mute (always works)"
echo ""
