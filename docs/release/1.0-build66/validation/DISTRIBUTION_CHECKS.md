# Distribution preparation checks — October 3, 2026

Scope: current checkout, version 1.0 (66), India-only draft. No app behavior, household entities, data schema, permission flows or networking changed in this preparation. The calendar UI test now handles the existing optional overlap confirmation. Simulator fixtures use fictional, in-memory household data and fake Apple integrations.

## Build and automated checks

XcodeGen generation and iPhone simulator build succeeded. Xcode 27.1 (27A9269), iOS 27 simulators. Deployment target remains iOS 18; execution on iOS 18 is unverified.

- iPhone 18 Pro Max: 272 Swift tests in 51 suites passed; one performance XCTest passed.
- Initial iPhone UI run: 11 of 12 cases passed. The linked-calendar case recorded two failed assertions because its clock-dependent appointment could trigger the existing overlap confirmation. This was a test-driver omission, not evidence that the app failed to save after confirmation.
- Corrected linked-calendar case: passed in a focused rerun. The test explicitly selects **Save anyway** when the overlap dialog exists, after creation and editing. Other successful cases were not repeated because this change only affects the calendar test.
- iPad Pro 13-inch (M5): build and all 12 selected UI cases passed, including the corrected calendar case. Across both simulators, all 24 selected device/case combinations have a passing result after the focused phone rerun.

Evidence bundles (local temporary paths; preserve separately if long-term raw evidence is needed):

- `/tmp/LunaDistribution66Oct03/phone.xcresult` — original run, including the recorded calendar failure and passing screenshot case.
- `/tmp/LunaDistribution66Oct03/phone-calendar-fixed.xcresult` — corrected calendar case, successful.
- `/tmp/LunaDistribution66Oct03/ipad.xcresult` — iPad run.

The 12 selected UI cases cover store screenshots, receipt linking without duplicate restock, large-text receipt review, storage-open failure recovery, measured shopping restock, monthly expenses, linked calendar, Siri draft deep link, family-week large text, help large text, demo Reduce Motion, and Today selection/form retention during rotation. This is a selected release suite, not every UI test in the repository.

## Asset and document checks

- English listing fields pass configured App Store text limits; see `metadata-lengths.json`.
- App icon: 1024 × 1024 PNG, no alpha channel.
- Four HTML drafts have language and viewport declarations and valid local links; see `website-checks.json`. Browser URL security policy rejected local-file navigation, so rendered website review is incomplete. No alternate route was attempted.
- Phone screenshots were visually inspected: real native UI, fictional household, legible content, no keyboard/error overlay. Store samples currently display USD; India-only availability does not change the sample household currency.
- All 12 screenshots packaged and visually inspected. iPhone: 1320 × 2868; iPad: 2064 × 2752; all opaque and unretouched, with hashes in `screenshots.json`. iPad text/actions are legible with no blocking overlays; shopping/pantry/calendar have substantial unused space with the small sample dataset. Normal below-fold scrolling remains visible. This is capture review, not a claim of full visual/accessibility acceptance.
- Draft privacy text includes the implemented optional CloudKit/public configuration behavior and local diagnostics; publisher, effective date, contact and support retention facts remain unconfirmed. These drafts are not a completed privacy declaration or legal approval.

Screenshot packaging completed successfully; shell syntax, Python compilation and `git diff --check` passed. The capture script now selects the output directory and gallery version/build from the current project instead of overwriting build 54 materials.

## Limits and release decision

App Store Connect redirected to sign-in, then desktop access was blocked by device lock. No current live distribution fields or India availability were verified or changed. No new binary was uploaded and no public submission was made.

Build 66 remains a beta reference: its in-app privacy policy explicitly says Draft. Finalize publisher details and policy, update the app, increment the build, revalidate and upload the final public candidate. Finish the physical-device acceptance checks in `docs/RELEASE_READINESS.md`. Mocked integration tests and screenshot review do not verify production CloudKit, real EventKit permissions, remote notification delivery, spoken Siri, full VoiceOver behavior, or on-device AI quality.
