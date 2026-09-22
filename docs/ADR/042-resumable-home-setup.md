# ADR-042: Resumable home setup guide

The user requested a step-by-step guide with progress. Home creation remains a single required home-name field, with no room/profile/permission requirements. Its progress introduction leads to the prominent Home setup card and a five-step guide: home, pantry, shopping, planning, and optional sharing. The guide opens the existing feature screens rather than duplicating forms. Pantry guidance points to kitchen templates, receipt scanning and manual entry; sharing can be left local.

Progress is device-local UserDefaults metadata scoped by household UUID, excluded from backups and CloudKit. No household schema or new network/permission access is introduced. Real saved data determines completion, never simply opening a screen. Observed completed milestones are remembered when using the guide; skipped steps are recorded separately and can be revisited. Existing household data may satisfy steps. Progress counts steps reviewed, explicitly separates completed/skipped totals, and does not claim cloud sync success or invitation delivery. No preferences enable services automatically.

The Home card hides after all steps are reviewed; More → Preferences → Step-by-step setup always reopens it. Deleting/consuming records later does not erase already recorded learning progress. Guide navigation remains available offline; actual edits, errors and read-only protection belong to existing destination workflows. Invitations keep their existing root precedence.

Validation covers deterministic ordering, completed versus skipped, malformed persisted values, household scoping, and UI flows for open-without-saving, real pantry entry, skip, and return through Preferences. No live Apple permissions or household data are needed by these tests.

## Build 49 validation — September 15, 2026

- Four HomeSetupProgress unit tests passed (`/tmp/luna49-guide-unit.log`).
- iPhone normal and accessibility-size/dark setup flows passed; the final combined run recorded both phone tests passing in `/tmp/Luna49Complete.xcresult`. The combined run stalled on iPad and was canceled.
- Independent final iPad accessibility test passed (`/tmp/Luna49PadAX.xcresult`); full pantry-save, skip, progress and Preferences re-entry flow passed (`/tmp/Luna49PadFlow.xcresult`).
- Screenshots reviewed on iPhone and iPad, including dark accessibility text. The Home card exposes a single accessibility action; its decorative progress bar cannot intercept taps.
- Signed Release build succeeded (`/tmp/luna49-device-ready.log`). Build 49 installed directly on Ravi's iPhone. Physical iPad installation is pending unlocking the device; installation reported locked after a connection retry. No household data was reset.
- No TestFlight upload for build 49. These targeted checks do not constitute a fresh full-suite, physical VoiceOver, or live CloudKit verification.
