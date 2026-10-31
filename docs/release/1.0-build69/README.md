# Nam Illam 1.0 (69)

## Changes

- Receipt review shows the merchant, proposed total and scanned items with individual pantry selection and concise Add all / Clear selection actions. Pantry changes remain opt-in and require final confirmation.
- Receipt totals use explicit labels, handle additional currency and grouping formats, and leave conflicting totals for review. Existing linked purchases are protected from duplicate stocking.
- Improved dark-mode receipt confirmation, accessibility-sized purchase forms, and action wording across the app.
- Expansive Home uses two independently scrollable areas: household actions and the saved room layout. Compact and accessibility layouts stay stacked. Room editing survives layout transitions; selected-floor state resets when the household changes.
- Updated public app wording to Nam Illam and bundled the owner-confirmed privacy policy. Existing bundle, storage and CloudKit identities remain unchanged.
- Added a keyboard Done action to the Notes draft editor.

## Scope and privacy

Affected entities: expense proposals, receipt line selections, pantry links, home/floor/room presentation and support text. No schema migration, new permissions, new network services or runtime dependencies. Household changes continue to save locally first. Recognition results and approximate room layouts require user review.

## Validation and distribution

Final results and TestFlight status are recorded in STATUS.md. Earlier UI evidence is in docs/validation/2026-10-30-ui-review and docs/validation/2026-10-30-duo-workspace.

Simulator checks do not replace physical-camera receipt testing, VoiceOver use, older supported OS acceptance or two-account iCloud testing. This is a TestFlight release, not a public App Store submission.
