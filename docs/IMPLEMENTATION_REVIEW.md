# Implementation review — September 11, 2026

> Current foundation (ADR-012): local household reminders, shopping, schedules and home records support optional private CloudKit sync and CKShare invitations. Foreground changes sync automatically; live two-account device acceptance is still a release check. Apple Reminders is a separate optional connection. Setup no longer asks for a room. Earlier Apple-only/manual-backup-only implementation notes below are historical. See [ADR-012](ADR/012-live-private-household-sharing.md).



Current September 12 update: Home now has contextual room/item creation and setup can create a first room atomically. Optional **manual private CloudKit backup/restore** is implemented; the selected signing team is now configured and a signed iPhone build passes. Live backup/restore remains a separate device check. Earlier sections describe prior milestones. See [ADR-006](adr/006-private-cloudkit-backup.md), [Home flow](HOME_FLOW.md), and [CloudKit setup](CLOUDKIT_SETUP.md).

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


## Setup and private CloudKit backup — September 12

Setup now offers an optional first room and collapsed optional member entry, keeps Create my home fixed at the bottom, and opens Home after successful creation or restore. Quick Add provides a focused Done keyboard action and scrolling dismissal. The Home flow explicitly links rooms, items, warranties, recurring maintenance and replacement groceries.

Private backup uses the domain service protocol, versioned per-entity values, bounded CloudKit batches, immutable snapshot zones and a change-tag-protected publication manifest. Restore validates the entire graph before one local transaction and refuses to overwrite an existing home. Account, staging and partial failures preserve the local store. See ADR-006 for the privacy review, snapshot limits and file exclusions. Background sync and CKShare collaboration are not implemented.

Validation: XcodeGen generation and simulator build passed. All 31 Swift Testing tests and all 6 UI flows passed across `/tmp/LunaHearthHomeFocused.xcresult` (31 unit + Home E2E and setup/cloud unavailable flows) and `/tmp/LunaHearthHomeAppearance.xcresult` (the remaining 4 UI flows). This includes full room/item/care creation, recurring completion, replacement groceries, separate-store backup restore, malformed backup rejection, dark mode, large text, 2D dragging and 3D orbit. Final captures are linked from `docs/visual-review/home-flow.html`.

The user then selected an Apple signing team. It is preserved in project.yml; the signed iPhone build and CloudKit entitlement/profile checks succeeded. Live upload/restore and production schema deployment are not established by simulator tests or code signing.

Physical-device follow-up: the final Development-environment build installed and launched successfully on the connected iPhone 16 Pro Max. No household backup was sent automatically; the user can initiate the explicit backup action in More. Device build log: `/tmp/luna-device-cloud-final.log`.


## Apple service connections

The user confirmed that live CloudKit backup works. The next pass adds selective EventKit calendar overlays, connected reminder lists with explicit completion, reviewed Calendar/Reminders exports, task deep links, and sharing to Notes/other installed apps. Local household storage/schema and its backup scope remain unchanged. Private external events/reminders are transient presentation data, with per-device opt-in and source preferences. No Calendar or Reminders authorization is requested at launch. See ADR-007 and APPLE_CONNECTIONS.md.

Apple connections validation: simulator build, all 38 Swift Testing tests, and all 7 UI flows passed across `/tmp/LunaHearthAppleConnections.xcresult` and the final unit/Calendar/Connections rerun `/tmp/LunaHearthAppleFinal.xcresult`. The signed device build also passed (`/tmp/luna-apple-device.log`). Simulator UI tests intentionally avoid live EventKit authorization; permission grants, real source selection, provider sync, and Notes destination availability still require user/device checks. Screens 26–27 show the actual app connections and note-sharing draft.

## Automatic task delivery to Apple Reminders — September 12, 2026

Implemented the requested opt-in LunaHearth → Apple Reminders path (ADR-008). New tasks save locally with durable delivery links; title/due/completion updates reuse the Apple record. Connections exposes destination selection, enable/pause, pending/error status and explicit retry. Task details expose status and unlink. Existing tasks remain local unless manually copied. No Apple → household reverse sync or external deletion is implemented.

Validation: XcodeGen generation and simulator build succeeded. `/tmp/LunaHearthReminderSync.xcresult` passed 46 unit tests and all seven existing UI flows. `/tmp/LunaHearthReminderFinal.xcresult` passed all 47 unit tests including additive on-disk migration plus the new automatic-reminders UI flow using an isolated test provider. Thus 47 unit tests and eight distinct UI flows passed across the final validation runs. Xcode reported a non-fatal simulator diagnostics collection failure after the last tests; the result bundle and command report TEST SUCCEEDED. No live EventKit permission or account propagation was exercised by automated tests.

The signed device build succeeded and was installed on the connected iPhone. Automatic launch was blocked because the phone was locked. Unlock/open LunaHearth, connect Reminders, select a writable destination and enable Sync new tasks for live account acceptance. Existing live CloudKit backup remains user-confirmed; its payload format and operation were not changed.


### Apple-only reminder update

ADR-009 supersedes earlier reminder copy/sync behavior. Lists → Reminders now offers existing-list browsing, standard LunaHearth list creation, direct Apple-only entry and completion. Quick Add uses the selected Apple list; the former automatic delivery worker is stopped. Older household tasks remain in a labeled recovery section without automatic migration. See docs/APPLE_CONNECTIONS.md.

Validation: simulator build passed; 48 unit tests and all 8 UI tests passed. Final unit rerun passed; the expanded create-standard-list/direct-create/completion UI test passed after correcting its accessibility selector. Signed device build and install passed. Latest automatic launch was blocked by the phone being locked. Live EventKit account/list creation and provider propagation remain device acceptance checks.

### Selected Apple list setup and shopping

Implemented ADR-010: separate remembered Shopping/Reminders destinations; explicit create-standard-list or browse-and-confirm setup; source-of-truth messaging; selected-list-only new writes; Apple-backed quantity notes and maintenance replacement drafts; due filters; and an in-app sharing guide. Existing local tasks/groceries remain recoverable. EventKit has no public list invitation API, so invitations are completed in Apple Reminders.

Validation: xcodegen generation, simulator build, 50 unit tests, and all 9 UI flows passed in /tmp/LunaListSetup20260912.xcresult. The final selected-destination safeguards, dashboard isolation and URL routing passed the 50-unit-test rerun plus both Apple-list UI flows in /tmp/LunaListSetupFinal20260912.xcresult. Setup, sharing and shopping captures were visually reviewed. Signed iPhone build, installation and launch succeeded. Live iCloud list creation and participant invitation/propagation remain device acceptance checks.


## Private home foundation and live sharing — September 12, 2026

ADR-011/012 replace the historical Apple-only primary lists and manual-backup-only sharing design. Setup now asks only for the home name in an outlined input. People, personal/family choices and rooms are omitted; rooms are added through Home and profiles/sharing through More. The colorful welcome and room photography use original generated assets documented in visual-review/setup-artwork.md. More also provides a non-destructive setup preview.

Primary tasks, groceries and maintenance replacement items save locally and participate in optional private CloudKit household synchronization. Apple Reminders remains a separate optional connection. Explicit custom-zone CKShare invitations, independent-home joining/switching, foreground delivery, durable offline edits, tombstones, conflict review, account binding and read-only/revocation recovery are implemented. Canonical payload equality prevents server timestamp rounding from causing repeated uploads. No public database, app account, automatic upload at setup or network AI was added. Document/scan file synchronization and background push delivery remain unsupported.

The full preceding run passed 62 unit tests and all 11 UI flows in /tmp/LunaLiveSetup20260912.xcresult. Final home-name-only verification and timestamp regression results follow below. A real invitation between two different Apple Accounts remains unverified; automated synchronization tests use two repositories and a fake server.

Final validation: XcodeGen generation and simulator build passed. /tmp/LunaHomeOnlyVerified20260912.xcresult passed all 63 unit tests and four focused UI flows covering the simplified setup, offline shopping, safe setup preview, sharing unavailable, light/dark appearance and large text. The signed device build passed and the updated app was installed and launched on Ravi’s iPhone without resetting app data.

## Private cloud deletion and shopping responsibility — September 12, 2026

ADR-013 adds separately confirmed owner-only cloud-home deletion and manual-backup deletion, preserving local household content. Sync is paused durably before destructive network work and stays paused on errors. No deletion has been executed against the user’s live cloud data.

Shopping adds a store name and household buyer alongside quantity, with Any store / Anyone defaults. Rows group by store, show the assigned buyer, and filter by buyer. Members remain managed in More → Family. Optional additive model/payload fields preserve old records and backup compatibility. Tests cover edits, missing legacy keys, reopened local stores, household reference validation and propagation between two fake-server clients. Receipts, categories and purchase accounting remain future work.

Validation: 66 unit tests passed in /tmp/LunaShoppingFinal20260912.xcresult. The final shopping add/store/buyer/check-off UI flow passed in /tmp/LunaShoppingTapFinal20260912.xcresult after fixing full-row hit testing and dismissing the person-entry keyboard. Backup deletion confirmation/cancellation/unavailable-cloud and simple offline shopping passed in /tmp/LunaShoppingStores20260912.xcresult. Screens 41–42 were visually inspected. Signed iPhone build, upgrade installation and launch succeeded; live cloud deletion was not performed on the user’s data.

## On-device shopping ideas — September 12, 2026

Added Domain ShoppingSuggestionService and validation/fallback rules, a Foundation Models service explicitly using SystemLanguageModel.default, and a review sheet reached from Shopping. Generation is opt-in, local-only, availability-gated at iOS 26, bounded to short grocery context, and offers a clearly labeled non-AI fallback. The iOS 18 manual workflow remains intact. Review permits editing, selection and user-chosen store/buyer; one local transaction commits confirmed suggestions and rechecks duplicates/household references. No schema or networking change.

Validation: simulator build and all 69 unit tests passed in /tmp/LunaShoppingAI20260912.xcresult. The UI review/cancel/add fallback flow passed, and its screenshot (43) was inspected. Signed device build, install and launch succeeded on Ravi’s iPhone. Actual on-device model generation/quality was not exercised by these simulator tests; the app checks availability at request time and shows an explicit fallback when unavailable.

## Shopping form design refinement — September 12, 2026

Dedicated shopping creation/editing now uses rounded cards, persistent field labels, outlined inputs, a blue basket accent and a fixed bottom save action. Item/quantity and optional store/buyer are visually separated. Standard Quick Add and optional Apple-list flows keep their existing behavior.

Shopping ideas becomes a two-step flow: an illustrated request screen with prompt shortcuts and optional checked-history context, followed by compact editable selection cards and a shared pickup plan. Add remains anchored at the bottom; privacy detail is available in a disclosure. Cancel discards transient suggestions and Start over returns to the request. Existing domain validation, local-first saves and review requirements are unchanged.

Validation: /tmp/LunaShoppingForms20260912.xcresult passed 69 unit tests and three UI flows (standard Quick Add, shopping store/buyer, AI review/cancel/add). /tmp/LunaShoppingFormsAccess20260912.xcresult passed the dark/large-text form check. The final permanent buyer-label refinement passed shopping E2E again in /tmp/LunaShoppingFormsFinal20260912.xcresult. Screens 41, 43–45 were visually inspected. Signed builds passed. The main redesign installed on Ravi’s iPhone; opening was blocked by its lock state. Installing the final two-label refinement was blocked twice by device connectivity/assertion unavailability, so the final source/simulator build is newer than the phone by that small refinement.

## Shopping timing — September 12, 2026

Manual shopping and AI review now offer a segmented Now / Later choice. The list shows a timing badge and All / Now / Later filters, together with the existing store grouping and buyer filter. Default Now means the next shop; Later means future shopping, without scheduling a notification. Local optional persistence and additive backup/sync mapping preserve timing across edits and devices. Existing items and older snapshots remain Now. No new permissions or networking are involved.

Timing validation: XcodeGen generation, simulator build, 69 unit tests and both shopping manual/AI UI flows passed in /tmp/LunaShoppingWhen20260912.xcresult. Tests cover Later persistence through edit/reopen/restore, legacy snapshots defaulting to Now, fake-server Later→Now propagation and selected AI-batch timing. Signed iPhone build passed, but installation could not connect to Ravi’s iPhone. This timing build is not yet installed there.
