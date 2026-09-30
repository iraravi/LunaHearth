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
Command-line upload succeeded on September 30 at 14:34 CDT: /tmp/luna65-upload.log. Apple reports the package is processing. Tester availability is not yet verified.
