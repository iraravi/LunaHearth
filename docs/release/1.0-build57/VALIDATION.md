# Version 1.0 (57) — visual welcome and setup

September 16, 2026. See ADR 046 for scope and privacy. No schema or household-data migration; no new permissions or network services.

- XcodeGen generation and signed device Release build succeeded. Product Info.plist reports build 57 (`/tmp/luna57-device.log`).
- 240 unit tests in 44 suites passed (`/tmp/luna-welcome.log`). Initial first-run UI test failed because a launch-argument preference overrode persisted completion. Replaced that test-only override with a DEBUG-only reset flag, then verified completion survives relaunch.
- iPhone: setup completed/skipped progress regression and welcome/replay tests passed (`/tmp/luna-welcome-ui.log`).
- Final artwork: welcome/relaunch and large-text replay passed on iPad (`/tmp/luna-welcome-final-ipad.log`) and iPhone (`/tmp/luna-welcome-final-phone.log`).
- Final iPad receipt and large-text iPhone receipt screenshots inspected. Captures: `docs/visual-review/welcome-guide/`. Physical VoiceOver and Reduce Motion manual checks remain unperformed.
- Build 57 installed directly on Ravi’s iPad and Ravi’s iPhone. No uninstall, reset or data deletion. Both launch attempts were blocked because the devices were locked; unlock and open manually.
- No TestFlight upload or App Store submission.
