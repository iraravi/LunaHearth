# Live v2 receipt, pantry and calendar corrections

Branch: `codex/receipt-calendar-reliability`. Based on the current development branch including the separately committed encrypted backup work. No public release, account mutation or user-data cleanup performed.

## Report and causes

The user confirmed that Mutton was created in Nam Illam Shopping and assigned to their wife, not directly in Apple Reminders. This is the reviewed shopping-link flow covered by the fix.

- A shopping request named Mutton and a receipt named PREMIUM MUTTON LEG did not reconcile: shopping links and recent-purchase suggestions used strict ingredient identity. The manually chosen shopping picker also replaced the receipt name.
- Pantry said only the name was required but choosing lb with an empty amount failed measured-amount validation. The placeholder 0 made unknown look like empty stock.
- Apple Calendar connections used picker labels as the only source names outside a Form. The reported layout rendered repeated privacy values without names. Exporting an appointment to Apple is separate from reading selected calendars; hidden was an intentional display default, not an export failure.
- The family calendar board displayed appointments but omitted assigned household tasks.

## Changes and boundaries

Receipt suggestions use a separate bounded rule, not relaxed pantry ingredient identity: known quality qualifiers and a generic meat request can suggest a more specific cut. Different species, distinct specific cuts and preparations do not match. A non-exact shopping suggestion must be selected explicitly; possible recent purchases still require link/new-purchase review. Repository validation rechecks identity, eligibility and single use before the existing atomic transaction. Preserve shopping name, assignment and ID; preserve the receipt name for a new pantry pack. Linking existing purchase history does not silently add stock or change its previous inventory decision. Existing duplicates in live data are not automatically merged/deleted.

Pantry accepts a blank amount as unknown even with a chosen unit; it never interprets blank as zero. Explicit zero still marks a measured pack used up, malformed nonblank values fail, and valid values retain the selected unit. No schema migration.

Calendar connections show each source name and account explicitly, with Not shown in app / Busy only / Event titles. Saved privacy choices remain unchanged. Apple overlays remain separate from household ownership and filters. Wide calendar layouts use left date/person controls and a right family board; compact/Dynamic Type layouts stack. Assigned tasks appear with appointments: due-day work plus unfinished overdue and undated tasks on Today; completed backlog does not repeat. Add task opens an assigned, dated draft. Existing task completion and optional Apple delivery mechanisms remain in use.

Affected entities: GroceryItem, PurchaseEntry, InventoryItem, HouseholdTask and FamilyEvent presentation. No CloudKit keys, persistence schema, household ownership, Apple permission scope, network requests or runtime dependencies changed. Matching works offline without model availability. No broad Apple Reminders scan/completion is added; direct Apple-list items remain a separate integration from Nam Illam Shopping.

## Validation

Automated results and screenshot review are appended after the runs. Tests use synthetic data and Apple-service doubles; they cannot verify a spouse's actual device or Apple's server propagation. Physical two-device acceptance remains necessary before public rollout.

### Verified results

- XcodeGen generation and iPhone 18 Pro iOS 27.2 build passed. iPhone 17 Pro was unavailable; used UUID `45A49484-C4E5-46DA-B35E-9F9009A64117`.
- **305 Swift Testing tests in 58 suites passed**, plus the grocery performance XCTest. Includes new mutton matching/preserved assignment/replay, recent purchase without double stock, rejected species/form mismatches, blank/valid/invalid/zero pantry quantities, and calendar task date/DST boundaries.
- iPhone UI: calendar large text, family tasks + named calendar choices in landscape, and existing receipt linking without restock passed. The initial new receipt test tapped the switch label without selecting stock; the corrected test taps the switch control and asserts its on state.
- Corrected iPhone receipt test passed end to end: reviewed Mutton match, explicit pantry selection, receipt save, opening PREMIUM MUTTON LEG, selecting lb, saving with unknown amount and returning to pantry without the prior error. Log `/tmp/namillam-mutton-retest.log`; result `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.07_22-04-22--0600.xcresult`.
- Duo iOS 27.1 calendar UI test passed (UUID `72F1DB79-E84D-463A-AF40-C89DEAA43B38`). Inspected a direct display-3 screenshot confirming source names/accounts/choices are visible. XCTest's app screenshot capture produces black/cropped images on these multi-display/rotation cases; those attachments are not accepted as layout evidence.
- Initial Duo portrait receipt test could not scroll the review sheet to its match row after orientation changes. Stable-landscape rerun is recorded below. The failed combined runs are not reported as entirely passing.
- Inspected iPhone receipt match and pantry unknown-amount screenshots; retained these plus the Duo source-settings image under `2026-11-07-receipt-calendar/`.

Logs: `/tmp/namillam-fixes-final.log`, `/tmp/namillam-fixes-duo.log`, `/tmp/namillam-mutton-retest.log`. Simulator diagnostics reported duplicate accessibility classes, missing default-toolchain simctl and unavailable debugger metadata; these are not asserted resolved by the app changes. No full app-wide UI-suite run or physical Apple account propagation test is claimed.

### Duo receipt gate remains open

Stable landscape did not resolve the Duo sheet-scrolling failure (`/tmp/namillam-mutton-duo-retest.log`, result `Test-LunaHearth-2026.11.07_22-06-25--0600.xcresult`). An additional experiment scrolling the concrete collection element also could not reveal the match row (`/tmp/namillam-duo-element-scroll.log`); the global helper experiment was reverted. The receipt fixture appears in the accessibility hierarchy, but the sheet remains at its top in the failing test. Do not call Duo receipt interaction verified or this patch ready for public rollout. The complete iPhone UI flow and underlying transaction tests passed, and the Duo calendar flow passed. A direct Duo-device/manual sheet interaction check is still required to distinguish remaining simulator automation limitations from an app interaction defect.

No release/upload is performed. Existing duplicate live records are preserved for reviewed correction. TestFlight acceptance with the user's real receipt and spouse's household remains a release gate.

Manual Duo follow-up opened the synthetic receipt sheet in Device Hub. A scroll attempt did not move it. Direct drag failed twice with the native automation error `noWindowsAvailable`, including after reconnecting the app. This does not establish whether touch scrolling works on a physical Duo; the gate remains open.
