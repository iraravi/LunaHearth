# ADR 030: Linked purchase history

Accepted 2026-09-13, user requested connected expense, shopping and inventory history.

## Data and privacy
Add normalized PurchaseEntry records, grouped by a stable purchaseID. Each line stores householdID, stable local UUID, timestamps, optional expense/shopping/inventory IDs, purchased name/quantity/store/date snapshots, optional reviewed item total in integer minor units and currency, and stock action. Receipt expense remains the group total including tax/discounts. No photos, payment data or raw OCR are added. Local transaction first; optional existing private/shared CloudKit transport includes these records. No new network service or permissions.

## Behavior
Receipt import commits expense, shopping completion, stock action and history together. Deterministic receipt-line IDs prevent replay even after shopping records disappear. New shopping completions also record history. Purchase history is accessible under Home, from expenses, inventory and receipt completion. A purchase without an expense can receive one later without repeating stock actions. Duplicate expense linking is rejected. Historical links tolerate deleted targets; snapshots remain visible. Expense edits/refunds/deletions never undo physical stock. Restocking records the purchased quantity and clears Low stock, but does not arithmetically combine free-text quantities or change expiry dates.

## Compatibility and scope
Additive SwiftData model, no destructive migration or inferred historical backfill. Existing installs retain data. Both household devices should update: older builds cannot decode the new record kind. Existing sync uses entity conflict resolution; simultaneous independent receipts with different OCR fingerprints are not guaranteed deduplicated. The ledger is historical purchase evidence, not a numeric stock-accounting engine. Optional line prices are manually reviewed; tax/discount allocation and unit conversion are deferred. Historical purchase data is removed with household data, not by deleting its expense or shopping record.

## Validation
Unit tests cover atomic links, repeat import, restock history, attaching expenses later, invalid-price rollback, backup/restore and deleted targets. UI tests cover receipt → purchase details → expense on iPhone/iPad. Device installation and final results are recorded in TESTFLIGHT_RELEASE.md.
