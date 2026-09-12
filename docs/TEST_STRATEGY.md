# Test Strategy

## 1. Goals

Tests protect household data first. A beautiful screen with unreliable recurrence/sync is a product failure.

## 2. Pyramid

### Unit tests — many
- date calculations
- warranty status
- maintenance next-due computation
- Today ranking
- parsing validation
- CloudKit mapping
- conflict merge
- permission-independent business rules

### Persistence integration — moderate
Use in-memory SwiftData containers.

Test:
- CRUD
- relationships/IDs
- archive/delete
- migration where possible

### UI tests — targeted
Critical flows:
- first-run local setup
- add event/task/home item
- add maintenance
- deny Calendar permission and continue
- navigate compact layouts

### Real CloudKit tests — manual/integration lane
Must not block normal local unit suite.

## 3. Required date tests

- DST spring/fall transitions
- device time-zone change
- all-day event boundaries
- maintenance “every N days” using Calendar arithmetic
- warranty expiring today
- leap year
- date-only meal plan

## 4. Maintenance tests

Given interval 90 days and completion date, next due is calendar +90 days.

Test:
- repeated completion
- early completion
- late completion
- editing interval
- deleting asset with maintenance history

## 5. Sync mapper tests

For every record type:
- local → CKRecord DTO mapping
- CKRecord → remote DTO mapping
- missing optional field
- unknown future field ignored
- schema version behavior

Avoid requiring actual CKDatabase operations in these unit tests.

## 6. Conflict tests

Construct local/server versions and assert merge outcomes.

Never ship a conflict policy without fixtures for:
- task completion + title edit
- grocery completion + quantity edit
- asset simultaneous edits
- deletion vs update

## 7. AI tests

Separate:
- deterministic validation tests
- model evaluation tests

App unit tests must not depend on stochastic model availability.

Use fake `HouseholdIntelligenceService` for UI/use-case tests.

## 8. Privacy tests/checks

- logs do not contain sample secret strings
- export includes only selected household
- deleting local data removes document files
- denial of permission does not crash
- iCloud-disabled app never requires network

## 9. Accessibility checks

Manual + UI test where practical:
- Dynamic Type XXL/accessibility sizes
- VoiceOver labels
- color-independent member identity
- keyboard navigation on iPad if supported
- Reduce Motion

## 10. Build gate

Before merging on macOS:

```bash
xcodegen generate
xcodebuild -project LunaHearth.xcodeproj -scheme LunaHearth -destination '<available simulator>' build
xcodebuild -project LunaHearth.xcodeproj -scheme LunaHearth -destination '<available simulator>' test
```

Report exact command/result. Never say tests pass from code inspection alone.
