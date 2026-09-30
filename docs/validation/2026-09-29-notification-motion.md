# Notification arrival and purchase feedback

Implemented presentation changes for existing task/shopping assignment notifications and purchase completion. Added strict assignment notification parsing with household identity checks, a targeted arrival banner/scroll, and persistent dismissible purchase confirmations. Network refresh no longer blocks opening the assignment sheet. Notification delivery remains existing CloudKit background refresh plus local alerts, with no guarantee of immediate delivery.

No data-model, CloudKit schema, notification permission or household-write changes. Confirmations are emitted only after successful local purchase writes, show persisted stock amounts when available, and do not imply remote sync completion. Motion is a short transition/symbol effect only; Reduce Motion is static and no timed auto-dismiss is used. Existing native compact and expansive navigation is retained.

Two unit tests cover route identity and malformed/non-assignment notifications. UI fixtures inject synthetic arrival routes in DEBUG only; they do not send notifications or use real iCloud. Reduced-motion UI fixtures exercise the static component path; production reads the system accessibility setting.

Validation completed:

- XcodeGen project generation and build passed.
- Full Swift Testing suite: 269 tests in 50 suites passed, plus the existing XCTest search performance check. Final log: `/tmp/luna-motion-ipad-final.log`.
- iPad Pro 13-inch (M5): three UI tests passed, covering both assignment destinations with motion enabled, a notification belonging to another home, and purchase confirmation followed by persisted pantry quantity verification.
- iPhone Duo simulator: two UI tests passed, covering both assignment destinations with large text/reduced motion and purchase confirmation/restock. Final log: `/tmp/luna-motion-duo-retry.log`.
- Initial arrival checks exposed missing public-configuration/AI environment dependencies on app-level notification sheets. Those dependencies now live above the sheets; reruns passed.
- Visually reviewed the iPad assignment sheet. The Duo default XCTest screenshot was black; explicit `simctl io ... screenshot --display=primary-1` captured the active display successfully, and its large-text arrival sheet was reviewed. The inactive `primary` display remained black. Capture: `/tmp/luna-duo-primary1.png`.
- `git diff --check` passed.

These are synthetic notification-route tests, not live APNs/CloudKit delivery tests. They do not prove physical-device delivery timing, animation smoothness, or physical folding/posture behavior. No new posture API is used. This change has not been distributed to TestFlight.
