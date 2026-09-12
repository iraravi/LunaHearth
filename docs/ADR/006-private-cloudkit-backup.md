# ADR-006: Manual private CloudKit backups before collaboration

Status: Accepted for the requested optional cloud-storage implementation; CKShare collaboration remains governed by ADR-001.

## Scope and user experience

A user can explicitly save a complete household backup to their own Apple Account from More → iCloud backup. A new installation can find, review and restore that backup from the welcome screen. No app login is introduced. There is one latest backup per Apple Account; saving shows a confirmation that the previous backup will be replaced. This is manual backup/restore, not background sync or live family collaboration.

Local setup creates Household, optional HouseholdMember profiles and an optional first Room in one transaction. Home directs users from room to item to warranty and maintenance. No permission or network request occurs during local setup.

## Data and transport

SwiftData remains local with CloudKit mirroring disabled. Each supported entity is encoded independently into a versioned, normalized CloudKit record with UUID record name, household ID, kind, creation/modification dates and Codable per-entity payload. Supported entities: Household, HouseholdMember, HomeFloor, Room geometry, HomeAsset, Warranty, MaintenancePlan, MaintenanceHistory, FamilyEvent, HouseholdTask, GroceryItem and MealPlanEntry (including civil dateKey).

A backup uses a fresh immutable custom zone. Upload operations are bounded to 100 records / 4 MB payload, and each result is checked. Only after every record succeeds is the catalog's latest manifest updated using optimistic change-tag concurrency. A failed or interrupted upload cannot publish a partial generation. After acknowledged publication, the former generation is retired. Failed staging generations are cleaned up on a best-effort basis when the account is unchanged. Generations from ambiguous publication errors or interrupted cleanup may remain and consume quota; automatic orphan cleanup is a future enhancement. Retry creates a new generation and never erases the local store.

Snapshot limits: 10,000 records, 500 KB per entity payload and 25 MB total payload. Exceeding these limits produces an error without claiming a successful backup. Restore downloads the complete manifest, checks unique IDs, supported version/type, metadata and cross-entity links, then inserts atomically into an empty local household store. It never merges or replaces an existing local home. Snapshot semantics omit deleted records; collaborative tombstones/outbox/merge are still required before live sync.

Document/RoomPlan files and their device-local paths are not transported. A home containing these files is rejected for backup rather than producing a misleading incomplete backup. No existing SwiftData schema is changed by backup support.

## Privacy and threat review

- Network access starts only after a deliberate Find backup or confirmed Save backup action.
- The confirmation explains that household names, profiles, schedules, item details and notes go to Apple iCloud, including any sensitive free text users entered.
- Uses only the configured CloudKit container's private database and Apple Account identity; no public database, third-party service, analytics or app credentials.
- No logging of household content, account identifiers or record payloads.
- Account availability is checked at operation start; account identity is rechecked before publishing and before returning downloaded data. Account loss/change never deletes local records.
- Incoming payloads are data, decoded into known DTOs; unsupported versions/types, duplicate IDs, broken links and incomplete geometry are rejected before mutation. File paths are never restored.
- Concurrent backup publications are rejected through CloudKit change tags; there is no blind overwrite of another concurrent writer.
- Offline, quota, provisioning, transient and partial failures produce a visible retryable failure. The local app remains available.
- No promise of end-to-end encryption is made; CloudKit storage follows Apple account/service protections.

## Release validation still required

Configure an authorized Apple Development Team and provision `iCloud.com.neuralluna.lunahearth` in Xcode. The Info.plist team check prevents initialization in unsigned builds and UI tests; it does not prove container entitlement/provisioning correctness. Deploy the development schema to production before distribution.

Use two devices on the same Apple Account to verify upload → reinstall/empty-store restore, geometry and care history, large batches, airplane mode, quota failure, account change, concurrent publication and interrupted uploads. Normal automated tests run offline against local stores and do not establish live CloudKit success. CKShare, participant acceptance/removal, change tokens and continuous sync remain unimplemented and are not advertised as available.
