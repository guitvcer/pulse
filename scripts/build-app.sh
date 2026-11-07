#!/bin/bash
# Builds a universal (Apple Silicon + Intel) release Pulse.app into build/.
set -euo pipefail
cd "$(dirname "$0")/.."

ARCHS=(arm64 x86_64)
for arch in "${ARCHS[@]}"; do
    swift build -c release --build-system native --triple "$arch-apple-macosx14.0" 2>&1 \
        | grep -v "has been deprecated" || true
    [[ -x ".build/$arch-apple-macosx/release/Pulse" ]] || { echo "Build failed for $arch" >&2; exit 1; }
done

APP=build/Pulse.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
lipo -create -output "$APP/Contents/MacOS/Pulse" \
    .build/arm64-apple-macosx/release/Pulse .build/x86_64-apple-macosx/release/Pulse
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

# Ad-hoc signature: required for Open at Login to work.
codesign --force --sign - --timestamp=none "$APP"
echo "Built $APP"
