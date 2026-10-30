# Dark-mode button review

Scope: shared controls and main native app surfaces, following reports of unclear dark-mode buttons. No model, persistence, permissions or networking changes.

Changes: dark shared actions use opaque backgrounds, explicit enabled/disabled label colors, visible capsule boundaries and pressed feedback. Setup, meal and sharing prominent actions share these styles. Dashboard card and category-filter boundaries are strengthened. Light-mode button treatments are preserved.

Asset checks: dark ink/surface contrast is about 13:1, muted/surface about 7.95:1, and accent/canvas 10.04:1 or higher across the feature palettes checked. These solid-color calculations do not certify all rendered UI states or glass toolbars.

Validation passed: simulator build, 287 Swift Testing tests plus the performance XCTest, and six targeted UI tests. The screen survey covered Today, Calendar, Home, tasks, meals, floor plan, expenses, home care, More/preferences/privacy/connections/family, plus receipt review, shopping forms/tools, pantry and welcome at large text sizes. No physical-device or comprehensive VoiceOver audit has been completed.


Visual inspection: reviewed captured Today, Calendar, Home, tasks, meals, floor plan, home care, More, preferences, privacy, connections, family, Pantry and both enabled/disabled Shopping controls. Primary actions have strong dark-on-light labels; secondary actions have bright text and defined outlines. Large-text tools remain horizontally scrollable. The expense survey screenshot caught a navigation transition, so it is retained as evidence but is not a clean visual approval for that screen. Native toolbar and tab-bar glass remain system-managed. Deep permission sheets, every populated/error state, and every device size are outside this targeted pass.

Evidence: /tmp/luna-dark-build2.log, /tmp/luna-dark-test.log, /tmp/LunaDarkControlsTests.xcresult. Representative screenshots are saved beside this report. The run succeeded despite simulator/toolchain diagnostics (including a simctl lookup warning during teardown) and existing frame-dimension warnings. No TestFlight upload was performed.
