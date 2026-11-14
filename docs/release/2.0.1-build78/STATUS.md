# Nam Illam 2.0.1 (78) — submission preparation

Branch: codex/virtual-pantry. Public version 2.0.0 remains unchanged.

## Included changes

- Existing home/fridge/pantry animations and receipt improvements from build 77.
- Portrait-specific full-height home artwork shows the office, kitchen and shopping area on regular iPhones.
- Compact room controls replace large stacked rows at standard text sizes; large accessibility text keeps full rows.
- Removed floating item icons from the closed fridge door. Saved items appear on interior shelves after opening.

No persistence model, network, permission or household ownership changes.

## Current verification

- XcodeGen and build-for-testing succeeded: /tmp/NamIllam78-build.log.
- 339 unit tests in 65 suites passed on the final source: /tmp/NamIllam78-final-tests.log.
- Final UI checks, source recording, screenshots and Release archive in progress.
- App Store Connect 2.0.1 draft created and verified as Prepare for Submission.
- Release-note editing is blocked by Mac input reporting noWindowsAvailable, even after user confirmed unlocking. Draft text is saved locally in metadata/.
- No App Review submission or public release performed.

## Pending

Complete UI validation; export and inspect App Store media; upload build 78 using App Store Connect distribution (not TestFlight Internal Only); upload/select media; save metadata; verify draft. Build 77 cannot be used for public review because it was uploaded Internal Only.

## Verified update

Build 78 archive and App Store Connect upload succeeded. Apple processed it. Assigned to LunaHearth Beta and verified `Testing`, 4 testers and 23 group builds. Final source checks passed (339 unit tests, phone UI flows and iPad screenshot capture). Newer regular-iPhone Inventory entry correction and refreshed media are tracked separately under ../2.0.1-build79/; build 78 does not contain that correction. Public submission remains pending.
