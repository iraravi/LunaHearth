# Purchase form redesign

The prior change clarified behavior but kept a long inline form. This pass changes the information architecture:

- Receipt overview: compact purchase summary, item list and optional receipt tools.
- Purchase details: store, amount, currency and date in a dedicated sheet.
- Each item opens a focused editor. Pantry choices are mutually exclusive cards: existing pack, separate pack, or purchase only. Selection has a checkmark and text, not color alone.
- Existing-purchase matching remains explicit; history is collapsed.
- Final save follows the selected pantry actions; no competing save action silently overrides them.
- Shopping completion uses a bounded content width and a compact item header with an orange icon.

Entities remain ReceiptLine, InventoryItem, PurchaseEntry and HouseholdExpense. This is native SwiftUI presentation only; no schema, synchronization, permissions, networking or dependencies changed. Offline behavior and the existing repository validation remain intact.

Validation:
- XcodeGen and simulator build succeeded.
- All 318 unit tests passed. Final iPhone UI tests passed for exact expense total with pantry selection (dark), historical receipt attachment without restocking, and separate-pack purchase. Log: `/tmp/receipt-design-final.log`. Duo separate-pack editor and save flow passed (`/tmp/receipt-redesign-duo.log`).
- Interaction checks found and fixed empty-space row taps and automatic expense-field opening left over from the former inline form.
- Scans now land on the overview. The entire purchase/item row is tappable.
- The amount field keeps its label when populated.
- Dark overview screenshot: receipt-overview-dark.png.

Not uploaded to TestFlight.
