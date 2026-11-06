# Navigation review — v2

## Scope and behavior

Review the existing Today, Calendar, Home and More navigation, setup activity destinations, meal planning links, and modal boundaries. Four root tabs remain per ADR 041. Native push/back and sheet transitions remain in use; no custom zoom or forced animation is added.

- All six setup activities now open their destination directly instead of jumping the guide to a separate action panel.
- Returning to the setup guide retains the selected activity. Initial selection is computed only once; completing an activity exposes an explicit Continue action.
- Meal ideas exposes manual meal entry beside the planning controls, before optional suggestions/reminders. Weekly planning inherits the selected date.
- Calendar → Family week → full meal planner now carries the selected date through the journey instead of unexpectedly returning to today.
- Calendar date-picker expansion and meal-result scrolling use short ease-in/out transitions, disabled when Reduce Motion is enabled.
- The expansive Home dashboard has one setup checklist entry, removing duplicate focus targets.

Affected entities: presentation of existing setup progress, meals, pantry, shopping, expenses, tasks and family profiles. No model, sync, privacy, networking or permission changes. All routes remain usable offline, subject to the existing optional integration capabilities. Existing saved data is preserved.

## Validation

XcodeGen generation and final iPhone 18 Pro / iOS 27.2 simulator build passed. The 295 Swift Testing tests in 55 suites and the grocery performance XCTest passed. Nine targeted UI tests passed across the two runs: FourTabsAndHomeReminders, GuidedSetupLargeText, GuidedSetupSavesProgressAndKeepsSkipsSeparate, HomeMealsCardOpens, SetupActivitiesOpenDirectlyAndReturn, TodayPlanningRetainsSelectionDuringRotation, MoreRedesignNavigation, PrimaryNavigationRoundTrips, and PrimaryNavigationRoundTripsWide.

The first run exposed an obsolete test expectation for the warranty horizon setting, hidden by the prior v2 product decision. The test now verifies the current setup entry and absence of that control; the corrected test passed in the final run. The final round-trip tests verify the latest Calendar/meal changes in portrait and landscape, including manual-entry cancellation, tab-state retention, and the family-week-to-meal-planner date handoff. Dark appearance and Reduce Motion are enabled for these round trips. The large-text setup screenshot was inspected.

This is a targeted navigation review, not a full UI-suite or physical-device frame-rate audit. Actual Duo posture changes and physical-device interactive back gestures still need hands-on beta feedback. No TestFlight upload or production release is part of this change.

Logs: `/tmp/namillam-navigation-build.log`, `/tmp/namillam-navigation-tests.log`, `/tmp/namillam-navigation-final-build.log`, `/tmp/namillam-navigation-final-tests.log`. Final result: `/tmp/NamIllamTodayV2/Logs/Test/Test-LunaHearth-2026.11.06_17-32-14--0600.xcresult`.
