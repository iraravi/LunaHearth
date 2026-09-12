#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "LunaHearth iOS development requires macOS with Xcode."
  exit 1
fi

command -v xcodebuild >/dev/null || { echo "Install Xcode and select it with xcode-select."; exit 1; }
if ! command -v xcodegen >/dev/null; then
  echo "XcodeGen is required to generate the .xcodeproj. Install with: brew install xcodegen"
  exit 1
fi

xcodegen generate
echo "Generated LunaHearth.xcodeproj. Open it in Xcode and set your Development Team."
