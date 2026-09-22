# ADR-012: Live private CloudKit household sharing

Status: Accepted by explicit user request on September 12, 2026: “we need live icloud sharing too.” Extends ADR-011; replaces its manual-backup-only limitation. Also removes room selection from initial home creation.

## Product behavior

Setup asks only for a clearly labeled home name. Personal/family choices, display names, member profiles and room selection are omitted from creation per the user’s final direction. Rooms are created from Home afterward; people and sharing live in More. More → iCloud & sharing offers explicit private sync enablement, Apple’s invitation/participant UI, Sync now, iCloud home discovery and switching between local homes. Joining another home keeps the existing household separate and never uploads or merges it.

The owner enables uploading before inviting anyone. `CKShare(recordZoneID:)` shares a custom `LHHousehold-<UUID>` zone. Owner records live in the private database; invitees access the shared database. Public permission is none and the sharing controller permits private invitations only. An Apple Account and iCloud access are needed for collaboration. Profiles are not Apple identities or invitations.

Current automatic delivery runs after local writes (one-second debounce), on foreground/household changes, and every 20 seconds while active. This is live foreground synchronization, not a guarantee of instantaneous or background delivery. No remote-notification/background entitlement is added. Manual private snapshots remain a separate recovery feature.

## Domain and persistence

Sync includes Household, HouseholdMember, FamilyEvent, HouseholdTask, GroceryItem, MealPlanEntry, HomeFloor, Room, HomeAsset, Warranty, MaintenancePlan and MaintenanceHistory. Record names are locally generated UUIDs. Existing normalized per-entity Codable values and validation are reused; there is no single household JSON cloud record. Document and room-scan files remain unsupported and prevent enablement/upload rather than being silently omitted.

Additive device-local tables:
- HouseholdSyncConfiguration: household/zone, owner/participant database scope, opaque account binding, read-only/recovery state, change token and last success.
- HouseholdSyncBaseline: one acknowledged remote value and server system fields per entity, plus an unresolved-conflict flag.
- ActiveHouseholdSelection: the active household UUID. A missing selection preserves the previous oldest-home default.

No domain records are deleted or converted during schema upgrade. Baselines, tokens, account bindings and active selection are excluded from backups. Local records are the durable pending queue: differences from baselines represent unsent edits, and a missing previously acknowledged planning record represents a pending deletion. Deletions are uploaded as tombstones with stable UUIDs. Retained tombstones are not garbage-collected in this version.

## Merge and failure handling

Three-way comparisons use local values, last acknowledged values and current remote values. Equality uses canonical payloads rather than CloudKit timestamp precision, preventing redundant uploads after server date rounding. Independent records merge automatically. Same-record conflicts—including completion/reopen, assignment and critical asset changes—require explicit review of both versions. Conflict baselines persist across restart. The user chooses local or cloud versions for the displayed conflict set. Layout combinations that overlap are rejected, with incoming geometry shown for local adjustment before retry.

Record tags and `ifServerRecordUnchanged` prevent racing writers from silently replacing server changes. Uploads are bounded by record count and payload bytes; only acknowledged saves advance a baseline. Partial or uncertain results retry using stable record names. Local edits made during network waits are re-read before merge, and upload acknowledgements never replace newer local values.

Incoming graphs validate before an atomic transaction applies data, baselines and the change token. Token expiration triggers a full fetch without deleting pending local changes. Unknown schemas, malformed references and unexpected physical deletions halt reconciliation. Account changes, zone loss and revoked access transition the local home to visible recovery mode; its data remains readable and available for backup. Read-only permissions are rechecked and repository writes are blocked while preserving any earlier pending changes. Network/quota failures keep the editable local copy and surface a pending/error banner, with bounded exponential retry and CloudKit retry guidance.

## Privacy / threat review

Only an explicit enable action uploads household content. Discovery reads only the current account’s private/shared LunaHearth zones. Accepted invitations validate container and zone identity; foreign UUID/type collisions cannot overwrite another local household. Incoming payloads remain data, never paths or executable content. No household text, share URLs, documents or identifiers are logged.

The current Apple account is checked against the saved opaque transport binding before operations and after network batches; an account switch cannot redirect an existing household into a different account. The binding is sync metadata, not product authentication or a household member identity. Shared access reveals the whole selected home to invitees; the UI explains this before invitation. Existing personal homes and optional Apple Reminders lists stay outside the shared zone. Reminders mirroring and cloud AI remain off.

## Bounds and acceptance checks

This first transport limits a zone read to 10,000 entity/tombstone records and 25 MB of payload. Documents, large assets, tombstone compaction and background push delivery remain future work. Automatic schema creation applies in Development; deploy LHHouseholdEntity schema before TestFlight/Production and use the same CloudKit environment on both devices.

Automated tests use two local repositories and a fake server for edit/completion propagation, preservation of an existing personal home, offline persistence, tombstones, partial acknowledgements, conflicting edits, recovery/read-only access, mapper validation and disk reopen. The normal suite never uses real iCloud credentials. A physical two-Apple-Account invite/accept/offline/revoke check remains required before claiming production readiness.

References:
- https://github.com/apple/sample-cloudkit-zonesharing
- https://developer.apple.com/documentation/cloudkit/ckshare
- https://developer.apple.com/documentation/cloudkit/ckdatabase/recordzonechanges(inzonewith:since:desiredkeys:resultslimit:)
- https://developer.apple.com/documentation/coredata/accepting-share-invitations-in-a-swiftui-app
