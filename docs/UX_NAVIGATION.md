# UX and Navigation Design

## 1. Navigation principle

LunaHearth may contain a lot of household data, but it must not *feel* like enterprise software. Five root tabs are the maximum for the first product:

`Today | Calendar | Home | Lists | More`

Everything else is subordinate.

## 2. First launch

### Screen 1 — Welcome

Content:
- LunaHearth value proposition
- privacy statement
- primary `Get Started`
- secondary `Join Family`

No Login/Sign Up button.
No permission prompts.
No iCloud requirement.

### Screen 2 — Name your home
Examples: Our Home, Apartment, Dallas Home.

### Screen 3 — People (optional)
Add adults/children by display name. Skip allowed.

### Screen 4 — Ready
Reinforce: “Stored on this device. You can enable private iCloud family sync later.”

Go to Today.

## 3. Today

Purpose: answer “What matters today?” in under five seconds.

Suggested sections:
- Family schedule
- To do
- Home alerts
- Tonight/meal
- Shopping summary

Use cards sparingly; prioritize clear grouped lists.

Primary action: Quick Add.

## 4. Calendar

### Compact
- agenda/day-first
- date picker/month strip
- filter by member
- push event detail

### Expansive
- left: date/month/member filters
- right: selected day/agenda

Member color is supplementary; always show names/initials.

## 5. Home

### Compact

```text
My Home
├ First Floor
│  ├ Living Room
│  ├ Kitchen
│  └ Garage
└ Second Floor
   ├ Bedroom
   ├ Child Room
   └ Office
```

Tap room → item list → asset detail.

### Expansive / Duo-class

```text
┌─────────────────────────┬─────────────────────────┐
│ MY HOME                 │ KITCHEN                 │
│ First Floor             │ Refrigerator            │
│  Living Room            │ Dishwasher ⚠            │
│  Kitchen ←              │ Oven                    │
│  Garage                 │ Coffee Machine          │
│                         │                         │
│ Second Floor            │ Upcoming                │
│  Bedroom                │ Filter due tomorrow     │
└─────────────────────────┴─────────────────────────┘
```

This is master/detail, not a separate product mode.

## 6. Asset detail

Sections:
- identity (name/manufacturer/model/serial)
- room/location
- purchase
- warranty
- maintenance
- documents
- service history

High-value actions:
- add warranty
- add maintenance
- scan/import receipt
- add document
- move room
- archive item

Avoid hiding basic asset data behind decorative 3D UI.

## 7. Lists

Landing list:
- Tasks & Chores
- Groceries
- Meals
- Routines

### Tasks
Filters: Today / Upcoming / By Person / Home Maintenance.

### Grocery
Fast checkbox list; household replacement parts can appear here.

### Meals
Simple weekly plan. Recipes are not MVP unless validated.

### Routines
Recurring family sequences later; do not duplicate the task recurrence engine unnecessarily.

## 8. More

Sections:

### Household
- Family
- Documents

### Privacy & sync
- Storage mode: This Device / iCloud Family Sync
- last sync status
- manage participants

### App
- Settings
- Diagnostics
- Export data
- About/privacy

## 9. Quick Add

One universal sheet reduces navigation complexity.

Top:
`What do you want to add?`

Free text field and optional microphone/App Intent later.

Explicit choices:
- Event
- Task
- Grocery
- Meal
- Home Item
- Maintenance

If AI recognizes intent, prefill a draft but keep type/form editable.

## 10. Permission UX

Never ask everything on onboarding.

Examples:

Calendar:
> Connect Apple Calendar
> See selected calendars alongside your LunaHearth family schedule.

Camera:
> Scan this appliance label
> Camera access is used only while scanning.

Notifications:
> Get maintenance reminders
> Allow alerts for the due dates you create.

## 11. Empty states

Every empty state should teach the next useful action.

Home empty:
- “Add your first room”
- “Scan Room” only if supported

Calendar empty:
- “Add a family event”
- optional “Connect Apple Calendar”

Today empty:
- positive, not broken-looking
- show setup suggestions rather than blank cards

## 12. Fold/posture behavior

Do not assume hinge posture from screen size alone. When relevant SDK APIs are integrated:
- fully open: two-column planning/detail
- partially open on a surface: optional glance/focus layouts
- closed/compact: standard iPhone navigation

A task must never require a particular posture.

## 13. Widgets

Widgets complement the app; they do not replace the connected household workflows.

Initial widget information:
- next event
- due task count
- maintenance/warranty alert
- shopping count

Interactive completion comes later with App Intents.

## 14. Design language

Tone:
- calm
- warm
- precise
- domestic but not childish
- privacy-conscious without fear messaging

Avoid:
- excessive gradients/glows
- gamification everywhere
- dense analytics
- copying competitor visual systems

Use SF Symbols where appropriate and respect system appearance/accessibility.

## Home organization — build 21

Home now groups food links under Groceries, saved rooms and the optional Floor plan under Rooms, the expandable item index under Belongings, and warranties/maintenance under Home care. Add a room is a single inline action; floor creation and floor renaming live in the Home settings menu. Open a room to add its belongings. The floor plan remains the existing 2D/3D editor, rather than a separate competing setup flow.

The iPad keeps the room master/detail layout with a graphical introduction before a selection. Pantry and shopping still propagate their peach and green canvases across the split view. Native lists, wrapping text, labeled controls and 44-point add targets retain accessibility and compact-width support.

Affected entities: presentation of existing floors, rooms, assets and inventory only. No schema, ownership, notification, sync or permission changes. All navigation and room/item creation retain their existing local/offline behavior.

## Receipt entry — build 23

Shopping and Groceries at home have a labeled Scan receipt toolbar action beside Add item. Choose photos or scan a document, review compact selectable item rows, expand Quantity & matches when needed, then Add the selected items. Receipt source text and rescan controls collapse after recognition to keep the proposed purchases in view. Excluded rows save nothing; turning off Add to home inventory records a purchase kept elsewhere. Existing inventory clears Low stock and retains amount/expiry; new items receive confirmed quantities. Success reports the import count. Recognition errors allow retry and readable text with no detected items supports adding missed lines.

## Expenses under Home — build 24

Home places Expenses near groceries. Its lavender canvas follows the iPad sidebar and detail. The monthly dashboard leads with spending, followed by a six-month chart, category breakdown and purchase/refund history. Month and currency controls scope all report totals; history search/category filters do not alter the complete exported month. Scan receipt and Add expense stay in the toolbar. Edit/delete opens from a purchase row; deletion requires confirmation. No sixth root tab is added.

### Calendar board update — build 41
User-selected visual direction replaces the expansive month-sidebar layout with side-by-side member panels, with morning/afternoon/evening sections and explicit member labels. Date selection is available in the header on all sizes; the month picker expands on demand. Compact layouts stack panels, and member selectors isolate one person. Existing event detail, editing, optional Apple Calendar connection, and export remain available.

### Family week — build 44
Calendar → Family week and Today → Family week combine existing appointments, due tasks and meals. Wide windows show scrolling day columns; compact/large-text views show a selected day with date buttons and optional swipe. The person filter retains unassigned household plans and shared meals. Plan our week opens dinner suggestions with optional reviewed prep tasks; Review meal ingredients uses the existing shopping review. The full breakfast/lunch/dinner planner remains reachable. See ADR 038.

Build 45: Plan our week now offers Breakfast, Lunch and Dinner switches, initially all on. Generate is unavailable if all are off. Reviewed output can contain up to 21 meals; existing occupied slots remain unchanged. Dinner prep remains separately optional.
