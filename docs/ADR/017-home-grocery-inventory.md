# ADR-017: Home grocery inventory and explicit purchase destination

Status: Accepted for implementation. Real-device model generation and two-account iCloud verification remain pending.

## Product decision

Home → Groceries at home is a household pantry/fridge/freezer inventory, also reachable from Shopping. It is separate from rooms and durable home assets. One InventoryItem represents a pack/batch, not a universal product or an inferred stock total. Only name is required. Amount, pack size/brand, storage location, store, packed date, expiry date and purchased date are optional. Two packs with the same name remain separate so their dates are not lost. No expiry or remaining amount is guessed.

Pending shopping rows open an explicit destination choice: add to home inventory and mark bought, or mark bought without adding (friends/gifts/other destinations). Name, quantity and store copy directly; purchase day is the device's current civil day. Legacy completed rows do not automatically populate inventory. A completed row can explicitly add to inventory using its leading swipe action. Reopening or changing shopping status never silently removes or replenishes an inventory pack. Inventory's Used up action archives the pack; Add to shopping creates a new pending grocery with no assumed reorder quantity, blocking an existing pending same-name item.

## Entities, migration and persistence

Add InventoryItem with locally generated UUID, householdID, name, quantityText, packDetails, storeName/storeID, location, packedDay, expiryDay, purchasedDay, sourceGroceryID, isUsedUp, createdAt and modifiedAt. GroceryItem gains optional purchaseDisposition (`inventory` or `elsewhere`; nil for legacy data). Local SwiftData migration is additive; no existing records are converted or deleted. SwiftData automatic CloudKit mirroring remains off.

Purchasing commits the inventory insertion and grocery completion in one local transaction. A purchase-derived inventory UUID is a deterministic SHA-256-derived UUID scoped by household and grocery UUID. Repeating the same purchase while that inventory entry exists does not add quantity, create another pack, or reset Used up. Independently created offline copies use the same identity; different values follow the existing explicit conflict policy. Manual packs use fresh UUIDs. Source grocery IDs are provenance, not a required parent reference, so deleting a shopping-history row cannot cascade to owned inventory.

Inventory participates in normalized backups, validation, restore, global-ID collision checks, private/shared sync mapping and deletion tombstones. Store references must resolve within the household. Date-only strings validate as actual civil days; expiry cannot precede packed day. No new CloudKit record type or public data source is introduced: the existing LHHouseholdEntity payload maps the new kind. Older app builds do not understand InventoryItem and will reject that household sync safely; household devices must upgrade together before using this feature in a shared home.

## On-device suggestions and privacy

PantrySuggestionService returns bounded ingredient names only. Built-in South Indian, Indian and Everyday starter lists work immediately offline. Optional Foundation Models tailoring is user-triggered, gated to supported iOS 26+ devices, and receives only the chosen style, bounded request and bounded existing ingredient names. Names are untrusted data and validated/deduplicated. No quantities, stores, packing dates, expiry dates, ownership, allergy safety or dietary suitability are inferred. Nothing writes until the user selects items and taps Add. Selection starts empty. AI-unavailable fallback explicitly says custom instructions were not applied.

The app has no network LLM calls, new backend, telemetry, location lookup or new permission request. The same optional private/shared CloudKit opt-in controls inventory sync. Image generation is a development-time asset workflow, not a runtime app capability. Receipt/barcode/photo extraction is not part of this version.

## UI and accessibility

Inventory uses adaptive peach/coral surfaces and a new pantry still-life, distinct from green shopping. Name-first entry keeps optional details collapsed. Unknown dates are labeled, and date-attention state uses text as well as color. Native controls, Dynamic Type, accessible action labels and critical-flow identifiers cover manual entry, selected starter ideas, purchase destination and restock. Existing root tabs remain unchanged.

## Validation scope

Unit tests cover required-name-only creation, optional-field backup/restore, store references, real civil dates, invalid date order rollback, purchase pair atomicity, repeat purchase IDs, foreign-household rejection, friends/legacy behavior, separate batches, review-only ideas, duplicate restock, read-only protection, deletion independence and fake-server sync/tombstones. Simulator UI checks cover manual pantry setup, South Indian selection, both purchase destinations and Used up/restock. Physical iCloud delivery, real Foundation Models generation and an upgrade of an existing physical store require separate verification.

## Matching inventory during shopping completion

Shopping completion now checks active ingredient aliases before creating a pack. A matching ingredient requires an explicit Keep existing entry or Add a separate pack choice. Keep existing marks the shopping purchase as stocked without creating inventory or overwriting its free-text quantity, dates or provenance. The user can edit the inventory amount separately; units are not silently summed. Repository validation enforces this for every caller and rechecks the selected active household match. A purchase already marked as stocked cannot create another pack on retry/reopen; bought items already stocked do not show an add-again action. Existing duplicates remain available for explicit review/removal rather than being destructively merged. No schema change.

When multiple matching packs already exist (including case-only duplicates such as milk/Milk), the finish-shopping screen shows one Use existing action. A secondary picker exposes each saved pack's amount/date/store/location, selection and confirmed duplicate deletion. No physical packs are assumed redundant merely because names match. Removing an accidental duplicate leaves shopping open until Use selected completes it. Single matches keep the one-tap path. This is presentation/workflow only; existing validated repository operations and sync tombstones are reused.

## Restocking an existing ingredient — build 22

An explicit new shopping purchase using **Restock existing** clears the selected active InventoryItem's `isLowStock` flag and updates `modifiedAt` in the same local transaction that completes the GroceryItem. This supersedes the earlier Keep existing behavior that left the low-stock flag unchanged. Alias matching, household validation, read-only protection and duplicate avoidance remain in force. Existing free-text quantity, expiry/packed/purchase dates and provenance are preserved; no unit arithmetic or expiry extension is inferred. A separately requested pack retains its own amount/dates and does not rewrite an older pack. Buying for someone else leaves home stock alone.

Once a shopping row has stocked inventory, its inventory disposition remains a receipt of that side effect even if reopened and finished without stocking. Repeating that historical purchase cannot clear a later low-stock flag. A genuinely new purchase uses a new shopping row. This uses existing fields, local persistence and the existing private/shared sync mapping; no schema, networking or permission changes. Automated tests cover curd restocking, persistence/backup, unchanged amount/expiry, repeated completion, friends' purchases and separate packs. Live two-device cloud delivery is not a unit-test assertion.
