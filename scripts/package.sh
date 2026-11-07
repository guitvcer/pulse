#!/bin/bash
# Builds Pulse.app and zips it into build/Pulse.zip (+ .sha256) for a GitHub release.
set -euo pipefail
cd "$(dirname "$0")/.."

scripts/build-app.sh
cd build
rm -f Pulse.zip Pulse.zip.sha256
ditto -c -k --keepParent Pulse.app Pulse.zip
shasum -a 256 Pulse.zip > Pulse.zip.sha256
echo "Packaged build/Pulse.zip"
