#!/usr/bin/env bash
# Same iPhone 16 → 17 (then first available iPhone) fallback as .github/workflows/ci.yml.
set -euo pipefail

if xcrun simctl list devices available | grep -Fq 'iPhone 16 ('; then
  DEST_NAME='iPhone 16'
elif xcrun simctl list devices available | grep -Fq 'iPhone 17 ('; then
  DEST_NAME='iPhone 17'
else
  DEST_NAME="$(xcrun simctl list devices available | grep -E '^[[:space:]]*iPhone ' | head -1 | sed -E 's/^[[:space:]]+//; s/ \([0-9A-F-]{8,}.*//')"
fi

if [ -z "${DEST_NAME}" ]; then
  echo "No available iPhone simulator found. Run: xcodebuild -scheme SceneShift -showdestinations" >&2
  exit 1
fi

echo "Using destination: platform=iOS Simulator,OS=latest,name=${DEST_NAME}"
xcodebuild test \
  -scheme SceneShift \
  -destination "platform=iOS Simulator,OS=latest,name=${DEST_NAME}"
