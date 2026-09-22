# ADR-020: Inventory attention and shopping shelves

Status: Implemented; physical two-account delivery and real model quality remain unverified.

## Household data audit

InventoryItem is scoped by householdID. LocalHouseholdRepository.reload filters inventory to the selected household. Stores and storage locations are attributes/references on packs, not separate stock databases. Purchases create inventory and update the grocery record in one local transaction. Backups include normalized inventory records, and shared sync uses the same mapper, validation, baselines, conflict handling and deletion tombstones. CloudKitHouseholdService routes owners to the private database and participants to the shared database; no public inventory data is used. SwiftData automatic CloudKit mirroring stays off.

Verified by code and tests: household switching/backup isolation, stock status backup round-trip, legacy JSON compatibility, expiry civil-day boundaries, and two-client fake-server stock update/deletion. This is not verification of live iCloud delivery. Existing limits remain: snapshot validation caps a household at 10,000 records and 25 MB payload; document/RoomPlan file attachments currently block snapshot creation, so receipt/photo file synchronization needs its own implementation before those features can rely on cloud transport. Metadata support alone must not be presented as receipt-image backup. The core store remains useful offline and sync errors retain local data.

## Low stock and expiry

InventoryItem adds optional isLowStock, also mapped in the existing InventoryItem backup/sync payload. Nil means no low-stock flag was recorded. Old payloads decode without the field; new packs do not inherit another pack's low-stock flag. InventoryDraft exposes an optional Running low toggle. This is user-reported per-pack status, not automatic consumption tracking, an ingredient-wide quantity total, or an AI inference. Used-up packs do not appear in active attention counts. Name remains the only required input. No destructive migration or public schema changes.

Expiry badges derive from recorded civil dates: before today is red Past expiry; today and the next seven days are amber; unknown dates remain explicitly unknown. The date classifier uses Gregorian civil-day arithmetic across month/year/DST boundaries. Color always accompanies text and an icon; adaptive colors support dark mode. Cards also have a subtle attention border. List and shelves use the same badges. Header actions filter dates needing attention or low-stock packs; the existing editor's Add to shopping retains duplicate protection.

All shared clients should update together: older clients can decode newer payloads while ignoring an optional field and can drop it on later edits. No live AI or automatic stock depletion is claimed.

## Shopping shelves

Shopping defaults to adaptive food-icon cards grouped by store, with a List switch and category filter. Cards retain amount, buyer, Now/Later, planned dates, purchase destination, editing/deletion via context menu and explicit add-to-inventory for bought items. Also at home reflects a matching active inventory ingredient without inferring remaining quantity or freshness. Purchase behavior remains transactional and unchanged. Header buttons use independent button styles so a tap cannot activate neighboring actions.

Optional user-triggered on-device category hints reuse PantryCategorizationService for up to 40 unfamiliar ingredient names. Bounded, validated results affect presentation only, are labeled, resettable and not persisted. Unknown/unavailable AI falls back to offline icons/categories. No runtime network AI, telemetry, new backend or new permissions.

## Artwork

A new synthetic shopping still-life was generated at development time using the built-in image-generation tool. It contains generic food only; no household contents were sent. The workspace asset and exact prompt are recorded in visual-review/shopping-shelves-design.md.
