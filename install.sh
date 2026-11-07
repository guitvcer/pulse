#!/bin/sh
# Installs the latest Pulse release: curl -fsSL <this file's URL> | sh
set -eu

repo="guitvcer/pulse"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "Pulse only runs on macOS." >&2
  exit 1
fi

if [ -w /Applications ]; then
  dir="/Applications"
else
  dir="$HOME/Applications"
  mkdir -p "$dir"
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

archive="Pulse.zip"
base="https://github.com/$repo/releases/latest/download"
curl -fsSL "$base/$archive" -o "$work/$archive"
curl -fsSL "$base/$archive.sha256" -o "$work/$archive.sha256"
(cd "$work" && shasum -a 256 -c "$archive.sha256" >/dev/null)
ditto -x -k "$work/$archive" "$work"

pkill -x Pulse 2>/dev/null || true
rm -rf "$dir/Pulse.app"
mv "$work/Pulse.app" "$dir/Pulse.app"
open "$dir/Pulse.app"

echo "Installed Pulse to $dir/Pulse.app. Look for it in the menu bar."
