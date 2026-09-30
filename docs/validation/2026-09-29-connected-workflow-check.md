# Connected household workflow check — September 29, 2026

## Scope
Rechecked shopping completion → pantry restock → purchase history → receipt reconciliation → monthly expense reporting, plus shared-home transport/merge behavior and stale assignment-alert clearing. Reviewed the repository transaction boundaries, receipt validation, stable purchase IDs, notification refresh, CloudKit adapter and sharing controller.

Entities: GroceryItem, InventoryItem, PurchaseEntry, HouseholdExpense and household sync baselines. No production schema, permission, network, model prompt or user-data changes. Tests use synthetic local stores and an in-memory shared server. No live household was reset or modified.

## Checks
- Compatible measured quantities combine (including kg/g and litre/ml); incompatible or unknown quantities are not guessed.
- Restocking an eligible existing pack clears Low stock. Expired/used-up packs are not silently reused.
- Repeating purchase completion does not increment inventory again; deliberately separate packs remain possible.
- Linking a receipt to an existing purchase adds its expense evidence without restocking, changing expiry, or reviving a consumed pack.
- Exact receipt replays do not duplicate purchases/expenses; invalid reviews roll back before partial writes.
- Monthly amounts use integer minor units and currency filtering.
- Local purchase/receipt/meal state survives store reopening and backup restoration.
- Simulated shared households propagate purchase/receipt links, retain offline changes, and require explicit conflict resolution for simultaneous stock edits.
- Assignment notification refresh clears obsolete delivered/pending summaries when items are bought.

## Added regression
`HouseholdSharingTests.sharedRestockClearsLowStockAndReceiptReplayKeepsOneBalance` exercises one connected scenario across two local repositories: participant restocks Curd from 500 g to 1500 g; both retain one pack, clear Low stock and complete the same grocery; owner attaches a USD 4 receipt; participant replay adds nothing; both show one linked purchase/expense and a 400-cent monthly total.

## Validation
- iPhone simulator build succeeded; all 266 Swift Testing tests in 49 suites and the grocery performance XCTest passed (`/tmp/luna-connected-check.log`).
- iPad simulator: all 29 household-sharing tests passed, including the newly added connected restock/receipt regression (`/tmp/luna-connected-ipad.log`). This adds one unique test to the existing 266.
- All six targeted UI scenarios passed: measured restock, linking an already-bought receipt and monthly expense dashboard, each on iPhone and iPad. Both runs ended with `TEST SUCCEEDED`.
- Xcode emitted a post-test diagnostic-collection `simctl` lookup error despite the explicit developer path; this did not fail any test. The iPad expense run also emitted a transient invalid-frame warning; the dashboard assertions passed, but this run does not establish that all layout warnings are resolved.
- `git diff --check` passed. Only the new regression and this report were added for this check; no production logic was changed.

## Limits
The shared server tests exercise application sync logic, not Apple's live service. Actual Ravi/Kira iCloud delivery, background push timing, Apple account permissions, physical-device battery use and real receipt OCR accuracy are not established by these tests. A shared stock conflict preserves both versions for review; it does not automatically sum independent offline purchases.
