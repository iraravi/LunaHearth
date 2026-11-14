# Nam Illam release — 30 October 2026

## Verified App Store Connect state

App 6811447245, version 1.0. Prepare for Submission; not submitted.
- Name Nam Illam; operator/copyright Vasanthi D.
- Free: ₹0.00 Current Price independently read back. India only: 1 available, 174 not available; future territories off.
- Lifestyle primary, Productivity secondary; age rating 9+ (regional variants set by Apple).
- Privacy declaration Data Not Collected published with explicit owner approval; Apple displayed publication confirmation.
- Public privacy https://neuralluna.com/privacy.html and privacy choices https://neuralluna.com/data-controls.html saved.
- Listing and public support/marketing URLs saved. Private review contact saved; reviewer sign-in not required.
- Six final build-68 iPad screenshots uploaded and verified in App Store Connect. Previous iPhone selection removed from this version (retained in Apple Asset Library); final six iPhone images selected in Finder for manual drag into the large Dynamic Island slot. Upload confirmation pending. Six native Duo screenshots captured, visually inspected and size-validated at 1398 × 2034; not yet uploaded. Eighteen final images available at ../1.0-build68/index.html. Safari file chooser still leaves Upload disabled; manual drag required.
- Build 68 processed and selected; saved and independently re-read. Automatic release after approval currently selected.

## Final candidate 68

User-facing name and permission copy changed to Nam Illam. Bundle/storage/sync identities preserved. Complete published privacy policy included offline, effective 30 October 2026, with user-initiated public policy link. Hostinger Mail, Vasanthi D only, 90-day resolved-support retention (disputes/legal duties excepted).

Simulator build and signed release archive passed. Xcode confirmed build 68 uploaded to Apple at 18:04 CDT. All 287 Swift Testing tests (52 suites), one XCTest performance test and seven targeted UI tests passed. Local heuristic security audit reported no findings; this is not a Sonar/CVE scan. iPad screenshot capture passed. Initial dark screenshots captured navigation transitions; the test capture now waits for transitions, and the repeated iPhone/iPad surveys passed and were visually inspected. Screenshot test initially assumed shelf mode; explicitly selecting it fixed the preference-dependent failure and the rerun passed. Two Apple-list integration UI tests also passed. Final build 68 is selected; submission remains pending screenshot replacement.

## Remaining evidence

Finish iPhone/Duo screenshot upload and final submission validation. Build/archive, screenshot capture and build selection are complete. Actual two-account production sharing/revocation, real camera/permission behavior, notification delivery, VoiceOver and iOS 18 execution require device acceptance evidence; simulator success does not establish those. Trademark clearance is not established by these technical checks.

Website policy, terms and data controls were published on both neuralluna.com and namillam.neuralluna.com and live policy content verified. No DNS/mail settings changed. Mailbox ownership/provider confirmed by owner; inbound deliverability not independently tested.

## TestFlight distribution — 30 October 2026

Build 1.0 (68) assigned to LunaHearth Beta (internal, 4 testers) and Ravi Home (external, 1 tester). Testing instructions saved and automatic tester notifications enabled. Submitted through the beta review flow; the refreshed TestFlight build list now shows Testing with both group badges. Public App Store submission remains separate and pending.

## Unreleased receipt-expense improvements

After build 68 was distributed, improved labeled-total parsing, explicit currency suggestions, expanded amount review, visible opt-in pantry/inventory switches, and final save confirmation. Existing stock is preserved for linked purchases. Build 68 does not contain these changes; archive and distribute a subsequent build before public submission.

Validation: 289 unit tests across 52 suites passed, plus the XCTest performance test. Three UI regressions passed after correcting UI test targeting for switches and nested confirmation buttons: exact total plus selective inventory, existing-purchase stock preservation, and dark mode with large text. Focused expense/receipt unit tests passed again after adding mixed currency code/symbol coverage. Native confirmation screenshot inspected. No schema, permissions or networking changes. Actual customer receipt example remains unavailable, so its exact failure is not yet reproduced.

Receipt visual redesign (unreleased): animated scan summary, total/currency and item-count display, illustrated selectable cards, Add all / Clear selection, and per-item inventory control. Reduce Motion and Dynamic Type supported. Twenty-three receipt/expense tests passed; dark large-text walkthrough and bulk/individual-selection-to-saved-expense UI test passed. Final high-contrast button version rebuilt and its UI test passed again. Screenshots saved in docs/validation/2026-10-30-receipt/. These changes are not in TestFlight build 68.

## Unreleased screen consistency review

Shortened action labels across pantry, shopping, Home, family, meals and alerts. Pantry-photo Add all / Clear selection are visible; shopping purchase sheets expand for accessibility text sizes. Replaced receipt save confirmation with a solid high-contrast review sheet after visual inspection found poor readability in the translucent dialog. No schema, networking or permission changes.

Build passed; ten UI walkthroughs passed with zero failures, covering dark survey, large text, home creation/maintenance, pantry photo, receipt total/selection, shopping and onboarding. Inspected 33 captures. After the final receipt sheet change, rebuilt and reran exact-total/selected-stock and dark-large-text purchase-only save tests; both passed. Final confirmation image inspected. Evidence and limits: docs/validation/2026-10-30-ui-review/README.md. Not yet archived or distributed; build 68 remains the last TestFlight build.


## Unreleased Duo Home workspace

Implemented a geometry-based two-pane Home dashboard inspired by the supplied control-panel reference: household action cards on the left, saved-room 3D preview and room controls on the right. Compact windows and accessibility text retain the stacked Home. Parent-owned editor and camera state survive layout changes. No schema, permissions or networking changes.

Build and two layout unit tests passed. Two open-Duo UI tests passed in light/dark appearance; initial closed-display attempts failed before selecting Open in Device Hub. Compact iPhone Home end-to-end and dark large-text inventory tests also passed. Live Device Hub inspection verified empty/saved-room layouts and closing/reopening an active room editor; XCTest's open-Duo attachments were black and were not used as visual proof. Detailed evidence: docs/validation/2026-10-30-duo-workspace/README.md. Physical-device and VoiceOver acceptance remain separate. Not yet in TestFlight build 68.
