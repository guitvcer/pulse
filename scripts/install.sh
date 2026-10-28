#!/bin/bash
# Replaces /Applications/Pulse.app with the fresh build and restarts it.
set -euo pipefail
cd "$(dirname "$0")/.."

pkill -x Pulse 2>/dev/null || true
rm -rf /Applications/Pulse.app
cp -R build/Pulse.app /Applications/Pulse.app
open /Applications/Pulse.app
echo "Installed and launched /Applications/Pulse.app"
