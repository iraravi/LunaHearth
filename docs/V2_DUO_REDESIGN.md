# Nam Illam v2: two-pane workspace

Status: planned; implementation and visual acceptance pending.
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
