# ADR-001: Local-first SwiftData with explicit CloudKit sharing

**Status:** Accepted

## Context

LunaHearth must work offline and optionally share one household with other iCloud users. SwiftData is an excellent local persistence layer, but user-to-user CKShare collaboration has different concerns from simple per-user CloudKit mirroring.

## Decision

- SwiftData is the local persistence layer and immediate UX source of truth.
- CloudKit sharing/sync is implemented explicitly using CloudKit APIs, custom record zones, and CKShare.
- Do not enable SwiftData automatic CloudKit mirroring for the shared household as an unreviewed shortcut.

## Consequences

Positive:
- clear offline semantics
- explicit control over CKShare ownership/participants
- testable sync mapping/conflict logic

Negative:
- more sync code
- schema mapping required
- conflict/retry design is our responsibility

## References
- https://developer.apple.com/documentation/cloudkit/ckshare
- https://developer.apple.com/documentation/cloudkit/sharing-cloudkit-data-with-other-icloud-users
