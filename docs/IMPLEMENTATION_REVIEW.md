# Implementation review — September 11, 2026

Current September 12 update: Home now has contextual room/item creation and setup can create a first room atomically. Optional **manual private CloudKit backup/restore** is implemented; live cloud verification still requires team/container provisioning. Earlier sections describe prior milestones. See [ADR-006](adr/006-private-cloudkit-backup.md), [Home flow](HOME_FLOW.md), and [CloudKit setup](CLOUDKIT_SETUP.md).

## Review findings addressed

The original repository was an unvalidated scaffold. Onboarding wrote only a preferences flag, so reaching Today did not imply a saved household existed. Today, Calendar, and Home showed fictitious data. Quick Add, room creation, invitations, and several navigation destinations were inert. The store configuration also relied on automatic CloudKit inference despite the explicit local-first ADR.

This implementation replaces those paths with saved records, transactional mutations, input validation, real summaries, and explicit unavailable-feature copy. Onboarding now depends on a successfully loaded household, so relaunch restores the local household rather than trusting a separate boolean. Store-open failures offer retry instead of showing empty onboarding over inaccessible data.

## Affected domain and privacy

Household, HouseholdMember, FamilyEvent, HouseholdTask, GroceryItem, MealPlanEntry, HomeFloor, Room, HomeAsset, Warranty, and MaintenancePlan now have working creation paths. Home and planning records are editable. Tasks and groceries support reversible completion. Planning records can be deleted after confirmation.

MaintenanceHistory is a new normalized entity with a stable UUID, household ID, plan ID, completion instant, and creation/modification timestamps. Completion and rescheduling save together. Shopping items are created only through an explicit button, and duplicate open replacement items for the same asset/name are suppressed.

No network path, analytics, runtime dependency, permission request, login, or household ownership change was added. SwiftData uses `cloudKitDatabase: .none`. Existing Apple integration skeletons remain disconnected from the UI. CloudKit record mapping, tombstones, conflict handling, and sharing must be implemented before enabling collaboration. Local planning deletion is currently a hard delete; assets and their histories have no deletion flow.

## Local architecture

`LocalHouseholdRepository` owns a dedicated main-actor ModelContext with autosave disabled. Mutations validate household references and save explicitly; write failures roll back. Data used by views stays on the main actor. Reads are scoped to the active household, though the initial adapter fetches entity sets before filtering; predicate-based fetching and pagination remain scalability work.

Deterministic name, event-range, date-boundary, and recurrence logic is in Domain. Today reads repository projections rather than sample data. Calendar includes events overlapping the selected day, including events starting the prior day. Unscheduled tasks remain in All Tasks, and completed tasks are excluded from due summaries.

## Schema and migration considerations

`MealPlanEntry.dateKey` is an additive optional property containing a Gregorian `YYYY-MM-DD` civil date. The original `date` field remains for compatibility. New records set both; editing reconstructs the selected civil date in the current zone. Legacy nil keys are filled on first load using the calendar day visible on that device at upgrade, because the scaffold stored no original time zone. Once filled, later travel does not shift the meal. A test covers this backfill without changing record identity.

`MaintenanceHistory` is an additive model. There is no destructive migration or store reset on upgrade. SwiftData handles the additive schema; full on-disk migration coverage against an archived pre-upgrade application remains a release gate.

## Build and test validation

- XcodeGen 2.46.0 generates the Xcode project successfully.
- Swift 6, strict concurrency complete, and iOS 18 deployment remain enabled.
- iPhone 17 Pro is unavailable on this machine; validation uses iPhone 18 Pro with the installed iOS 27 simulator runtime.
- Simulator build and all 17 Swift Testing tests across 3 suites pass. The final run completed successfully on September 11, 2026.
- Shell syntax validation and documentation checks pass.
- Xcode emits the informational App Intents metadata-extraction warning because no App Intents implementation exists.
- Automated visual inspection was attempted but the computer-control integration could not open Device Hub. No visual QA or iOS 18 runtime validation is claimed.

Reproduce with `./scripts/verify.sh`; use `SIMULATOR_ID` to choose another installed simulator. Logs from this run are in `/tmp/luna-verify.log` and `/tmp/luna-final.log`; derived products are in `/tmp/LunaHearthDerivedData`.

## Remaining roadmap and release limits

This build implements the initial offline product paths, not every acceptance criterion in CODEX_TASKS.md. In particular:

- Repository responsibilities should be split as features grow; document metadata CRUD remains deferred with file lifecycle work.
- Quick Add is a manual structured form. The existing rule parser is a no-inference fallback; generative parsing is not connected.
- Event recurrence, task recurrence, family routines, advanced member management, calendar export/overlay, and comprehensive date editing semantics remain follow-ups.
- Home still needs user-controlled ordering, purchase-date/price fields, archive/recovery, full warranty ranges, and document associations.
- Document vault, OCR, RoomPlan, Foundation Models, CloudKit sync/sharing, export, notifications, widgets, and App Intents are deferred.
- The app uses Dynamic Type, native forms, labels, confirmation dialogs, and identifiers for critical flows. VoiceOver, large-text, compact/expansive navigation, and minimum-OS device QA remain release gates.
- The app icon is a neutral build placeholder, not final branded artwork.

The workspace has no `.git` directory, so no commit, branch, or pull request was created.

## Visual refresh follow-up

The second pass replaces generic presentation with a cohesive monochrome illustrated design across onboarding, Today, Calendar, Home, Lists, More, and Quick Add. Domain entities, schema, permissions, and network behavior are unchanged. New local resources are three static decorative images and eight adaptive semantic colors. See `DESIGN_SYSTEM.md` and `ARTWORK_PROVENANCE.md` for design tokens and source prompts.

The app's UI test target uses an isolated in-memory store through a DEBUG-only launch flag; normal launches still use the existing on-disk store. Light/dark and large-text overrides affect only test launches. The added tests capture real simulator screenshots and exercise setup and task creation; visual QA results are reported in the task response.

The user's subsequent preference for an Uber-inspired theme superseded the warm palette: that pass used black/white/gray semantic colors, bold system type, direct labels, and grayscale illustrations. Original image assets and generation provenance are retained.

Monochrome pass validation: simulator build, 17 Swift Testing tests, and 2 XCTest UI flows all passed on iPhone 18 Pro / iOS 27. Final captures are in `docs/visual-review/`; result bundle: `/tmp/LunaHearthMonoFinal.xcresult`. Visual review corrected artwork sizing, clipped list headers, onboarding CTA placement, and large-text primary-button wrapping.

## Colorful graphics correction

The clarified direction retains black-and-white interface surfaces and primary controls, with full-color illustrations and category icons. Three new bundled graphics replace the earthy artwork: cobalt living room, bright groceries, and colorful planning objects. Grayscale rendering is removed. Five adaptive accent colors distinguish decorative icon badges and summary symbols in light and dark mode; labels continue to identify every category without depending on color.

Affected domain entities: none. Persistence, schema, permissions, navigation, and offline behavior are unchanged. Images are static app resources with no runtime network requests. Generation used only generic illustration descriptions; no household content was supplied. Prompts and asset paths are in `ARTWORK_PROVENANCE.md`.

Color refresh validation: simulator build, 17 Swift Testing tests, and both XCTest UI flows passed on iPhone 18 Pro / iOS 27. Result bundle: `/tmp/LunaHearthColorFinal.xcresult`. Updated screenshots are in `docs/visual-review/`.

## Manual home and room builder

Affected entities: HomeFloor (existing selection/creation), Room (additive optional geometry), HomeAsset (existing links preserved). The new Home workspace creates and edits rectangular room layouts with presets, dimensions, floor-local coordinates, open-space placement, overlap validation, 2D plans and rotatable 3D cutaways. SwiftUI Canvas projects the saved 3D vertices directly, with no rendering dependency, model downloads, camera access, or network traffic. No new root tab or minimum OS change.

Privacy: dimensions and positions are stored only in local SwiftData. They describe a floor plan, not geographic tracking. Save is explicit and atomic; Cancel discards changes. Existing rooms without dimensions stay unplaced. The room list and native steppers provide non-visual and non-drag alternatives. Geometry validation and persistence/link preservation have dedicated unit tests, with a UI creation/edit flow.

Validation: generated the project and built on iPhone 18 Pro / iOS 27. All 22 unit tests and 4 UI flows passed in `/tmp/LunaHearthLayoutFinal.xcresult`. The decimal-edge placement refinement passed the complete unit suite and home-creation UI flow again in `/tmp/LunaHearthPlacementFinal.xcresult`. Appearance checks explicitly apply the DEBUG-only text-size override inside the editor sheet, so large-text captures exercise the sheet rather than only the underlying screen. No test preference affects production or device settings. Simulator previews are in `docs/visual-review/home-layout.html`.

Final editor layout/appearance checks passed in `/tmp/LunaHearthLayoutAccessFinal.xcresult`, including the expanded preset cards and scrolled accessibility measurement fields.

Measurement rows now stack their labels above controls at accessibility sizes. The final build and appearance flow passed in `/tmp/LunaHearthLayoutVerified.xcresult`; updated captures include scrolled measurement fields.

## Direct room dragging

Room geometry and schema are unchanged. The 2D floor workspace now uses interactive SwiftUI room tiles with transient gesture previews, 0.25 m grid/nearby-edge snapping, selection, zoom, Fit rooms, and accessibility move actions. Drop commits through the existing validated local repository; overlaps and failed saves revert to persisted geometry and show a message. Cancelled gestures discard transient state. The 3D workspace exposes an Arrange rooms action. No permissions or network access were added.

An independent browser demo is available at `docs/visual-review/interactive-layout.html`; it uses only generic sample rooms, never household records. Local-file browser automation was blocked by the browser URL policy, so no browser interaction verification is claimed for that artifact.

Drag validation: 23 unit tests passed, including movement snapping/clamping. The existing three non-drag UI flows passed; the corrected room-builder UI flow passed in `/tmp/LunaHearthDragGesture.xcresult`, exercising a rejected overlapping drop, a successful saved move, and reopening the room editor. The initial drag UI failure was caused by a container accessibility identifier overriding room identifiers; the container identifier was removed. Room-specific error messages now expose validated layout errors instead of a generic save failure. Browser demo code-level checks covered parsing, snapping, overlap rejection, add, undo, and invalid edits; no browser-level verification is claimed.

## 360-degree orbit follow-up

The Home workspace and room editor now wrap the projected geometry in a direct-manipulation camera view. Horizontal drags orbit with angle wrapping, vertical drags adjust a bounded elevation, and interrupted gestures discard camera deltas. Projection and visible cutaway walls update with the camera. Camera changes do not modify Room or HomeFloor records; no schema, storage, networking or permission changes were needed.

The separate browser preview now provides pointer orbit/tilt, sliders, rotation buttons, keyboard arrows and reset, using camera-dependent projection and room depth ordering. Code-level stub-DOM tests cover a full revolution, pointer orbit/tilt, unchanged room geometry, and reset. Browser URL policy continues to prevent local-file browser automation; no browser-level verification is claimed.

Orbit validation: XcodeGen generation, simulator build, 24 unit tests, and all 4 UI flows passed on iPhone 18 Pro / iOS 27 (`/tmp/LunaHearthOrbit.xcresult`). The room-builder flow performs an actual 3D orbit/tilt drag and asserts the accessible camera value changed before exercising room placement. Rotated-screen capture: `docs/visual-review/18-Home-Rotated.png`.

## Home end-to-end clarity

Home now emphasizes rooms and belongings, with explicit create actions and contextual room/item lists. Room details prioritize adding and viewing items; layout and room editing live under Room settings. Contextual create/edit sheets keep their entry type fixed, display the selected room for new items, and retain all existing validation and save-error behavior. Item details expose explicit warranty and maintenance actions.

Affected entities: existing HomeFloor, Room, HomeAsset, Warranty, MaintenancePlan/History, and replacement GroceryItem links. No schema changes or new external access. Everything uses the existing offline repository; no permissions are requested. The full UI flow covers household setup → floor → room → item → warranty → recurring maintenance → completion → replacement groceries. A fresh-repository integration test verifies the hierarchy and care links survive reload after an item moves rooms. Existing drag/orbit UI coverage remains in the normal suite.
