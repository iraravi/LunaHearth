# v2 hidden Home features

User decision: hide Home care, Warranties, rooms and floors for this version.

Changes are presentation-only. Existing home entities, repositories and CloudKit
mapping are preserved, including the full hierarchy persistence test. Quick Add
also omits Home Item because its containing Rooms & belongings destination is
hidden. Pantry inventory and receipt imports remain available.

Validation:
- XcodeGen succeeded.
- iPhone 18 Pro iOS 27.2: build, 295 Swift Testing tests, XCTest performance test,
  Today navigation and hidden-feature navigation passed.
  Result: `/tmp/namillam-hide-v2.xcresult`.
- Manually opened the updated Today and Home screens in Xcode on iPhone Duo
  iOS 27.1. Confirmed three Today sections and Home actions beside the decorative
  residence overview, with no room/floor or care controls.
- Three legacy room/layout UI tests are explicitly skipped while the feature is
  hidden. Remaining navigation/survey tests were adjusted to the v2 scope.
- No App Store/TestFlight upload performed; live v1 remains unchanged.
- Final app code: all 295 unit tests passed on Duo iOS 27.2 as well. That run's
  wide-layout UI check failed because the simulator remained folded/compact
  (confirmed from its screenshot). It is not recorded as an overall pass.
  Result: `/tmp/namillam-hide-v2-final.xcresult`.
- Open Duo iOS 27.1: both the wide Home receipt/pantry navigation check and the
  hidden-feature check passed. Result: `/tmp/namillam-hide-duo-open.xcresult`.
  The wide check now explicitly skips unsuitable compact windows.
- Final wide-test precondition change compiled and the open-Duo dark workflow
  passed again: `/tmp/namillam-hide-duo-verified.xcresult`.
