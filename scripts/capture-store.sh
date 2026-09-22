#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
results="${STORE_RESULTS_DIR:-/tmp/LunaHearthStore-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$results"
xcodegen generate
for family in phone ipad; do
  target=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
items=[d for runtime,ds in json.load(sys.stdin)["devices"].items() if ".iOS-" in runtime for d in ds if d.get("isAvailable")]
needle="iPhone 18 Pro Max" if sys.argv[1]=="phone" else "iPad Pro 13-inch (M5)"
found=next((d for d in items if d["name"]==needle),None)
if found is None: sys.exit("Install the supported screenshot simulator: "+needle)
print(found["udid"])
' "$family")
  xcrun simctl boot "$target" 2>/dev/null || true
  xcrun simctl bootstatus "$target" -b
  xcrun simctl status_bar "$target" override --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
  xcodebuild -project LunaHearth.xcodeproj -scheme LunaHearth -destination "platform=iOS Simulator,id=$target" \
    -derivedDataPath /tmp/LunaReleaseCapture -resultBundlePath "$results/$family.xcresult" \
    -only-testing:LunaHearthUITests/VisualFlowTests/testAppStoreScreenshots test > "$results/$family.log" 2>&1
  xcrun simctl status_bar "$target" clear
done
python3 scripts/package-store-screenshots.py --phone "$results/phone.xcresult" --ipad "$results/ipad.xcresult"
