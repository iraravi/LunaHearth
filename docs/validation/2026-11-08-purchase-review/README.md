# Purchase and pantry review clarity

Branch: codex/purchase-review-clarity. Not uploaded to TestFlight.

## Findings and changes

Receipt review displayed historical purchases from the seven-day matching window before the new-purchase action. Bare dates and adjacent pantry controls made history linking look like pantry restocking. Pantry restock selection was also hidden in Quantity & matches, and receipt imports had no explicit separate-pack choice.

- Historical purchases are inside Already recorded? Attach receipt, labeled Previous purchase with readable dates.
- Record this purchase explicitly means buying more, not creating a duplicate pantry item. Pantry controls appear after that decision when previous purchases match.
- Existing pantry handling is visible: add compatible quantities to a selected pack, keep a separate pack, or turn off Add to pantry.
- Separate-pack intent is validated in the local transaction. It cannot simultaneously target an existing pack; no fallback merge is allowed.
- Existing pack quantities and dates survive separate-pack import and receipt attachment. Restocking preserves original pack purchase date; the new purchase date remains in purchase history.
- Shopping completion uses Add to existing pack, Keep a separate pack, and Don’t add to pantry wording.

Domain entities: ReceiptLine transient review state, InventoryItem, GroceryItem, PurchaseEntry, HouseholdExpense. No persisted schema or CloudKit mapping changes. All logic remains offline; no new permissions, dependencies, or data transmission.

## Validation

- XcodeGen completed; simulator build succeeded.
- 318 Swift Testing tests across 59 suites passed, plus grocery performance XCTest.
- Added regressions for separate-pack quantities/dates and replay, conflicting separate/restock intent, and original-pack versus new-purchase dates.
- iPhone 18 Pro (iOS 27.2): historical receipt attachment, new separate pack, and measured shopping restock UI tests passed.
- Duo (iOS 27.1): separate-pack receipt save passed; historical receipt attachment and unchanged pantry quantity passed on the final rerun.
- Initial Duo UI runs failed because app-relative test swipes did not scroll the foreground list on its active display. The test helper now uses element-routed collection gestures for Receipt and Groceries at home. The app does not contain simulator-specific gesture workarounds.
- Final iPhone rerun with the updated gesture helper passed both receipt tests (`/tmp/namillam-purchase-iphone-final.log`).

Evidence: `/tmp/namillam-purchase-review-validation.log`, `/tmp/namillam-purchase-duo-retest.log`, `/tmp/namillam-purchase-duo-final.log`. Saved iPhone review screenshot: `iphone-separate-pack.png`. Duo XCTest screenshots target an inactive display and are black, so they are not retained as visual evidence.

This change has not been uploaded; installed TestFlight build 74 does not contain it.
