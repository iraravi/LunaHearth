# ADR-014: Reusable private household stores

Status: Accepted — user requested private CloudKit store records, September 12, 2026.

## Decision and scope

Add a normalized ShoppingStore entity with a local UUID, householdID, name,
optional branch, createdAt and modifiedAt. GroceryItem adds optional storeID and
retains storeName as a legacy/display fallback. Stores outlive shopping items.
The bundled 32-chain catalog is only an offline suggestion source; selecting a
chain or saving a custom shop creates/reuses a household store.

Local SwiftData writes commit before optional cloud synchronization. Store records
use the existing explicit private owner zone and participant shared-database
transport, never public CloudKit. They are included in private manual backups too.
No store API, geolocation, account, dependency or network AI is introduced. Branch
is user-entered text, not tracked location. The existing opt-in and sharing scope
apply; recipients of the household share can see its store records.

## Identity and duplicates

IDs are locally derived UUIDs from SHA-256 of a versioned namespace, household UUID
and normalized display label. This makes equivalent creations on offline devices
use one record ID. IDs are fixed after creation. The existing optimistic conflict
review policy applies if concurrent versions differ. Known catalog aliases and
case/spacing/punctuation variants reuse records; different branch labels remain
separate. There is no fuzzy or AI merge. Stable IDs are not global store IDs.

## Migration and compatibility

Additive SwiftData table and optional GroceryItem.storeID; retain all old names.
On reload of a writable home, unlinked named groceries get reusable stores and
links in one saved transaction, with a new item modification timestamp. This is
idempotent and skipped for read-only/recovery homes. Nil store IDs in old backup
payloads remain decodable and are backfilled after restore. Malformed legacy names
longer than the current limit remain intact without automatic conversion.

BackupCodec validates same-household store references and transports stores as
individual ShoppingStore payloads. CloudKit continues using LHHouseholdEntity with
existing keys; no new CloudKit type or field is needed. New entity kinds are
rejected safely by older clients, so all participants must update before sharing
this revision. Old apps cannot restore backups containing ShoppingStore records.
The envelope version stays 1; unknown-kind rejection prevents silent data loss.

## Deletion and release limits

Deleting an item leaves its store. Individual stores have no delete/rename UI in
this revision, matching the existing non-deletable parent-entity policy; unsafe
remote store tombstones are rejected. Owner private-cloud deletion still removes
the whole zone and preserves local records. Store management can be added with
explicit reference/archive semantics later.

Production schema was deployed successfully during build 3 distribution. Physical
two-account validation remains pending from the prior release. Simulator/fake transport tests do not establish live iCloud
acceptance, delivery or quota behavior. Disk tests exercise the added table and
backfill/reopen; upgrading a real prior TestFlight binary remains a release check.
