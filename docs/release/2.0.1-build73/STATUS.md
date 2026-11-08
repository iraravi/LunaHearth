# TestFlight 2.0.1 (73)

Prepared November 8, 2026 on codex/receipt-calendar-reliability, application source 68de096. Patch version selected for receipt reliability and appearance improvements. No public App Store submission requested.

- Regression validation: 315 Swift Testing tests in 59 suites and grocery performance test passed. Targeted calendar family/source, mutton receipt/pantry and corrected receipt-image UI flows passed. See docs/validation/2026-11-07-expanded-regression.md.
- Signed Release archive succeeded: /tmp/NamIllam-2.0.1-Build73.xcarchive. Verified version 2.0.1/build 73, bundle ID com.neuralluna.lunahearth, and strict code signature validation.
- Command-line upload failed with account/keychain credential errors. Reauthenticated through Xcode and started upload from Organizer; awaiting completion at time of this entry.
- Safari App Store Connect sign-in requires user two-factor verification before tester assignment can be completed.
- WHAT_TO_TEST.txt includes outstanding physical Duo receipt scrolling and two-device family sharing/notification acceptance checks. These remain public-release gates.

## Upload confirmed

Xcode Organizer displayed “App upload complete” and “LunaHearth 2.0.1 (73) uploaded.” Upload succeeded through the GUI. Apple processing, build-specific notes and tester-group assignment are not yet verified because Safari is waiting for two-factor verification. The public App Store version is unchanged.

## Internal testing verified

After user completed Safari verification, Apple processing finished. Assigned 2.0.1 (73) to LunaHearth Beta (4 internal testers); group now shows 18 builds. Verified build status Testing, expires in 90 days. Saved build-specific What to Test notes and reloaded the details page to verify persistence. Build details: https://appstoreconnect.apple.com/teams/278f79ef-d215-47fc-82e0-b88d1239f11b/apps/6811447245/testflight/ios/5114b6b7-01f0-4367-8343-db823cc45db2 .

Internal testing only, consistent with the preceding beta workflow. No public App Store submission or external beta-review request made. Tester installation of build 73 has not been observed.
