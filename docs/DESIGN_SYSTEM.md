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
│ Today      Calendar      Home      More   │
└────────────────────────────────────────────┘
```

Four tabs are used under ADR-041: Today, Calendar, Home and More. Home provides reminders, shopping and meals; Today keeps contextual shortcuts.

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

## More hub — September 13, 2026

More uses a pale teal canvas, colorful home photography and compact destination
rows with subtle category icon backgrounds. Family & sharing comes first, followed
by Apple connections, storage/preferences and the product tour. Private backups
are explicitly separate from live sharing. Longer privacy explanations and warranty
preferences live on their own detail screens. Documents are clearly marked as
coming later instead of opening a dead end. No storage status is inferred from
whether a local store exists.

Wide windows arrange sections in two columns, bounded to a readable content width.
Accessibility text sizes use one column and omit decorative hero photography so
names and navigation retain space. Rows grow with text and use native navigation,
VoiceOver grouping and 44-point-or-larger targets. Light and dark appearances use
system text/surface colors with a restrained tinted canvas. No persistence,
permissions, sharing behavior or private-cloud data changes.

## Family direction — September 13, 2026

Family separates invitations from profiles without a device. A compact illustrated
header leads to an owner-only Invite someone action, shared-access management, and
a roster with initials, profile roles, and a You marker when a device profile is
known. Invitation acceptance is not inferred from a profile existing; a short
caption directs people to sharing management for that status.

The local-only state leads to optional iCloud setup while preserving a secondary
Add someone without a device flow. Its name/type form is presented separately,
with validation and cancel/save controls. Shared participants see owner guidance;
read-only and recovery states hide creation controls. No new data fields,
authorization semantics, permissions, network services or cloud operations.

Wide layouts show roster and actions side by side. Accessibility sizes use one
column, omit decorative avatar art and allow text/rows to expand. This changes
presentation of HouseholdMember and existing SyncConfiguration only; local saves
continue to use the repository and named invitations reuse ADR-024.

The root iCloud status strip now occupies its own layout space above navigation,
rather than overlaying navigation bars through a top safe-area inset. This keeps
Family’s back control and the iPad tab bar visible while a sync warning is shown.
Decorative action icons are omitted at accessibility text sizes to prevent them
from extending into enlarged labels.

ADR-025 keeps Family's Invitations & access in a direct Apple sharing sheet. The
named invitation form explains the send step and opens the composer after
preparation; not-sent, cancelled, copied and app-handoff states replace the earlier
misleading checkmark. Entering a name/email never implies an email was delivered.

### Single family destination (direct build 15)
More has one **Family** entry for people, named invitations and Apple's access panel. Technical **iCloud sync & data** lives under Storage & preferences; it no longer duplicates invitation buttons or the Home, together header. Invitation fields stay editable during background sync. Preparing waits for active sync without overlapping writes, revalidates the destination, and presents failures in an alert with the entered values retained.

Affected entities: existing household configuration and named household members. No schema or ownership changes; offline copies remain preserved. No message is sent automatically: Mail or Messages still requires the user's Send action.

### Apple-managed invitations (direct build 16)
The user confirmed native Apple sharing via email or Messages succeeds, while our custom named-email lookup rejects the same recipient. Family → Invite someone now opens the same UICloudSharingController as Invitations & access. No app-side email discovery or second send sheet blocks this primary path. Errors opening the native panel are presented immediately. Native invite delivery and participant status are managed by Apple; a profile row is not evidence of an accepted share. The old custom named invitation view is not exposed by Family. Existing named profile data and identity mappings are preserved; Apple-managed invitations do not themselves run the custom pre-naming operation. Automatic admin-selected naming for participants invited through the native flow remains follow-up work and must not be claimed complete.

### Automatic profiles after native joining (direct build 17)
The build 16 naming follow-up is implemented: verified writable sync creates/reuses the current account's profile automatically. Owner supplies app display names using the pencil beside a person. Initial names are Home owner and Family member, not Apple contact names. Same account means the same profile on every device; different accounts remain separate regardless of matching names. Names and task assignments use the existing shared member record.

### Pantry Ideas clarity (build 18)
Use Starter suggestions / AI suggestions, never a heading that implies the proposed items are already owned. Show the saved ingredient count independently. Display AI outcome feedback as a readable result section with an icon and title, including explicit fallback reasons. Add remains disabled until the user selects at least one currently eligible suggestion.

### Kitchen templates and shared iPad canvas (build 20)
Pantry Ideas supports 100+ regional kitchen checklists, searchable category groups, bulk selection and a separate Review pantry step before Add. On iPad, the Home sidebar takes the currently visible destination's canvas: InventoryCanvas for pantry and ShoppingCanvas for shopping. Palette state is scoped to the root tab and cleared when a destination disappears. No white sidebar remains beside a colored pantry/shopping detail.

## Expenses dashboard (build 24)

A lavender canvas and white/light or deep-purple/dark surfaces distinguish spending from green Shopping and peach Pantry. The primary figure is gross spending for the chosen month and currency, with refunds/net beneath when present. Monthly trend and category cards sit side-by-side on wide windows and stack on compact layouts. Purchase history uses labeled category icons and visible dates/amounts; editing stays in a separate sheet. Chart accessibility announces each month and formatted currency amount, and color never carries the only meaning. Receipt expense details collapse into a store/total/currency/date summary so proposed inventory items remain accessible below.

## Purchase flow polish — build 28
Purchase history uses item previews, readable dates and expense totals in neutral lavender cards. Purchase details use a compact receipt summary plus illustrated item cards. At window widths of 820 points or more the summary sits beside items; narrower windows and accessibility text sizes stack content. No device-model or undocumented fold/posture API is used. History switches to a single column at accessibility sizes. Receipt introductions are compact; expense reports stack charts and place amounts below merchant details at accessibility sizes.

Native Dynamic Type is uncapped. Important state includes text and symbols, decorative illustrations are hidden from VoiceOver, inventory actions identify the item, and actions have at least 44-point targets. Increase Contrast strengthens purchase-card borders. No new animation is introduced. Existing light/dark semantic colors remain. Keyboard/Switch Control/VoiceOver hardware navigation and unreleased Duo behavior must not be described as verified without a live check.

## Connected demo — build 29
Home's connected demo shows receipt, expense, shopping, pantry and meal-preview stages as a vertical diagram. A document marker moves between stages on a five-second cadence with a 2.5-second transition. Pause/replay/manual controls are available; Reduce Motion disables timed playback. Separate stage colors supplement labels and symbols. Sample receipt sharing is explicit. All business actions run against an isolated in-memory repository.

## Continuous demo animation — build 30
The previous step-card diagram is replaced by a continuously rendered vector scene: scanning receipt, branching purchase tokens, growing expense bars, clearing shopping rows, arriving pantry jars and ingredients assembling on a plate. A 25-second loop uses a capped 30 fps SwiftUI TimelineView. It starts independently of receipt import and is explicitly an illustration with sample values. Pause/Play and Next scene are available. Reduce Motion uses static manual scenes; backgrounding or leaving pauses playback. The scene is decorative to VoiceOver; a scalable text caption describes its current meaning. This view has no repository or persistence access.

## Meal ideas — build 31
A separate pantry-based meal screen uses a fresh-food hero, soft sage canvas with a dark appearance, native date selection, a visible device reminder toggle and a bounded suggestion action. Adaptive cards show main ingredients, approximate duration, deterministic missing-item labels and Review & plan. Expansive windows use a multi-column card grid capped at 1000 points; accessibility text uses one column. Decorative art is hidden from VoiceOver; actionable controls retain native labels and minimum tap targets. The existing meal editor performs final review/save. This is the real household workflow, distinct from the temporary connected demo.

Meal ideas build 32 adds a native cuisine dropdown instead of a long row of chips. An initially unselected placeholder asks for a choice, with Any style available. A labelled, bordered multiline optional-notes field includes a 400-character counter and keyboard Done action. The device remembers cooking style; notes are session-only. The same controls adapt to iPhone and iPad without adding another onboarding screen.

## Cook this meal — build 33
Saved plans and Today open a bounded cooking detail with a food hero, ingredient availability, editable pantry pack amounts, preparation tasks, and tappable recipe steps. Separate compact sheets review missing shopping and pantry usage. Measured usage has explicit amount/unit controls and a calculated remaining preview. All pantry actions default to unchanged; status uses icon and text. Inline sheet titles and native accessible controls preserve compact and enlarged text layouts.

## Home dashboard and category cleanup — build 34
Home uses two illustrated kitchen cards with short purpose labels, a separate meal card, a rooms photo card and compact utility tiles. Pantry is warm; Shopping is green. Accessible text sizes collapse kitchen cards to one column, and utility cards adapt to available width. Rooms keep an independent split-view workspace instead of occupying a permanent white sidebar on the Home dashboard. Danger Zone is a separate destination under More with category counts and an explicit typed confirmation sheet; destructive red is reserved for cleanup controls.

### Lists landing refinement (build 36)
Lists uses three distinct, fully tappable cards: Reminders / What needs doing, Shopping / What to buy, and Meal ideas / What to cook. Compact artwork replaces the tall header illustration so destinations appear earlier. Task and shopping counts read current local household data. Cards retain native NavigationLink behavior and use indigo, sage and warm pantry accents; text and symbols distinguish the destinations independently of color. Large accessibility sizes hide decorative artwork to reserve width for text. The centered 800-point maximum keeps iPad rows readable.

### Meal plans and cooking (build 37)
Saved meal plans use day-based cards with meal type, servings, ingredient count and cooked state. Ingredients have individual status cards with matched pack amounts inline, avoiding the repeated ingredient list followed by a second pack list. Prep reminders explicitly describe advance tasks; Cooking steps remains the recipe section. Empty older recipes offer Add recipe steps rather than a blank area.

### Weekly meals (build 38)
Weekly meals provides seven day cards with breakfast/lunch/dinner slots, a separate draft review and a separate shopping review. Unknown amounts and existing shopping entries have explicit labels. Per-serving quantities sit in the meal editor; Today includes tomorrow preparation links. Native text sizing and scrolling support compact/regular layouts.

### Today visual rhythm (build 39)
Today uses a compact household-photo hero, consistent 20-point card insets, rounded surfaces and matching illustrated section headers for schedule, reminders, home care and meals. A measured SwiftUI Layout aligns card heights and action footers without hardcoded content heights. Wide priority panels share measured heights; household cards form a two-column grid on wide windows and one column on compact/accessibility layouts. Decorative thumbnails are hidden at accessibility text sizes so labels can grow. Existing actions, personal shopping, expiry/low-stock attention, brief and meal links retain their behavior. No data, permissions or synchronization changes.

### Calendar agenda refresh (build 40)
Calendar uses a compact week strip and expandable native month picker on narrow windows. At 850 points and wider it places the month and member controls beside the agenda; accessibility text sizes retain the single-column layout. An illustrated heading, neutral adaptive surfaces, indigo selection, appointment symbols, explicit member names, and full-card navigation replace the long form. Real household members populate filters; sample Ravi/Kira events exist only in the in-memory UI fixture. Apple Calendar remains an optional device-specific disclosure and is explicitly separate from household-member filters. No new permissions, schema, or synchronization behavior.

### Family calendar board (build 41)
The calendar now uses the user's person-first reference: initials-based member selectors, soft individual panel tints, and appointment cards grouped into Morning, Afternoon, and Evening. The header stays compact, with previous day, Today, next day, and an expandable native month picker. Windows at least 700 points wide use adaptive columns; narrow windows and accessibility text sizes use a single column. Everyone shows each member's panel, including open days; unassigned or missing-member appointments remain in a Household panel. Member names are always visible. Symbols illustrate time of day rather than guessing an appointment's medical or personal purpose. Per-person add actions preselect that member. No photos, fake appointments, points, or task-completion state are added to household data.

### Appointment editor and Siri (build 42)
Calendar's add and detail-edit actions use a focused illustrated appointment editor: name/person/type, start/end with bounded repeat settings, and reminder timing. Type icons replace time-of-day artwork for explicitly categorized events. Conflicts surface before save. Calendar settings group device alerts and discoverable Siri phrases; ShortcutsLink opens Apple's shortcuts surface. Siri creates a reviewable draft, not an automatic appointment.

### Apple Calendar checkbox (build 43)
The appointment editor adds a compact optional toggle with writable-calendar selection, loading/unavailable states, and direction-of-sync copy. Existing linked calendars are named and kept fixed. Turning off the toggle pauses future updates and keeps the Apple copy. Event details show Last update sent/Pending/Paused/Needs attention, with Calendar settings → Linked events & sync status for retry or cleanup. Deleting a linked appointment offers keep-Apple-copy versus delete-both choices; other item types retain the ordinary deletion message.

### Family week — build 44
The weekly header uses HearthPlanning artwork with a soft indigo surface. Day panels use labeled appointment, task and meal sections with subtle indigo/teal/amber accents; shopping keeps its sage surface. Compact date buttons and person chips have accessible selection states and at least 44-point targets. Wide columns are horizontally scrollable; accessibility text sizes switch to a single day, allow wrapping and remove decorative artwork. Whole entry cards navigate to the original details. No new bottom tab.

### Everyday screen polish — build 53
Today measures card heights per row instead of using the largest card across the entire dashboard, reducing empty space while retaining equal heights within a row. Home's pantry and shopping destinations share that measured layout, retain colorful food photography, and omit decorative food artwork at accessibility sizes. Grocery controls have visible rounded button boundaries and 44-point minimum targets. Pantry and shopping shelves use a genuinely flexible single column at accessibility sizes, including narrow windows. Category filters announce their category and item count rather than decorative emoji. Shared card outlines become stronger with Increase Contrast, and pantry/shopping maintain distinct warm/green palettes in light and dark appearances.

This is presentation-only for existing household, task, grocery and inventory data. No schema, permissions, networking, AI, sync or persistence changes. Existing navigation identifiers are retained. No new animation is added.
At accessibility text sizes, grocery tools form a horizontally scrollable, labeled strip rather than three tall rows. Pantry uses concise Add item / Kitchen photo labels with full accessibility names. Text sizing remains uncapped; category chips retain selection traits. Physical VoiceOver, Switch Control and keyboard operation still need device verification.
Build 53 validation: Home navigation, grocery dark-mode controls, and Today large-text flows passed on iPhone. The grocery large-text regression initially caught excess pantry header height; after concise labels and the scrollable tools strip, it passed on iPhone and iPad. iPad Today landscape flow also passed. Screenshots were inspected for Home, dark shopping and large-text Today/pantry; landscape test capture had a rotation artifact, so it is not evidence of a complete landscape visual review. Signed Release build passed and installed on Ravi's iPhone. Physical iPad installation remains blocked by lock state. No TestFlight upload.

## Welcome and setup — September 16 refinement

Use restrained editorial photography, an ivory/charcoal adaptive palette, muted sage accents and serif display headings for the welcome journey. Keep body text native and readable. Favor a photograph, short instructions and a single compact primary action over decorative tile grids. Chapter navigation uses text and an underline. Setup progress remains explicit; permission and AI disclosures stay reachable. Assets and generation prompts: `docs/visual-review/premium-welcome/ART_DIRECTION.md`. Other feature surfaces retain their existing semantic palettes until individually redesigned.

## App-wide ivory system — ADR 047

The welcome direction now applies throughout the app: ivory canvas, near-white surfaces, charcoal text and restrained sage/clay/slate/plum accents. Category accents appear in icons, small backgrounds and selected states, not full-page color washes. Danger and caution retain their semantic colors and text. Serif display headings are reserved for editorial hierarchy; record data and actions use native system type. Shared cards use 18-point corners and adaptive contrast outlines. See ADR 047 for affected surfaces and privacy boundaries.

## Liquid Glass controls — ADR 048

On iOS 26+, let native bars supply Liquid Glass. Use HearthGlassControls and hearthGlassButton for grouped navigation/action controls; preserve opaque ivory content surfaces. Availability fallback uses native bordered styles. Reduce Transparency and Increase Contrast also use solid/bordered styles. Do not apply glass to whole cards, forms, images or screens. See ADR 048.

## Assignment arrival and purchase confirmation — September 29, 2026
Assignment notification taps distinguish tasks from shopping and show the matching section in For You. A static sage banner identifies the destination; a single symbol bounce provides arrival feedback when Reduce Motion is off. The sheet opens before the background refresh finishes. Another home's notification is explicitly identified rather than displaying unrelated current assignments. Existing personal-member selection and current saved lists remain authoritative; this does not claim an exact unread-item count or guaranteed push timing.

Successful shopping completion shows a dismissible, width-capped confirmation on Shopping, For You and Today priority screens. Its text uses the saved pantry quantity when a linked pack exists. The confirmation is emitted only after the repository commits, and a purchase-sheet cancellation or save failure does not trigger it. It remains readable until dismissed, disappears on home change, and uses native Dynamic Type with labelled 44-point dismissal. A short insertion transition is disabled for Reduce Motion. There is no animation timer, background rendering or new permission.

Duo follows the existing adaptive navigation/sheet guidance. No hinge angle is inferred from size, no posture-specific API was introduced, and no physical fold transition is claimed. Tests cover the available Duo simulator plus an iPad layout; real VoiceOver and physical-device motion remain manual checks. No schema, AI, cloud payload or notification subscription changes.
