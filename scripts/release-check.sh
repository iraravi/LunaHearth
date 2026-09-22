#!/usr/bin/env bash
# Synthetic local fixtures only. No household reset, iCloud credentials or live Apple writes.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
command -v xcodegen >/dev/null
xcodegen generate
artifacts="${RELEASE_RESULTS_DIR:-/tmp/LunaHearthRelease-$(date +%Y%m%d-%H%M%S)}"
mkdir -p "$artifacts"
for kind in iPhone iPad; do
  simulator_id=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
kind=sys.argv[1]
devices=[d for runtime,group in json.load(sys.stdin)["devices"].items() if ".iOS-" in runtime for d in group if d.get("isAvailable") and d["name"].startswith(kind)]
if not devices: sys.exit("No available "+kind+" simulator")
print(next((d for d in devices if d["state"]=="Booted"), devices[0])["udid"])
' "$kind")
  targets=()
  if [[ "$kind" == iPhone ]]; then targets+=(-only-testing:LunaHearthTests); fi
  for test in testReceiptLinksBoughtItemWithoutRestocking testReceiptLinkLargeText testStoreFailureNeverShowsNewHomeSetup testMeasuredShoppingRestockUpdatesPantry testExpenseDashboardMonthlyTracking testLinkedAppleCalendarFlow testSiriAppointmentDraftLink testFamilyWeekLargeText; do
    targets+=("-only-testing:LunaHearthUITests/VisualFlowTests/$test")
  done
  xcodebuild -project LunaHearth.xcodeproj -scheme LunaHearth \
    -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath "${DERIVED_DATA_PATH:-/tmp/LunaHearthReleaseDerivedData}" \
    -resultBundlePath "$artifacts/$kind.xcresult" "${targets[@]}" test 2>&1 | tee "$artifacts/$kind.log"
done
printf 'Release regression results: %s\n' "$artifacts"
