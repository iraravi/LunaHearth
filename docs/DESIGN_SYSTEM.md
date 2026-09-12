# LunaHearth Product & Visual Design System

## 1. Design objective

LunaHearth should feel like a calm household instrument: warm enough for family use, structured enough for home records, and native enough that an Apple user immediately understands it.

It must not feel like:
- a corporate asset-management app
- a child-only chore game
- a dense smart-home control panel
- a clone of Calendar/Reminders
- a clone of a dedicated wall-calendar product

## 2. Design principles

### Calm density
Show enough information to make Today useful, but cap sections and use progressive disclosure.

### Native interaction first
Use standard SwiftUI navigation, menus, sheets, pickers, date controls, swipe actions, context menus, and system materials before inventing custom interaction.

### Content over chrome
Household data is the visual focus. Avoid decorative backgrounds that reduce readability.

### Privacy without fear
Use clear labels such as “This Device” and “iCloud Family Sync.” Avoid alarming shield/lock imagery everywhere.

### One object, one home
An asset has one clear detail page where warranty, maintenance, documents, and purchase details converge.

## 3. Root navigation

```text
┌────────────────────────────────────────────┐
│                Current View                │
│                                            │
│                                            │
├────────────────────────────────────────────┤
│ Today   Calendar   Home   Lists   More     │
└────────────────────────────────────────────┘
```

Five tabs are fixed for MVP.

## 4. Today composition

Preferred order:

```text
TODAY                                      +
Friday, Sep 11

FAMILY
9:00 AM   Work                         Ravi
3:00 PM   School activity              Kira
6:30 PM   Dinner                       Family

TO DO
○ Pick up prescription
○ Change upstairs AC filter

HOME
⚠ Dishwasher warranty ends in 21 days
  Refrigerator filter due tomorrow

TONIGHT
Dinner        Chicken curry
Shopping      7 open items
```

Rules:
- no more than 3–5 items per summary section before “View all”
- urgent states use icon + text, never color only
- do not show charts on Today in MVP
- Quick Add remains visible in toolbar

## 5. Calendar composition

Compact:

```text
SEPTEMBER 2026
M  T  W  T  F  S  S
...

FRIDAY 11
9:00   Work                         Ravi
10:30  Dentist                      Mom
3:00   Activity                     Child
5:30   Costco                       Family
```

Expansive:

```text
┌────────────────────┬─────────────────────────────┐
│ SEPTEMBER          │ FRIDAY 11                   │
│ calendar grid      │                             │
│                    │ 9:00 Work — Ravi            │
│ Filters            │ 10:30 Dentist — Mom         │
│ Ravi               │ 3:00 Activity — Child      │
│ Mom                │ 5:30 Costco — Family       │
│ Child              │                             │
└────────────────────┴─────────────────────────────┘
```

Use color as a secondary family-member cue; text/avatars/initials provide the primary identity.

## 6. Home composition

### Home root

```text
MY HOME                                      +

First Floor
  Living Room                          5 items
  Kitchen                              7 items
  Garage                               9 items

Second Floor
  Primary Bedroom                      4 items
  Child Room                           3 items
  Office                               6 items

Upcoming
  AC filter                      Tomorrow
  Dishwasher warranty            21 days
```

### Room detail

```text
KITCHEN

Items
  Refrigerator                   Warranty active
  Dishwasher                     ⚠ 21 days
  Oven                           —
  Coffee Machine                 Descale in 14 days

Maintenance
  Refrigerator filter            Feb 12

[ Add Item ]  [ Scan Room ]
```

### Asset detail

```text
LG Refrigerator
Kitchen

OVERVIEW
LG • LRFVS3006S
Serial: •••••6789
Purchased May 18, 2025
$2,399.00

WARRANTY
Active until May 18, 2030

MAINTENANCE
Water filter
Last: Aug 12, 2026
Next: Feb 12, 2027

DOCUMENTS
Receipt
Warranty
Manual

SERVICE HISTORY
Jun 2026   Ice maker repair
```

Serial numbers can be visually redacted in summary contexts; reveal in detail intentionally.

## 7. Lists composition

Lists landing uses a simple list, not four competing dashboard tiles if a list reads better:

```text
Tasks & Chores      5 due
Groceries           7 open
Meals               Dinner planned
Routines            3 active
```

Groceries optimize for one-handed check-off and fast add.

## 8. More composition

```text
HOUSEHOLD
Family
Documents

PRIVACY & SYNC
Storage              This Device
iCloud Family Sync   Off

APP
Settings
Diagnostics
Export Data
About & Privacy
```

## 9. Onboarding

### Welcome

Headline:
**Your home and family, together.**

Support copy:
“LunaHearth works on this device first. iCloud family sync is optional.”

Actions:
- Get Started — primary
- Join Family — secondary

No login/sign-up.

### Household setup
Ask only:
1. Home name
2. Your display name
3. Add other people? optional

Do not ask permissions or subscription on first launch.

## 10. Quick Add

Sheet layout:

```text
QUICK ADD

[ What needs to happen?                    ]

Suggested: Task
“Change upstairs AC filter every 90 days”

Event        Task        Grocery
Meal         Home Item   Maintenance

                         [ Continue ]
```

After parsing, show editable draft before saving if recurrence/date/member is inferred.

## 11. Typography

Use Dynamic Type system fonts.

Suggested semantic levels:
- navigation/title: system large title/title
- section heading: headline
- primary item text: body
- metadata: subheadline/footnote
- alerts: body + icon, not tiny red text

Do not hardcode font point sizes except narrowly justified visualizations.

## 12. Spacing

Default tokens in code may evolve:
- screen horizontal padding: 16–20pt
- section spacing: 16–24pt
- card internal padding: 16pt
- compact row vertical padding: 8–12pt
- minimum practical touch target: ~44pt

## 13. Shape and material

Use system grouped lists and materials where they help hierarchy.

Cards:
- rounded, moderate radius
- subtle material/system background
- avoid deep shadows and glass-on-glass nesting

On newer OS versions, adopt current system visual language through SwiftUI APIs rather than recreating effects manually.

## 14. Color

Brand color is intentionally not finalized until naming/brand work is cleared.

For implementation:
- use semantic system colors
- use asset-catalog AccentColor placeholder
- family-member colors must meet contrast requirements and be accompanied by labels
- status colors: system semantic green/orange/red where appropriate, plus icon/text

## 15. Iconography

Prefer SF Symbols.

Suggested concepts:
- Today: `sun.max`
- Calendar: `calendar`
- Home: `house`
- Lists: `checklist`
- More: `ellipsis.circle`
- Warranty: `checkmark.shield` / status-specific symbol
- Maintenance: `wrench.and.screwdriver`
- Grocery: `cart`
- Meal: `fork.knife`
- Documents: `doc.text`

Verify symbol availability against the minimum SDK before shipping.

## 16. Motion

Motion should confirm spatial navigation/state changes, not entertain.

Respect Reduce Motion.

Good uses:
- task completion state transition
- inserted grocery row
- expanding a summary

Avoid:
- constant dashboard animations
- celebratory confetti for routine adult household actions

## 17. Accessibility

Mandatory:
- Dynamic Type
- VoiceOver
- adequate contrast
- non-color status indication
- large touch targets
- list alternative to spatial/3D Home representation
- understandable focus order
- no drag-only interaction

## 18. Duo / expansive design

The product should use extra width for **simultaneous context**, not stretched whitespace.

Examples:
- Calendar: date navigator + agenda
- Home: room tree + room/asset detail
- Lists: list + selected item/detail
- Documents: folders/categories + preview metadata

Avoid a different information architecture for Duo. The same routes/state adapt.

## 19. Partial-fold desk scenarios

Potential later experiences:
- Today glance on top region + quick action on lower region
- meal/grocery counter mode in kitchen
- maintenance checklist while working on an appliance

These are enhancements, not MVP requirements. Never invent posture APIs; implement only after verifying current Apple SDK.

## 20. Empty/error states

Every empty state answers:
1. what is this area?
2. what should I do next?

Every error state answers:
1. what happened?
2. did I lose anything?
3. what can I do now?

Example iCloud error:
“Family sync is unavailable right now. Your changes are saved on this device and will remain available.”

## 21. Implemented visual refresh — September 2026

The requested direction is now Uber-inspired: monochrome surfaces, bold system sans-serif titles, direct copy, strong primary actions, compact cards, and vivid colorful graphics. This supersedes the initial warm editorial exploration. The implementation remains LunaHearth's original native household UI; it does not use Uber logos, proprietary typefaces, or a third-party UI package.

The palette is white/black canvas, light gray/charcoal surfaces, black/white primary text and actions, and high-contrast neutral secondary text. Semantic color assets provide light and dark variants. The 18 main foreground/surface combinations exceed 4.5:1 contrast. Corners are generally 12–16 points; system controls retain their native styling. Display headings use bold system sans-serif with Dynamic Type.

Three original illustrations are bundled: a cobalt-blue living room, colorful planning objects, and bright groceries. These use saturated blue, yellow, coral, green, and purple against clean white backgrounds, with no earthy or sepia treatment. Category icon badges and metric icons use adaptive blue, green, orange, purple, and coral accents. Navigation, text, surfaces, and primary actions remain black and white. They are decorative graphics, never representations of the user's actual household. Labels and actions are native SwiftUI text outside the imagery. No household content is transmitted. Generation prompts and file paths are recorded in `ARTWORK_PROVENANCE.md`.

Today places a prominent add action and household counts above its cards. It uses an adaptive one/two-column layout. Home retains split navigation. Lists keeps one clear destination row per list type. The welcome button stays accessible in a bottom safe-area inset while introductory content scrolls.

Shared components live in `Core/DesignSystem/AppTheme.swift`: semantic colors, introductions, icon badges, artwork panels, metrics, cards, and link rows. Decorative graphics are hidden from VoiceOver. No information depends on color alone. No decorative animation was introduced.

The UI tests use a DEBUG-only in-memory store and appearance arguments, exercising onboarding and task creation and capturing all five tabs plus dark mode and accessibility text. They do not modify normal on-disk data or system preferences. Screenshots are exported to `docs/visual-review/` for review. Minimum-OS, iPad, and full VoiceOver QA remain separate release checks.

Reference for the general token-based light/dark approach: [Uber's Base Web theming documentation](https://baseweb.design/guides/theming/). No Base Web code or dependency is included in the app.

## Home layout workspace

The manual builder keeps black-and-white navigation and actions while using blue, purple, green, cyan, coral and orange room accents. Presets are illustrated with native symbols; the preview is generated from saved dimensions. 3D rotation uses an accessible slider, and 2D mode plus the labeled room list provide alternative views. A persistent toolbar add action remains available while scrolling. Room measurement fields accept exact numeric input as well as stepper increments.
