# AGENTS.md — LunaHearth engineering contract

This file is the authoritative instruction set for coding agents working in this repository. Read it **before modifying code**. If another document conflicts with this file, follow this file unless an explicit ADR supersedes it.

## 1. Mission

Build **LunaHearth**, a privacy-first local family + home operating system for Apple devices. The app must remain useful without network access and must not require a NeuralLuna account or third-party cloud service.

The product is not a clone of Skylight, Apple Calendar, Reminders, or any home inventory app. Implement original workflows and UI around a connected household model: people, schedule, home, rooms, assets, tasks, maintenance, shopping, meals, and documents.

## 2. Non-negotiable constraints

### Privacy / networking

- Core features MUST work entirely offline.
- Do NOT add Firebase, Supabase, AWS Amplify, Realm Sync, Parse, or any custom backend.
- Do NOT add OpenAI, Anthropic, Gemini, or other network LLM calls.
- Do NOT add advertising, attribution, tracking, behavioral analytics, session replay, crash SDKs, or telemetry SDKs without an approved ADR.
- Do NOT silently transmit household content anywhere.
- iCloud/CloudKit is optional and must be disabled gracefully when unavailable.
- Network access added for any future feature requires a threat/privacy review and ADR.

### Identity

- No email/password login.
- No OAuth login.
- No Sign in with Apple for MVP.
- The local app can identify an internal household member, but that is not an authentication account.
- Family collaboration uses CloudKit sharing and Apple/iCloud identity managed by the system.

### Dependencies

- Prefer Apple SDKs and the Swift standard library.
- Runtime third-party packages require an ADR and justification.
- XcodeGen is allowed only as a development-time project generator.
- SwiftFormat/SwiftLint may be used locally but must not become required runtime packages.

## 3. Platform and language rules

- Swift 6 language mode.
- Strict concurrency: `SWIFT_STRICT_CONCURRENCY = complete`.
- SwiftUI for UI.
- SwiftData for local persistence.
- Swift Testing for new unit tests unless XCTest is required by an Apple UI-testing API.
- Use structured concurrency (`async/await`, actors, task groups) instead of callbacks when an async API is available.
- Avoid `Task.detached` unless isolation requirements are documented.
- UI state mutation belongs on `@MainActor`.
- Mutable services that cross tasks should be actors or otherwise Sendable-safe.
- Never suppress concurrency diagnostics globally.

## 4. Minimum OS and availability

- Keep deployment target at iOS 18 unless an ADR changes it.
- Newer capabilities MUST be guarded using `if #available` / `@available` and capability checks.
- Foundation Models is an enhancement. A non-generative fallback must preserve core workflows.
- RoomPlan is an enhancement. Manual room creation must always remain available.
- Foldable/Duo layouts are enhancements. Regular iPhone layout is always supported.

## 5. Architectural boundaries

Use this dependency direction:

```text
Features/UI
   ↓
Domain protocols / use cases
   ↓
Data + Services adapters
   ↓
Apple frameworks / persistence / CloudKit
```

### Feature layer

`LunaHearth/Features/<Feature>`

Owns:
- SwiftUI views
- feature-specific presentation state
- view models when behavior warrants them
- navigation local to the feature

Must NOT:
- issue raw CloudKit operations
- call `FileManager` directly for document storage
- embed EventKit authorization logic inside views
- know CloudKit record keys

### Domain layer

`LunaHearth/Domain`

Owns:
- core models/value types
- repository/service protocols
- business rules
- deterministic calculations

Domain code should be testable without CloudKit, EventKit, RoomPlan, or UI.

### Data layer

`LunaHearth/Data`

Owns:
- SwiftData repositories
- CloudKit synchronization adapters
- record mapping
- sync state/change tokens
- file metadata persistence

### Services layer

`LunaHearth/Services`

Owns adapters for:
- EventKit
- Vision / OCR
- Foundation Models
- RoomPlan
- local notifications
- document file storage
- App Intents/Widget shared service interfaces where appropriate

## 6. Local-first persistence rules

The UI reads/writes the local store first. A user action must not wait for CloudKit to succeed.

Every syncable record must have:
- stable UUID generated locally
- `householdID`
- creation timestamp
- modification timestamp
- deletion/tombstone strategy where necessary
- deterministic CloudKit record name based on UUID

Do not use network-generated IDs.

User-visible data must survive:
- airplane mode
- iCloud unavailable
- CloudKit transient failures
- app relaunch while changes are pending

## 7. CloudKit rules

Read `docs/CLOUDKIT_SYNC.md` before touching sync.

Important:
- Do NOT turn on SwiftData automatic CloudKit mirroring as a shortcut for shared household data without an ADR.
- Household sharing is designed around explicit CloudKit custom zones + `CKShare`.
- Keep CloudKit schema keys centralized in mapping code.
- Treat CloudKit as a synchronization transport, not the only copy of data.
- Handle account unavailable, restricted, no-network, partial failure, zone deletion, share revocation, participant removal, and conflicts.
- Never wipe local data merely because a share becomes unavailable. Transition it to an explicit orphaned/read-only/recovery state according to the sync design.
- CloudKit debug logs must never dump document contents, private notes, serial numbers, or household free text.

## 8. Data-model rules

Read `docs/DATA_MODEL.md` before schema changes.

- Use normalized entities rather than a giant JSON household blob.
- Prefer stable IDs over object references for cross-boundary relationships that need CloudKit mapping.
- Money is stored as integer minor units + ISO currency code; never `Double`.
- Dates that represent instants use `Date`.
- Calendar-only dates require explicit date-only handling; do not accidentally shift days through time zones.
- Do not store full photos/PDF blobs inside SwiftData models. Store files in app-controlled file storage and metadata in SwiftData; use `CKAsset` later for optional cloud synchronization.
- Schema changes require migration consideration and a task/ADR when destructive.

## 9. UI and navigation rules

Primary tabs are intentionally limited to:

1. Today
2. Calendar
3. Home
4. Lists
5. More

Do not add a sixth root tab without a product decision.

### Today
Must answer: **What matters to this household today?**

Prioritize:
- upcoming household events
- due/overdue tasks
- maintenance/warranty alerts
- meal for the day
- shopping summary

### Calendar
- Family-owned events live in LunaHearth.
- Apple Calendar integration is optional.
- Never require users to share all personal Apple calendars.
- Support privacy choices such as hidden / busy-only / full-details at product level when implemented.

### Home
Hierarchy:
`Household → Floor → Room → HomeAsset → Warranty/Maintenance/Documents`

A room scan must never be the only creation flow.

### Lists
Contains tasks/chores, groceries, meals, routines. Avoid one tab per list type.

### More
Documents, family sharing, sync/privacy, settings, diagnostics.

## 10. Adaptive and Duo-class layout rules

- Use SwiftUI adaptive containers such as `NavigationSplitView` where they improve master/detail behavior.
- Do not hardcode device model names or screen pixel dimensions.
- Respond to horizontal size class, available geometry, scene/window state, and newer posture APIs when available.
- On compact layouts, use push navigation.
- On expansive layouts, prefer master/detail rather than simply stretching cards.
- Fold/posture behavior must never hide critical actions.
- Any iOS 27 Duo-specific API must be isolated behind a small adapter so the rest of the app stays testable and supports older OS versions.

## 11. On-device intelligence rules

Read `docs/AI_ON_DEVICE.md`.

Allowed uses:
- parse natural-language quick add
- extract structured event/task/warranty data from OCR text
- summarize locally stored household information
- suggest non-destructive organization

Rules:
- AI output is a proposal until user confirms when it can create/change important records.
- Never silently delete, purchase, message, share, or disclose data from a model suggestion.
- Do not make deterministic business logic dependent on generative output.
- Provide graceful fallback when the model is unavailable.
- Keep prompts free of unrelated personal data; pass the minimum context needed.
- Treat extracted dates/amounts/serial numbers as untrusted until validated.

## 12. Permissions

Ask just-in-time, not at launch.

- Calendar: only when user connects Apple Calendar or exports an event.
- Reminders: only when user enables integration.
- Camera: only when scanning room/document/label.
- Photos: use PhotosPicker where possible to avoid broad library access.
- Notifications: ask after user creates a due date/maintenance reminder and understands the value.

Never show a wall of permission prompts during onboarding.

## 13. Security

- Avoid storing secrets; there is no app password system.
- Protect sensitive local files using appropriate iOS file protection attributes when document storage is implemented.
- Avoid logging household content.
- Use `Logger` with privacy annotations if logging values.
- Never trust OCR/model output as a file path, URL, record key, or executable command.
- Sanitize imported filenames.
- Imported files must remain data, never executable content.

## 14. Testing expectations

Every feature PR should include tests for business logic.

Minimum test categories:
- model/use-case unit tests
- date/time-zone tests
- local persistence tests using in-memory SwiftData stores when practical
- sync mapper/conflict tests without requiring live CloudKit
- UI accessibility identifiers for critical flows
- snapshot tests are optional, not required

Do not require live iCloud credentials for the normal unit-test suite.

Before marking a task complete on macOS:

```bash
xcodegen generate
xcodebuild -project LunaHearth.xcodeproj \
  -scheme LunaHearth \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build

xcodebuild -project LunaHearth.xcodeproj \
  -scheme LunaHearth \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

If the named simulator is unavailable, discover a valid simulator with `xcrun simctl list devices available` and use it. Never claim tests passed if they were not run.

## 15. Code quality

- Prefer small focused types.
- Prefer composition over inheritance.
- Avoid singleton mutable state.
- Avoid giant view models.
- Keep formatting logic out of persistence models where possible.
- Use `LocalizedStringResource` / localization-ready APIs for user-facing strings as the app matures.
- Accessibility labels and Dynamic Type are required for production UI.
- Do not use force unwraps in production paths.
- `fatalError` is acceptable only for unrecoverable developer/configuration failures such as failure to initialize the local model container at app launch; production recovery should be designed before release.

## 16. Feature implementation workflow for Codex

For every requested feature:

1. Read relevant product docs and ADRs.
2. Restate the affected domain entities and privacy implications in the PR/task notes.
3. Add/adjust domain protocol first when external framework access is needed.
4. Implement local/offline path first.
5. Add optional Apple integration second.
6. Add tests.
7. Run build + tests.
8. Update docs if behavior, schema, privacy, capability, or architecture changed.
9. Never introduce a dependency because it is convenient without checking this file.

## 17. Definition of done

A feature is not done until:
- offline behavior is defined
- empty/loading/error states are handled
- privacy/permission behavior is explicit
- accessibility basics are present
- unit tests cover deterministic logic
- build/tests run or limitation is clearly reported
- docs/ADRs are updated when needed

## 18. Product decisions agents must not make autonomously

Ask for/record a product decision before:
- adding a root tab
- adding a proprietary account/login
- adding any non-Apple backend
- adding ads/tracking/analytics SDK
- changing subscription model
- making iCloud mandatory
- exposing child-facing accounts/social features
- adding public/community content
- raising minimum iOS version
- changing household ownership semantics
- destructive data migration
- adding health/financial/location tracking domains

## 19. Naming

- Product: `LunaHearth`
- Brand/publisher: `NeuralLuna`
- Bundle namespace: `com.neuralluna.lunahearth`
- Swift types use `LunaHearth` only when app-global; feature/domain types should use precise names.

`LunaHearth` is a working name pending formal trademark clearance. Do not purchase domains, create App Store metadata, or write legal claims based solely on the working-name search.
