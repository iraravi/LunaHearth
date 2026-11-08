# Expanded regression review

Scope: recent receipt-to-shopping/pantry/expense changes, AI matching lifecycle, calendar family/source display, and saved receipt images. This is not an assertion that every app screen or every Apple integration is bug-free.

## Fixes

- Chicken stock, beef broth and bouillon now classify as everyday essentials; meat seasoning/rub classify as spices. Meat names remain meat and plant-based qualifiers remain excluded.
- A cancelled AI shopping-match task no longer clears the active/loading flag of a replacement task. Existing snapshot validation and cancellation checks still prevent stale suggestions from authorizing record changes.
- Receipt sidecars reject empty/non-JPEG data and dimensions outside the compressed-image contract before saving or displaying. Read failures use the existing recoverable viewer error path. UI fixture uses an explicit renderer scale so its pixel dimensions do not depend on simulator density.

Entities: no schema or persistence mapping changes. Pantry category changes are derived presentation only. Image validation changes local file handling; no network requests or new permissions. All matching and transaction checks remain usable offline. Existing image files are not deleted on validation failure.

## Added regression coverage

- Two receipt rows cannot claim one shopping entry; no partial expense, purchase or pantry write.
- A completed shopping entry invalidates an earlier AI approval; whole-review rejection remains atomic.
- Recent purchase window includes seven calendar days, excludes eight, in both directions around DST dates; invalid dates are excluded.
- Empty/corrupt receipt sidecars fail rather than yielding a blank preview.
- Prepared meat products, plant-based alternatives and raw mutton category boundaries.

## Release gates

Physical two-device CloudKit family assignment/notification propagation and on-device Foundation Models accuracy still require acceptance testing. Existing Duo receipt-sheet scroll verification remains unresolved; see `2026-11-07-receipt-calendar-fixes.md`. No public release readiness is claimed until that gate is closed. No upload or submission performed by this review.

## Results

- XcodeGen and iPhone 18 Pro iOS 27.2 simulator build passed.
- All 315 Swift Testing tests in 59 suites passed, plus the grocery performance XCTest. Unit coverage includes persistence, matching, calendar delivery, assignment routing, backups and scan cancellation. Log: `/tmp/namillam-regression.log`.
- iPhone landscape calendar family tasks/named sources passed (97.999s); receipt Mutton match and unknown-quantity Pantry save passed (59.291s).
- Initial image UI test failed because its uncompressed test JPEG inherited the simulator's 3x renderer scale. Updated DEBUG fixture to 1x (400x600 pixels). This fixture correction does not bypass production validation. Corrected rerun recorded below.
- AI request lifecycle fix was code-reviewed; actual Foundation Models response quality and device cancellation timing were not exercised by the simulator tests.
- Corrected dark-mode image opt-in/save/open/zoom/remove UI test passed, with a fresh successful build. Log: `/tmp/namillam-regression-image-retest.log`. All targeted tests ultimately passed; the initial combined run's failure is retained above rather than represented as a clean first run.
