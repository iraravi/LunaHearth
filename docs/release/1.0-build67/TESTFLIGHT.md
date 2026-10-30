# TestFlight 1.0 (67)

Requested October 30, 2026: push the native app updates, upload a TestFlight build and assign the existing LunaHearth Beta and Ravi Home tester groups.

## What to test
- Scan a receipt from the camera or selected photos. Cancel/retry a slow scan; check that older results do not replace a new review.
- Review item recognition, including prices with rupee symbols, Rs. and INR. Add any missed item before saving; verify the total, purchase history and pantry changes.
- Check dark-mode action labels, enabled/disabled buttons and category filters. Try larger text in Shopping, Pantry, Calendar, setup and receipts.

## Validation
- Simulator build and 287 Swift Testing tests plus the performance XCTest passed.
- Six dark-mode UI checks passed, covering the main-screen survey, Shopping tools and enabled/disabled forms, Pantry at large text, receipt review/save and welcome at large text.
- Camera conversion/OCR, timeout, cancellation and stale completion tests passed. Actual customer receipts, live camera/iCloud-photo downloads, VoiceOver and live multi-account sync remain device checks.
- Offline heuristic security checks found no flagged patterns; this is not a Sonar scan or full vulnerability assessment.
- No new networking, permissions or schema changes were added by the receipt/dark-mode fixes. Existing previously unreleased native hardening remains in the tested checkout.

## Distribution
Native release commit `4e8a387` pushed to origin/main. Signed Release archive succeeded at `/Users/ira/Library/Developer/Xcode/Archives/2026-10-30/LunaHearth 1.0 (67).xcarchive`; bundle identity, version 1.0, build 67 and iOS 18 minimum verified. CLI export could not load account credentials; Xcode Organizer confirmed “LunaHearth 1.0 (67) uploaded” at 11:57 CDT after account sign-in. Screenshot: upload-confirmation.png. Safari App Store Connect is waiting for Apple two-factor verification, so processing completion and assignment to LunaHearth Beta/Ravi Home remain unverified. No public App Store submission requested.
