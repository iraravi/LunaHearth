# Product Specification — LunaHearth

> Current foundation (ADR-012): local household reminders, shopping, schedules and home records support optional private CloudKit sync and CKShare invitations. Foreground changes sync automatically; live two-account device acceptance is still a release check. Apple Reminders is a separate optional connection. Setup no longer asks for a room. Earlier Apple-only/manual-backup-only implementation notes below are historical. See [ADR-012](ADR/012-live-private-household-sharing.md).



## 1. Executive summary

LunaHearth is a **private household operating system** for Apple devices. It helps a household coordinate people and time while also maintaining a structured digital representation of the physical home.

Most households currently split information across unrelated systems:

- Apple/Google Calendar for events
- Reminders/to-do apps for chores
- Notes/messages for grocery lists
- paper or email receipts for purchases
- manufacturer sites/PDFs for manuals
- memory for filter/service dates
- photo libraries for serial labels
- filing cabinets for warranties

LunaHearth joins these into one local-first graph of household information.

The differentiation is not “more features in a calendar.” The key product behavior is **connection**:

- A refrigerator belongs to a room.
- Its warranty expiration creates an alert.
- Its filter maintenance creates a recurring task.
- A needed filter can become a shopping item.
- Completing maintenance updates the asset history and next due date.
- The household sees the result on Today and Calendar.

## 2. Target customers

### Primary
Apple-centric households with 2–6 people that actively coordinate schedules, groceries, chores, meals, home maintenance, appliances, warranties, and documents.

### High-value early adopters
- homeowners
- busy couples/parents
- households already using shared calendars/reminders
- people using dedicated family displays but wanting a software-first option
- users who value privacy/local processing
- users with many appliances/home systems and recurring maintenance

### Secondary
- renters managing possessions and warranties
- multi-generational households
- caregivers invited as limited participants
- individuals using the app as a personal home operating system

## 3. Jobs to be done

### Daily coordination
“When I open the app, tell me what matters to my household today without making me inspect five apps.”

### Family calendar
“Let us maintain shared household events without forcing everyone to expose their entire personal calendar.”

### Home memory
“Remember what we own, where it is, when we bought it, model/serial, receipt, warranty, and service history.”

### Maintenance
“Tell me what needs maintenance before I forget, and connect it to tasks/shopping.”

### Capture
“Let me turn a flyer, receipt, appliance label, or spoken sentence into structured household information with minimal typing.”

### Privacy
“Give my family useful software without creating another company account/database containing our family life.”

## 4. Product pillars

### Today
A calm household summary, not a noisy analytics dashboard.

### Family
People, household events, tasks/chores, routines.

### Home
Floors, rooms, assets, warranties, maintenance, documents.

### Food & shopping
Meal plan, groceries, household replacement items.

### Private intelligence
On-device extraction/planning where it reduces typing and cognitive load.

## 5. MVP scope

### Included
- local household setup
- household members/profiles managed by adults
- LunaHearth family events
- tasks and groceries
- basic meal planning
- floors/rooms/assets
- warranties and maintenance schedules
- Today dashboard
- document metadata and later local document vault
- optional Apple Calendar integration
- optional iCloud sharing after local MVP stabilizes

### Explicitly excluded from first release
- proprietary account/login
- public/social features
- child-owned accounts
- custom web backend
- Android/web clients
- remote LLM calls
- location tracking
- health/finance integrations

## 6. Core user stories

### Setup
As a new user, I can start immediately without login and create “Our Home.”

### Family
As an adult, I can add household members and assign colors/roles.

### Event
As a user, I can add a family event to LunaHearth without granting Calendar access.

### Calendar overlay
As a user, I can optionally connect selected Apple calendars to the household view.

### Home structure
As a homeowner, I can create floors and rooms manually even if my device cannot scan rooms.

### Asset
As a user, I can save an appliance with model, serial, purchase date, price, warranty, documents, and maintenance.

### Maintenance
As a user, I can set “change filter every 90 days”; completion records history and schedules the next occurrence.

### Shopping connection
As a user, maintenance can propose “buy 20x25x1 filter” into the household shopping list.

### Capture
As a user, I can photograph a receipt/label/flyer and review extracted fields before saving.

### Sync
As a household owner, I can optionally enable iCloud and invite another iCloud user without creating a LunaHearth account.

## 7. Information architecture

Five root destinations:

1. **Today**
2. **Calendar**
3. **Home**
4. **Lists**
5. **More**

### Lists contains
- Tasks & chores
- Groceries
- Meals
- Routines

### More contains
- Documents
- Family
- Privacy & sync
- Settings
- Diagnostics/export

## 8. Today ranking rules (initial)

Today should surface at most a manageable number of items. Suggested order:

1. urgent/overdue household alerts
2. next 3 events
3. due/overdue tasks
4. maintenance due within 7 days
5. warranty expiration within 30 days
6. today meal
7. shopping count

Avoid showing every record. “View all” routes to the owning feature.

## 9. Family roles

Initial product roles:

- **Owner** — created household/share; full local product control
- **Adult** — normal edit rights to shared household data
- **Child** — profile/assignment target; not an account in MVP
- **Guest** — future limited participant (e.g., caregiver/grandparent)

CloudKit participant permission and product role are related but not identical. Do not assume CKShare permission alone implements all role logic.

## 10. Privacy positioning

Accurate only if implementation continues to support it:

- Works offline
- No LunaHearth account
- No ads/tracking
- No NeuralLuna cloud database of family content
- Optional iCloud family sync
- On-device OCR/intelligence where supported

Avoid absolute marketing claims such as “data never leaves your phone” when the user enables iCloud.

Preferred wording:
- Local mode: “Stored on this device.”
- Sync mode: “Synced through your iCloud account. NeuralLuna does not operate a separate household-data backend.”

## 11. Monetization hypothesis

Do not implement pricing until validated.

Potential model:

### Free
- one household
- core calendar/tasks/groceries
- basic home inventory
- basic widgets

### LunaHearth+
- advanced home maintenance
- document/OCR workflows
- advanced meal/routine workflows
- enhanced household intelligence
- premium views/widgets
- extended history/export features

Never position the subscription as paying for Apple iCloud storage itself.

## 12. Success metrics without invasive analytics

Because the initial app avoids analytics SDKs, validation can use:
- opt-in TestFlight feedback
- App Store metrics available from Apple
- customer interviews
- support requests
- optional privacy-preserving diagnostic export initiated by user

If product analytics is later needed, create an ADR defining a privacy-preserving solution before adding instrumentation.

## 13. Competitive differentiation

Do not compete feature-for-feature with dedicated family displays or home inventory apps.

LunaHearth’s strategic wedge:

**Calendar + household operations + structured home memory + maintenance + local privacy.**

The app should feel like one connected system, not six mini apps inside a tab bar.

## Selected Apple lists — September 2026 update

ADR-010 supersedes earlier local shopping/task entry behavior. Shopping and Reminders each connect to one user-selected Apple Reminders list. Setup states that Apple Reminders is the source of truth, offers standard-list creation or existing-list browsing, and confirms the destination. Only that list's items appear and receive new writes. Shopping includes undated items; Reminders offers All, Today/overdue and Upcoming. Existing local items remain recoverable without automatic migration. List sharing instructions are available in-app; invitations and participant management happen in Apple Reminders because the public API does not expose those operations.

### Personal assigned shopping (ADR-016)

Today → For you shows open groceries assigned to the member selected on this device, including exact item count, quantities, store and Now/Later grouping. Completion updates the same household grocery record. Optional generic assignment alerts use private/shared iCloud background change hints; delays and missed delivery remain possible. The shopping brief is on-device only with a deterministic fallback. This is an in-app Today feature, not an iOS Home Screen widget.

### Groceries at home (ADR-017)

Home includes a separate grocery inventory with optional quantity, pack, store, location and calendar-only dates. South Indian, Indian and Everyday starter ideas can be tailored with on-device AI; users select what they own before saving. Shopping completion explicitly distinguishes stock for home from purchases kept elsewhere. Used-up inventory can return to shopping without guessing a reorder quantity. Coral/peach inventory visuals are distinct from shopping's green palette; no root tab or account is added.
