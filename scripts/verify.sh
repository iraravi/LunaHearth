#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
command -v xcodegen >/dev/null || { echo "XcodeGen is required: brew install xcodegen"; exit 1; }
xcodegen generate
simulator_id="${SIMULATOR_ID:-}"
if [[ -z "$simulator_id" ]]; then
  simulator_id=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
runtimes=json.load(sys.stdin)["devices"]
phones=[d for runtime,devices in runtimes.items() if ".iOS-" in runtime for d in devices if d.get("isAvailable") and d["name"].startswith("iPhone")]
preferred=next((d for d in phones if d["name"]=="iPhone 17 Pro"), next(iter(phones), None))
if preferred is None: sys.exit("No available iPhone simulator. Install an iOS runtime in Xcode Settings > Components.")
print(preferred["udid"])
')
fi
action="${1:-all}"
case "$action" in
  build|test) actions=("$action") ;;
  all) actions=(build test) ;;
  *) echo "Usage: scripts/verify.sh [build|test|all]"; exit 2 ;;
esac
for step in "${actions[@]}"; do
  xcodebuild -project LunaHearth.xcodeproj -scheme LunaHearth \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath "${DERIVED_DATA_PATH:-/tmp/LunaHearthDerivedData}" "$step"
done
