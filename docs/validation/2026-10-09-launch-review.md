# Launch code review — October 9, 2026

## Decision

Public submission remains blocked by publisher/privacy completion and live-device/account acceptance. Use [the launch checklist](../LAUNCH_CHECKLIST.md) as the execution order. No archive, upload, submission or public release was performed in this review.

## Source and scope

Fetched `origin`; local HEAD `daa0eba509c46496c70f748d42f76c8eb113b37c` is two commits ahead and zero behind `origin/main`. Starting source hashes matched the October 4 reviewed manifest. Existing uncommitted changes were preserved. This is a follow-up review of that working tree, not a claim that the remote alone contains the fixes.

Rechecked onboarding geometry, Home drag sizing/navigation, backup publication/account checks and deletion boundaries, local-store configuration/recovery, category cleanup, Calendar delivery ownership checks, notification routing/scheduling, invitation URL validation, public configuration validation/cache/enforcement, privacy text, entitlements and release metadata. Previous import, alert-refresh and navigation regression fixes remain present. No new confirmed production defect was established in these inspected paths. This review cannot prove every possible bug or vulnerability absent.

Inspected the current iPhone Rooms & belongings empty-state screenshot: room creation, floor-plan entry and belongings navigation are visible and legible. This is one screen check, not complete visual/accessibility acceptance.

No household entity, persistence schema, permission, networking or production behavior changed. Public configuration is already covered by ADR 049; it is not new networking introduced by this review.

## Corrections

Fresh compilation exposed warnings in test code:

- `VisualFlowTests` reset device orientation in synchronous XCTest setup, whose override is nonisolated despite the test class annotation. Changed to asynchronous setup and explicitly execute orientation mutation on MainActor. No concurrency suppression was added.
- Inventory restock regression now checks optional quantity directly against the expected empty string. This avoids a macro warning and no longer treats a missing grocery as an empty quantity.
- Invitation handoff fixture unwraps its test URL before assignment, avoiding a redundant-unwrap diagnostic while preserving the assertion.

## Verification

- XcodeGen project generation passed; Xcode 27.1 (27A9269).
- Fresh initial simulator build and full unit run passed: 276 Swift tests in 51 suites plus one performance XCTest. This initial compilation produced the test warnings corrected above.
- Unsigned Release build and Analyze passed on production source, with no compiler/analyzer warnings found in the log. Distribution signing is not verified by this command.
- Final rerun after test corrections passed: 276 Swift tests in 51 suites, one performance XCTest and all three selected iPhone UI cases (Apple-only Reminders creation/completion; Home room/item/warranty/maintenance with rotation; simple home setup and local shopping). Concurrency and assertion compiler warnings no longer appear. The 114-case UI suite was not repeated.
- Offline security heuristic scan: 196 production Swift files; no findings. No CVE database or real Sonar analysis was run. Scanner/project authentication is unavailable; no source was uploaded.
- The previous 114 unique phone UI cases retain October 4 aggregate evidence. They are not represented as a new full-suite October 9 run.

Logs/results: `/tmp/LunaLaunchOct09/units.log`, `units.xcresult`, `release.log`, `final.log`, `final.xcresult`. Portable summaries and source fingerprints are in `2026-10-09-launch-review/` alongside this document.

## Unresolved observations and release requirements

The setup-keyboard SwiftUI invalid-frame warning reproduced again in the October 9 Reminders UI flow. It remains unresolved; source inspection and the source-less XCTest warning did not establish its origin. Do not call it fixed merely because setup completes. Test-bundle App Intents metadata extraction reported that no AppIntents dependency exists; it is distinguished from production compiler diagnostics. Final test execution succeeded, but Xcode diagnostic collection reported that a child process could not locate simctl. This does not turn the run into warning-free evidence.

The app still contains an explicit draft privacy policy. The distribution JSON still has null support URL, privacy URL, copyright, pricing and reviewer contact. These are concrete blockers, not test failures. FAQ/product-guide drafts already exist. India is the confirmed territory request; current App Store Connect fields were not accessible through the available tools and were not verified.

Public configuration documentation records September 26 production deployment, restricted write permissions and a revision expiring October 20. This is historical Console evidence, not fresh ordinary-account write-rejection or signed-device fetch evidence. Recheck production configuration around launch; expiry deliberately returns to bundled defaults.

Minimum iOS 18, real CloudKit two-account sharing and recovery, actual EventKit permission/delivery, push/local notifications, spoken Siri, VoiceOver and on-device AI quality still require device evidence. Final signing/upload/build selection and public submission remain later checklist steps.

Apple references checked October 9: [review preparation](https://developer.apple.com/app-store/review/), [privacy declarations](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy), [submission process](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/).
