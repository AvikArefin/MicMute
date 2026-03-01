#!/bin/bash
# ─────────────────────────────────────────────────────────────
#  build_install.sh  –  Build MicMute and install to /Applications
# ─────────────────────────────────────────────────────────────
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="MicMute"
BUNDLE_ID="com.micmute.app"
APP_BUNDLE="/Applications/${APP_NAME}.app"

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
echo "✅  MicMute is running in your menu bar."
echo "   On first launch macOS may ask for microphone access – please Allow."
echo "   The app will auto-launch on every login automatically."
echo ""
echo "   To REMOVE auto-launch later, open System Settings → General → Login Items"
echo "   and remove MicMute from the list."
