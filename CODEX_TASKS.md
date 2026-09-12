# LunaHearth — Codex implementation backlog

This is an ordered engineering plan. Codex should complete tasks in sequence unless a task explicitly states that it is independent.

## Phase 0 — repository health

### P0.1 Generate and validate Xcode project
**Goal:** Open the repository on macOS and produce a clean Xcode project.

Acceptance criteria:
- `xcodegen generate` succeeds.
- `LunaHearth.xcodeproj` opens without missing file references.
- App target and test target build on an available iOS simulator.
- Swift 6 strict concurrency remains enabled.
- No third-party runtime package is added.

### P0.2 Add asset catalog and app icon placeholders
Acceptance criteria:
- Valid `Assets.xcassets` exists.
- App builds without asset catalog errors.
- Do not create final branded artwork; use neutral placeholders pending brand clearance.

### P0.3 CI-ready build script
Acceptance criteria:
- A script discovers an available simulator rather than assuming one exact device.
- Build and unit-test commands return nonzero on failure.

---

## Phase 1 — local-only MVP foundation

### P1.1 First-run household setup
Flow:
`Welcome → Get Started → Household name → Add adults/children (optional) → Today`

Rules:
- No login/account.
- No iCloud prompt during the first screen.
- User can skip adding members.

Acceptance criteria:
- Household persists locally.
- Relaunch goes to Today.
- Reset-local-data debug action exists in DEBUG builds.
- Unit tests cover creation and validation.

### P1.2 Repository layer over SwiftData
Create repositories for:
- household/member
- family events
- tasks
- groceries/meals
- home/floor/room/assets
- warranty/maintenance
- document metadata

Acceptance criteria:
- Views no longer construct persistence queries for complex domain behavior directly.
- Repositories can be exercised against an in-memory ModelContainer.
- CRUD tests exist.

### P1.3 Quick Add domain
Supported local commands/forms:
- Event
- Task
- Grocery item
- Meal
- Home item
- Maintenance

Acceptance criteria:
- Quick Add reachable from primary screens.
- Structured manual form always works without AI.
- Natural language parser fallback never blocks manual entry.

### P1.4 Today dashboard from real data
Acceptance criteria:
- Shows today’s events ordered by start.
- Shows due/overdue tasks.
- Shows warranty alerts within configurable horizon.
- Shows maintenance due/overdue.
- Shows today meal and open shopping count.
- Empty household receives helpful setup prompts.
- No network dependency.

---

## Phase 2 — Calendar and family organization

### P2.1 Native LunaHearth family calendar
Acceptance criteria:
- Day and agenda views first; week/month may follow.
- Events can be assigned to household member or Family.
- Member colors are accessible and not the sole indicator.
- Time-zone handling has tests.

### P2.2 EventKit read integration
Acceptance criteria:
- Permission requested only when user taps Connect Apple Calendar.
- User chooses which calendars to display.
- LunaHearth remains fully functional when denied.
- Imported/displayed EventKit events are distinguishable from LunaHearth-owned events.
- Never duplicate external events into local writable events without explicit import.

### P2.3 Apple Calendar write/export
Acceptance criteria:
- Separate explicit action such as `Add to Apple Calendar`.
- Request write-only access when full access is not needed.
- Failed write never deletes or changes LunaHearth event.

### P2.4 Tasks, chores, routines
Acceptance criteria:
- Assign member.
- Due date optional.
- Recurrence supported using an explicit recurrence model, not a mystery string before production.
- Completing a recurring task schedules the next occurrence deterministically.
- Child profiles are managed by adults; no child login/account.

---

## Phase 3 — Home model

### P3.1 Floors and rooms
Acceptance criteria:
- Household can have zero or more floors.
- Rooms may exist without a floor.
- Ordering is user-controlled.
- Compact UI uses push navigation; expansive UI uses master/detail.

### P3.2 Home assets
Fields:
- name/category
- room
- manufacturer/model/serial
- purchase date/price/currency
- notes

Acceptance criteria:
- Purchase price uses integer minor units.
- Search by name/model/serial.
- Moving item between rooms preserves warranty/documents/maintenance links.

### P3.3 Warranty tracking
Acceptance criteria:
- Start/end dates optional.
- Today dashboard surfaces upcoming expiry.
- Configurable alert horizons initially: 7/30/60 days.
- Warranty record can link documents.

### P3.4 Maintenance engine
Acceptance criteria:
- Recurring interval schedules.
- Completing maintenance updates history and computes next due date.
- Optional template can propose a shopping-list item.
- Example workflow supported: HVAC filter → due task → replacement filter grocery item → completion → next due date.

---

## Phase 4 — Documents and OCR

### P4.1 Local document vault
Acceptance criteria:
- Import through system document picker / PhotosPicker.
- Files copied into app-controlled Application Support storage.
- Filename sanitized.
- Metadata stored in SwiftData.
- Use iOS file protection suitable for user documents.
- Preview/share/export supported through system UI.

### P4.2 Vision OCR
Acceptance criteria:
- Runs on-device.
- Supports receipt, appliance-label, warranty, manual-cover, and event-flyer extraction workflows.
- Original file remains available.
- Extracted structured values require confirmation.

### P4.3 Receipt/appliance extraction
Acceptance criteria:
- Detect likely merchant/date/amount/model/serial candidates.
- Never trust OCR amount/date without validation.
- User can edit every extracted field before save.

---

## Phase 5 — optional iCloud family sharing

### P5.1 iCloud readiness screen
Acceptance criteria:
- Settings clearly shows `This Device Only` by default.
- User explicitly enables family sync.
- Account unavailable/restricted states are understandable.
- No data loss when enablement fails.

### P5.2 CloudKit schema + mapping
Acceptance criteria:
- Dedicated custom zone per household owned by creator.
- Deterministic CKRecord IDs.
- Record mapping unit-tested without live CloudKit where possible.
- Change tokens persisted safely.
- Cloud schema documented.

### P5.3 CKShare household collaboration
Acceptance criteria:
- Owner can invite collaborator through system sharing UI.
- Participant can accept share and load household.
- Permissions map to product roles where CloudKit semantics allow.
- Removing participant does not corrupt owner data.
- Participant losing share access gets a clear recovery/read-only UX.

### P5.4 Offline mutation queue and conflict policy
Acceptance criteria:
- Local edits work offline.
- Pending sync state survives relaunch.
- Per-entity conflict rules are implemented/documented.
- No whole-household last-write-wins blob.
- Partial CloudKit failures retry only failed records.

### P5.5 Document CKAsset sync
Acceptance criteria:
- Optional and user-visible.
- Large assets are not loaded eagerly.
- Local file remains usable when cloud asset unavailable.
- Quota/storage errors are understandable.

---

## Phase 6 — on-device intelligence

### P6.1 Capability adapter
Acceptance criteria:
- One protocol abstracts Apple Foundation Models.
- App compiles/runs where Foundation Models unavailable.
- Rule-based/manual fallback remains.

### P6.2 Natural-language Quick Add
Examples:
- “Saturday Costco and buy milk, eggs, chicken.”
- “Change upstairs AC filter every 90 days.”
- “Kira school festival September 24 at 5:30 and bring snacks.”

Acceptance criteria:
- Model proposes structured changes.
- User confirms before records are created when ambiguity exists.
- Parser has deterministic validation layer.

### P6.3 Multimodal extraction
Acceptance criteria:
- OCR/Vision runs locally.
- Model receives only minimum extracted/selected content.
- Supports event flyer and appliance-label flows.
- No third-party inference endpoint.

---

## Phase 7 — RoomPlan and richer Home UX

### P7.1 Device capability check
Acceptance criteria:
- `Scan Room` shown only when supported.
- Manual room creation always present.

### P7.2 RoomPlan capture
Acceptance criteria:
- Camera permission requested just in time.
- Captured structure stored as local asset with metadata.
- User can rename room and attach manually created assets.
- Do not promise object identification beyond what RoomPlan actually provides.

### P7.3 Multi-room visualization
Acceptance criteria:
- Optional visualization does not become required navigation.
- Accessibility has a list-based equivalent.

---

## Phase 8 — widgets, App Intents, notifications

### P8.1 Today widget
Show:
- next family event
- due task count
- maintenance alert
- shopping count

Acceptance criteria:
- Glanceable.
- Deep links into correct app destination.
- Shared snapshot storage is privacy-reviewed.

### P8.2 Interactive task widget
Acceptance criteria:
- App Intent marks task complete safely.
- No network required.
- Recurring completion rules preserved.

### P8.3 Siri/App Intents
Initial intents:
- Add grocery item
- Add household task
- Mark task complete
- Ask for next household event

### P8.4 Local notifications
Acceptance criteria:
- Local notifications only for MVP.
- Ask permission after user creates a reminder-worthy item.
- No remote-push backend.

---

## Phase 9 — premium / release

### P9.1 StoreKit 2
Potential premium features must be finalized before implementation.

Constraints:
- Do not sell “iCloud storage.”
- Free tier remains useful.
- Subscription state cached locally and restored via StoreKit.

### P9.2 Export / backup
Acceptance criteria:
- Export household data in documented portable format.
- Export documents separately or as archive.
- User can delete local household data.

### P9.3 Privacy and App Store release gate
- Privacy policy
- Terms
- App Privacy labels
- Trademark clearance
- Accessibility audit
- CloudKit production schema
- StoreKit product review metadata
- Permission-purpose-string review
- No debug/sample private data

---

## Deferred until explicit product approval

Do not implement autonomously:
- Android/web accounts
- custom backend
- public social/community
- family chat with unknown users
- child accounts/login
- location tracking/geofences
- health records
- bank/financial integrations
- advertising
- third-party analytics
- remote LLM providers

## Implementation checkpoint — September 11, 2026

The first local build implements P0 project generation and simulator discovery; persisted onboarding with validation; local repository-backed creation/editing; manual Quick Add; a real Today dashboard; and initial calendar, lists, room/item, warranty, and maintenance workflows. Do not mark every phase complete: full repository segmentation/document CRUD, advanced home fields/ordering, recurrence, integrations, and release QA remain outstanding. See `docs/IMPLEMENTATION_REVIEW.md` for exact scope and limitations.
