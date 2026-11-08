# Virtual Pantry

Native SwiftUI optional view for Pantry, enabled by default with a persistent List/Virtual toolbar switch. The original shelf/list view, filtering, search, scan and edit workflows remain available. No root tab added.

## Current full-screen design

Virtual mode is presented as a full-screen cover on compact and expansive devices. The image fills the available screen; no app rail, search, headings, item captions, badges or details panel appears. Closed doors retain the small glass window; tap anywhere on the doors to open. Inside, only actual food icons appear, and tapping one presents the existing pack editor within the cover. Small icon controls provide List, storage selection, Close, and pagination when needed. VoiceOver retains item names and quantities. Empty inventory shows empty shelves. Normal mode retains search, add, receipt scanning and other workflows. Virtual mode browses active packs without inheriting hidden normal-view filters.

## Earlier design and interaction (superseded by full-screen layout)

Bundled generated photorealistic empty refrigerator interior, overlaid with saved item illustrations and labels; empty sections contain no demonstration groceries. Native metallic doors start closed. Tap Open fridge/freezer to reveal saved contents with brief translucent cold mist; Close hides contents and clears the selected pack. Changing storage sections resets the doors to closed. No repeating movie, particle timer or remote rendering. Reduce Motion preserves explicit opening/closing but skips animation/mist; accessibility text uses a scalable item list instead of fixed-size shelf labels. Tap a pack to edit on compact screens, or inspect it in the right-hand detail panel on wide layouts. The detail panel links to existing quantity, restock and used-up controls in the pack editor.

Fridge/Freezer/Cupboard/Other are visual groups. Explicit saved locations take precedence; unrecognized locations stay Other. Otherwise existing offline food categories suggest a visual section. This does not set or change storage locations and is not storage/food-safety advice. Dates, low-stock state and quantities remain the user's saved data. Packs stay separate; nine items per visual page, with bounded pagination and clamping after changes. Search and existing filters apply to both views.

## Domain, privacy, assets

Affected entities: InventoryItem, read-only rendering; all writes use existing InventoryEditor workflows. No schema/migration, CloudKit, permission, third-party runtime, AI runtime or network changes. Illustration is generated during development with the imagegen skill from a generic empty-appliance prompt (no household data). Source: `/Users/ira/.codex/generated_images/01a091aa-8a50-7532-b4c6-1a30885b7335/exec-04426271-3d64-408a-8ca2-da393ff43968.png`; copied into VirtualFridgeInterior.imageset. App uses bundled image and native SF/emoji symbols. Synthetic produce exists only in the DEBUG in-memory UI fixture.

## Validation

- XcodeGen project generation and simulator build passed.
- 332 Swift Testing tests in 63 suites passed, plus the existing performance XCTest.
- iPhone 18 Pro: virtual pantry light, dark, and accessibility/Reduce Motion UI flows passed.
- Duo: light, dark, and accessibility/Reduce Motion UI flows passed. After the final shelf spacing refinement, light/dark checks were rerun and passed.
- Verified opening pack editor, switching storage sections, switching to existing list and back. Domain coverage includes saved location precedence and pagination without dropped/duplicated packs.
- Reviewed actual active Duo display screenshots; XCTest attachment capture can select its inactive display. Screenshot uses synthetic DEBUG data, not household content.
- No physical-device performance profiling or VoiceOver audio audit performed. No TestFlight upload for this feature.

Full suite evidence: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_14-25-40--0600.xcresult`.
Final visual checks: `duo-dark.png`, `duo-light.png`.
Final UI evidence: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_14-28-45--0600.xcresult`.

## Manual door interaction follow-up

The fridge no longer opens automatically. Closed contents are removed from the interactive and accessibility item tree. Open/close controls are also available with accessibility text sizes. No data, schema, or networking changes. Simulator build passed; updated UI regression checks cover closed contents, open, close, reopen, edit, and list switching.

Follow-up validation passed: 332 Swift Testing tests plus performance XCTest; all three Duo light, dark, and accessibility UI tests. Result: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_14-31-09--0600.xcresult`.

## Closed-door glass window

The right-hand closed fridge/freezer door has a small tinted window with a metallic border and reflective highlight. It renders up to three actual saved food icons as a decorative preview; no item controls are exposed until opening. Empty inventory produces an empty window. Uses bundled artwork and SwiftUI, without networking, permissions or additional assets. Reviewed active Duo display screenshot: `duo-closed-glass.png`.

Glass-window validation: simulator build passed; 332 Swift Testing tests, performance XCTest, and Duo light/dark open-close/edit/list UI flows passed. Result: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_14-35-46--0600.xcresult`.

## Full-screen validation

XcodeGen and simulator build passed. All 332 Swift Testing tests plus performance XCTest passed in `/tmp/pantry-full-final-tests.log`; that combined run was interrupted after a UI selector failed on duplicate underlying/foreground List buttons. The UI helper now targets the hittable foreground control. Full-screen container accessibility containment was corrected so child controls keep distinct identifiers. Final Duo light, dark, and accessibility/Reduce Motion UI runs all passed: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_14-45-29--0600.xcresult`. Flows cover closed/open/close/reopen, pack editing, storage menu, list exit and reentry. Active-display visual evidence: `duo-fullscreen-open.png`, `duo-fullscreen-closed.png`. This follow-up was verified on Duo; no new compact-device run or physical-device profiling. Not uploaded to TestFlight.

## Realistic French-door artwork follow-up

Replaced flat generated-in-code metal doors with original photorealistic closed/open assets: dark glass, dispenser, metal drawers, and empty door bins. Upper door halves animate independently; lower drawers remain decorative. Food icons are still generated from saved packs, never baked into backgrounds. Built-in imagegen prompts and asset paths are in `ARTWORK.md`. Active Duo screenshots: `duo-realistic-closed.png`, `duo-realistic-open.png`.

Validation: XcodeGen/build passed; 332 Swift Testing tests, performance XCTest, and Duo light/dark full-screen UI flows passed. Result: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_14-50-46--0600.xcresult`. No TestFlight upload.

## Physical hinge follow-up

Virtual pantry is now gated by an actual UIHingeInteraction observation (iOS 27.1+), isolated in Services/Device/PantryHingeObserver. No device-name or width inference. Regular phones and older OS versions retain the normal pantry and do not offer virtual mode. A transient nil update during hierarchy/display handoff preserves the last known state; unknown status never invents an angle. Closed means exterior; partially/fully open means interior. No tap-to-open controls remain. List mode remains an explicit user choice. Fold updates never write household records, request permissions, or use networking.

Unfolded presentation crops the artwork to the main fridge cavity only, omitting the lower freezer drawers. Closed exterior retains the drawers. Existing generated artwork is unchanged; SwiftUI performs display-only framing.

Domain tests cover closed/partial/full/unknown/unavailable states. Initial integration build, 334 unit tests, and unfolded Duo editor/list flow passed: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_15-04-15--0600.xcresult`. Further phone and fold-transition checks recorded below.

Final checks: regular iPhone 18 Pro normal-pantry UI test passed (`/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_15-05-59--0600.xcresult`). Device Hub manual verification on the latest build: fully open shows only the main interior; Closed switches to exterior on cover display; reopening to partial posture automatically restores the interior without a tap. Captured `duo-hinge-closed.png` and `duo-hinge-interior.png`. This verifies simulator hinge notifications, not physical hardware. The provided Spencer's reference URL returned HTTP 403; existing user-provided refrigerator references were used instead. Not uploaded to TestFlight.

## Fridge and fitted pantry follow-up

- Fridge and Pantry are the primary storage menu choices; Freezer and Other remain secondary so existing locations remain reachable.
- Pantry uses original charcoal slab-door artwork and an empty warm-white fitted interior with metal shelves and pull-out baskets. No wood.
- Food illustrations use shelf contact coordinates and contact shadows instead of centered floating placement.
- Refrigerated zones briefly show cold mist before revealing items. Closing or changing zones cancels pending reveals. Reduce Motion skips the mist and delay.
- Inventory add/edit exposes Fridge and Pantry choices in a visible Store in section. The existing optional location field remains editable for freezer/custom storage; existing values are preserved. No schema changes or network access. Receipt review and purchase-sheet storage controls are unchanged in this follow-up.
- Affected entity: InventoryItem.location, through the existing InventoryDraft save path. Visual posture changes never write household data.

Final verification: XcodeGen generation and simulator build succeeded. Full unit suite: 337 tests / 64 suites passed. Duo UI tests `testVirtualPantryAccessibility` and `testVirtualPantryLight` passed. Logs: `/tmp/pantry-final-build.log`, `/tmp/pantry-final-tests.log`. This work is not uploaded to TestFlight.
