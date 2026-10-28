#!/bin/bash
# Builds a release Pulse.app into build/.
set -euo pipefail
cd "$(dirname "$0")/.."

swift build -c release --build-system native 2>&1 | grep -v "has been deprecated" || true
BIN="$(swift build -c release --build-system native --show-bin-path 2>/dev/null)/Pulse"
[[ -x "$BIN" ]] || { echo "Build failed" >&2; exit 1; }

APP=build/Pulse.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Pulse"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc signature: required for Open at Login to work.
codesign --force --sign - --timestamp=none "$APP"
echo "Built $APP"
