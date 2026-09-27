# TestFlight deployment — September 22, 2026

Version: 1.0 (61). Requested distribution to the existing TestFlight testers.

## Included changes

- Offline Help & guides, contextual screen help, and a recoverable setup checklist.
- Hide AI-only actions when on-device generation is unavailable; keep manual workflows and deterministic suggestions.
- Foreground refresh cancellation and ingredient-matching performance improvements.
- Accessibility identifiers and button semantics for help/checklist navigation.

## Validation

- 246 Swift Testing tests across 47 suites passed; grocery performance tests also passed.
- Help/checklist UI flow passed on iPhone and iPad simulators.
- Accessibility text-size help checks passed on both simulator sizes.
- Release archive succeeded with Xcode 27.1. No physical-device installation is claimed.

Archive: `/Users/ira/Library/Developer/Xcode/Archives/2026-09-22/LunaHearth 1.0 (61).xcarchive`.

Build log: `/tmp/luna61-archive.log`.

## Distribution status

Command-line export failed because Xcode could not load complete account credentials. Reauthentication did not resolve CLI export. Organizer distribution passed account selection and signing, then started uploading the same archive to App Store Connect.

Organizer confirmed “App upload complete” and “LunaHearth 1.0 (61) uploaded.” Upload succeeded. Apple processing completion and tester availability are not yet confirmed. App Store Connect browser requires sign-in to verify and assign groups. No public App Store submission was performed.

## What to test

Open More → Help & guides. Open contextual help from household screens. Hide the setup checklist and restore it from its guide. Check larger text on iPhone and iPad. On devices without available Apple Intelligence, verify manual entry, pantry templates, shopping, and receipt OCR remain usable while AI-only actions are hidden.
