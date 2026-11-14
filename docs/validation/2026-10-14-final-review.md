# Final UI, accessibility and release-copy review — October 14, 2026

Status: scoped code, visual and automated verification complete; release gates remain open. Public submission is not approved by this report.

## Scope

Read AGENTS.md, design guidance, ADR-009 reminder ownership and existing privacy/legal release records. Reviewed Home 2D/3D controls and measurements, onboarding, Help, privacy and permission text, custom scrolling/motion, semantic color assets and existing release blockers. Preserved existing uncommitted work. No schema, household ownership, service, dependency, permission scope or network change was introduced.

## Confirmed changes

| Finding | Correction | Verification |
|---|---|---|
| Hard-coded black room names, selection outlines and grid strokes become difficult to distinguish in dark mode | Use adaptive Hearth ink; retain category colors and explicit move/error text | Dark room-editor screenshot visually inspected; room creation/rotation/drag test passed |
| Canvas room names use a fixed 11-point font | Scale the label relative to the caption text style; retain the accessible room list and dimension controls as alternatives | Dark and accessibility-size editor flows passed; full VoiceOver reading still requires device testing |
| Fit/zoom/edit controls have small label touch areas | Put a minimum 44-by-44-point area inside the interactive labels and add stable fit/zoom identifiers | Added geometry assertions to the existing successful drag/save regression; final rerun passed |
| Two programmatic scroll animations ignore Reduce Motion | Read system Reduce Motion, using the existing DEBUG-only fixture helper for tests, and disable custom scroll animation when enabled | Store-entry and pantry-suggestion flows passed with Reduce Motion fixture |
| Immediate pantry result scrolling can run before the new List section is installed | Use a cancellable task keyed to result availability and yield before scrolling | Reduce Motion regression failed before this adjustment, then passed with the same result-explanation assertions; screenshot inspected |
| Camera/photo prompts mention unimplemented room, warranty/manual and flyer scanning | Narrow purpose text to implemented kitchen-photo and receipt workflows; clarify Apple Reminders ownership | Source call-site audit: two PhotosPicker flows, pantry camera and receipt VisionKit scanner; build/security checks |
| Home layout footer implies device-only storage and does not explain its geometric limits | State that the rectangular layout is approximate, may sync when household sharing is enabled, and is not a construction/safety plan | Copy-only; no change to saving, sharing or room geometry |

## Visual and accessibility evidence

Checked 60 opaque sRGB semantic foreground/background pairs across Hearth, Welcome, Today, Shopping and Inventory in light/dark mode. Minimum contrast ratio: **5.197:1**, above 4.5:1. This does not cover imagery, translucent composites, system controls, disabled controls or every rendered screen. See `2026-10-14-final-review/color-contrast.json`.

Inspected screenshots of the dark room editor and accessibility-size measurement controls. The dark room label is visible, selected preset has an outline, numeric values remain readable and the measurement form scrolls. Native toolbar overlap during scrolling is not described as a full accessibility pass. Selected screenshots are preserved in `2026-10-14-final-review/room-dark.png`, `room-large-measurements.png` and `pantry-reduced-motion.png`; raw attachments remain in `/tmp/LunaFinalOct14/`.

## Validation

- Initial simulator build passed; 276 Swift tests in 51 suites plus performance XCTest passed.
- Initial five phone UI tests passed: room creation/rotation/drag; Help at accessibility size; room editor in dark and large text; offline policy; welcome at accessibility size/dark mode. This run preceded the final Reduce Motion/prompt changes and new touch-target assertions.
- Final phone run passed 276 Swift tests plus the performance test, room-layout touch-target assertions and Reduce Motion store entry. Its pantry case failed and drove the result-insertion correction; the unchanged pantry assertions then passed in a focused rerun. Final normal-motion pantry selection/review/save and full unit acceptance run passed: 276 Swift tests in 51 suites plus the performance XCTest. Eight distinct phone UI cases have passing evidence across the scoped runs; this is not a fresh run of all 114 UI cases on one final binary. Initial failures are retained as evidence, not represented as green runs.
- iPad Help and offline policy checks passed. The room-layout test initially failed because its selector required a bottom TabBar. Changed only that selector to the Home button across adaptive placements; the dark/large-text room test then passed. Three distinct iPad cases have passing evidence across these runs.
- Final unsigned Release build and Analyze passed with no compiler/analyzer warnings found in the log. This does not verify distribution signing.
- Offline security heuristic scan found no matching findings in 196 production Swift files. It is not Sonar, a CVE scan or a security certification.
- Logs/results are in `/tmp/LunaFinalOct14`; portable summaries/source fingerprint are in the adjacent dated evidence folder.

## Runtime warning investigation

The setup-keyboard SwiftUI invalid-frame warning reproduced. Tested replacing the decorative welcome photograph's explicit GeometryReader width with a constrained overlay: the setup/shopping flow passed, but the same warning remained. Reverted that experiment. No speculative photograph fix or warning suppression remains. Xcode also reports diagnostic-collection child-process failures locating simctl and test-runner App Intents metadata notices; test execution status is recorded separately. The SDK/device investigation is still open; successful UI navigation does not resolve it.

## Legal and release-copy boundaries

The draft policy notice remains deliberately visible. Publisher identity, support/privacy contact, public URLs, effective date, retention practices and pricing have not been confirmed. No legal identity, liability waiver, compliance certification, retention period, trademark clearance or privacy declaration was invented. Apple standard-license information is not a substitute for actual publisher rights or jurisdiction-specific review.

The asset catalog contains 15 image sets plus the app icon. This review does not establish commercial-use provenance for all images/generated assets. Keep source/license records and verify product/brand rights before release. No new artwork was introduced.

Public submission still needs the [launch checklist](../LAUNCH_CHECKLIST.md): final policy and support pages; legal/publisher facts; current CloudKit production and physical-device acceptance; real Sonar quality-gate evidence if required by the publisher; final signed/numbered build, TestFlight installation and India-only App Store Connect configuration. This review made no upload or submission.

Apple references checked October 14: [Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility), [Motion HIG](https://developer.apple.com/design/human-interface-guidelines/motion), [App Review](https://developer.apple.com/app-store/review/), [app privacy declarations](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy).
