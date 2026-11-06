# Nam Illam v2: two-pane workspace

Status: Today workspace implemented for review; Home and the remaining workspaces are still planned.
Owner direction, 6 November 2026: use both left and right sides effectively on expansive Duo layouts, with professional UI and safe updates for existing live users.

## Interaction contract

The left side keeps navigation, filtering and selection visible. The right side shows the selected content and its actions. Each pane scrolls independently. Prefer an adaptive split container over stretched cards. Pane selection uses stable entity IDs and survives resizing, rotation and scene transitions. Use available geometry and size class, not a device-name check or fixed hinge location.

| Flow | Left pane | Right pane |
| --- | --- | --- |
| Home (first slice) | Floors and rooms | Selected room, layout, belongings and Add actions |
| Pantry / shopping | Search, categories and items | Selected item, quantities and purchase/stock actions |
| Expenses / receipts | Receipts or scanned lines | Receipt preview, reviewed total and explicit pantry selection |
| Calendar | Calendar/date navigation | Selected day agenda and event details |
| More / documents | Sections or document list | Selected settings section or document |

Compact windows retain push navigation. Large accessibility text may collapse panes when minimum usable widths cannot be met. Critical Save, Cancel, Add and Back controls must remain visible with the keyboard. Reduced Motion removes decorative transitions; VoiceOver gets meaningful pane headings and predictable focus.

## Implementation sequence

1. Home room selection and detail shown side by side; preserve existing room editing and manual creation.
2. Receipt review and expenses, retaining amount validation and opt-in inventory rules.
3. Pantry and shopping selection/detail, then Calendar and More where the second pane improves the task.
4. Visual review across light/dark, compact/open layouts, empty/loading/error states and accessibility sizes.
5. Upgrade and offline regression, then a separate TestFlight candidate.

## Data and privacy

Affected entities are existing household, floor, room, asset, expense, receipt line, inventory, shopping and appointment records. This redesign is presentation work; no schema change, new permission or network service is currently proposed. Keep local writes and optional Apple integrations as defined by AGENTS.md and existing ADRs. A future schema change needs a separate migration design and tests.

## Acceptance gates

- Choosing a left-side item updates the right side without replacing the entire workspace.
- Empty detail offers a useful action; deleted selections recover safely; no stale room from another household.
- Unsaved edits survive supported layout transitions or prompt before dismissal.
- Compact flow and large-text flow remain fully usable with no clipped actions.
- Test existing 1.0 records through an update to v2 without resetting data.
- UI tests and captured images prove behavior; compile success alone is not visual acceptance.

## Baseline validation — 6 November 2026

Version-only baseline 2.0.0 (71) generated with XcodeGen. Simulator build and 292 unit tests in 53 suites passed on the available iPhone 18 Pro / iOS 27.2 simulator. Results: `/tmp/namillam-v2-baseline.xcresult`. No redesigned UI is implemented or visually accepted yet. Prior local website/release artifacts and two modified screenshot scripts were preserved outside these commits pending their own review.

## Today workspace — 6 November 2026

The owner requested a complete redesign of “Your day, in focus” with a cleaner, modern presentation inspired by the supplied Tesla reference. Today now uses a household overview and section navigation beside a focused content pane. The decorative house is an original generated 3D illustration bundled in the app. It requires no network request or runtime dependency; it does not represent the household’s saved rooms.

Affected existing entities: household, events, tasks, groceries, pantry inventory, maintenance plans, warranties and meals. This is presentation-only: no data model, migration, networking, permission, sync, or ownership change. All existing local actions and optional on-device summary behavior remain. The live v1 tag is unchanged.

Navigation and category state live above adaptive layout changes. Validation covers the width boundary, accessibility collapse, section destinations, Quick Add, rotation and light/dark/large text. Results are recorded after execution below.

Follow-up refinements: replace the temporary house drawing with `TodayResidenceV2`, a transparent generated architectural illustration. Unify all 33 base semantic color assets across Today, Home, Calendar, Shopping, Inventory, Expenses, onboarding and forms. Today delegates to AppTheme so its palette cannot diverge. Category/event/status colors remain semantic accents. A unit test checks matching feature palettes and a minimum 4.5:1 body-text/action contrast in both light and dark appearances.

Validation: simulator builds, 292 existing Swift Testing tests plus the performance test, targeted Today UI tests, app-wide dark screen survey, final palette/contrast unit test, light navigation and final Duo dark navigation passed. Evidence and result-bundle paths: `docs/validation/2026-11-06-today-v2/README.md`.

## November 6 scope decision: hide spaces and home care

The owner requested hiding Home care, Warranties, rooms and floors in v2.
Today no longer presents home-care navigation or counts in its daily brief.
Home keeps pantry, shopping, meals, reminders, receipts, expenses and purchases;
the expansive panel shows a household overview instead of the floor plan.
Quick Add offers events, reminders, groceries and meals. Home-item creation is
also omitted because its room/belongings destination is hidden. Setup, sharing
and preferences no longer link to room layout or warranty settings.

Affected entities: HomeFloor, Room, HomeAsset, Warranty and MaintenancePlan.
Their persistence and sync remain unchanged; no records are deleted or migrated.
This is an offline presentation change with no new permissions or networking.
The live v1 release is unchanged. Legacy room/home-care UI tests describe the
previous release; v2 validation uses the hidden-feature navigation check instead.
