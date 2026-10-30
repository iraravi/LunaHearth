# TestFlight 1.0 (66)

## Changes
- More → Help & guides adds searchable troubleshooting, 16 FAQ answers and responsible-use guidance, available offline.
- Today adapts attention and schedule panels to available space while preserving selection and open forms.
- The connected demo uses five selectable photographic scenes, playback controls and accessible manual stepping with Reduce Motion.
- Privacy policy remains explicitly a draft while publisher/contact and legal review are pending.

## Release scope
Requested October 1, 2026: upload the current app to TestFlight and assign the existing LunaHearth Beta and Ravi Home tester groups. No public App Store submission or new tester invitation requested. No household data, model/schema, permission or sync behavior changes in this release.

## Validation and distribution
- XcodeGen and simulator build passed.
- 272 Swift tests in 51 suites, the grocery search performance XCTest, and three targeted UI checks passed: FAQ/help at accessibility text sizes, demo chapters with Reduce Motion/large text, and Today selection/form preservation during rotation. Log: `/tmp/luna66-validation.log`.
- Signed Release archive succeeded: `/tmp/luna66-archive.log`.
- Archive: `/Users/ira/Library/Developer/Xcode/Archives/2026-10-01/LunaHearth 1.0 (66).xcarchive`.
- Bundle verified as `com.neuralluna.lunahearth`, version 1.0, build 66, minimum iOS 18. Privacy manifest parses successfully.
- CLI upload succeeded October 1, 2026 at 11:29 CDT. Xcode reported “Uploaded package is processing”, “Upload succeeded” and EXPORT SUCCEEDED. Log: `/tmp/luna66-upload.log`. Apple processing subsequently completed; build 66 was available for group assignment.
- After user sign-in, assigned build 66 to LunaHearth Beta (4 internal testers); its group build table confirms Testing.
- Added build 66 to Ravi Home (1 external tester), saved What to Test notes and submitted the beta-review flow with automatic tester notification enabled. Its group build table subsequently confirms Testing.
- Both existing groups are verified as Testing for 1.0 (66). No new tester accounts or public links were created; no public App Store submission was made. Device download/install remains up to each tester.

Existing feature validation records remain in docs/validation. Automated results do not establish real-device VoiceOver, live account synchronization or physical animation smoothness.
