# TestFlight 1.0 (65)

## Changes
- Assignment notifications open the matching task or shopping section with a subtle arrival highlight.
- Purchase confirmation shows the persisted pantry quantity and supports accessible dismissal.
- Reduce Motion, large text, and adaptive iPad/Duo layouts are retained.
- Notification sheets inherit configuration and AI availability correctly; notifications for another home cannot display current-home assignments.
- Includes the on-device AI reliability fixes committed in cc2d82d.

## Validation
269 Swift tests, the search performance XCTest, and five selected iPad/Duo UI tests passed before this build-number-only release change. See docs/validation/2026-09-29-notification-motion.md.
Release archive passed on September 30: /tmp/luna65-archive.log.
Archive: /Users/ira/Library/Developer/Xcode/Archives/2026-09-30/LunaHearth 1.0 (65).xcarchive.
Live remote-notification delivery and physical folding remain unverified.

## Distribution
Command-line upload succeeded on September 30 at 14:34 CDT: /tmp/luna65-upload.log. App Store Connect processing is Complete. Assigned to LunaHearth Beta (4 internal testers) and Ravi Home (1 external tester); beta-review submission completed with automatic tester notification enabled. LunaHearth Beta shows build 65 as Testing. Ravi Home also shows build 65 as Testing. Verified both group build pages on September 30. Both Ravi iCloud accounts are present in the internal group; the no-dot account is also in Ravi Home.

Release bookkeeping commit 29bacda was created locally. Its GitHub push failed because macOS Keychain could not supply credentials; this does not affect the successful TestFlight distribution.
