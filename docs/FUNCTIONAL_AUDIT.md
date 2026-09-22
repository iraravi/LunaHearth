# Connected household functional audit — build 46

Scope: shopping completion, pantry restocking/counts, receipt import, linked purchase history, expenses/monthly reports, meal ingredient shopping and measured consumption.

## Fixes
- Compatible restock amounts now add (200 g + 1 kg = 1200 g), with review text showing the resulting amount. Matching package counts add without inferring their weight/volume. Unknown/incompatible quantities remain unchanged with a visible explanation.
- Large expense amounts retain all digits when formatted for editing/export.
- New purchases do not merge into expired packs. Old stock remains visible as expired, while the new pack has its own quantity and reviewed expiry.

## Connection contract
| Action | Pantry | Shopping | Expenses/history |
| --- | --- | --- | --- |
| Bought, restock existing | Add known compatible quantity; clear Low stock | Mark bought | Add purchase history; price remains unset |
| Bought, separate pack | Add distinct pack | Mark bought | Add purchase history |
| Bought, kept elsewhere | Unchanged | Mark bought | Add purchase history |
| Reviewed receipt | Add new pack or restock selected match | Complete matched pending item | Reviewed total creates linked expense and line history atomically |
| Attach expense to existing purchase | Unchanged | Unchanged | Add one linked expense |
| Review weekly ingredients | Unchanged | Add selected unmet ingredients, skip already listed aliases | Unchanged |
| Finish meal with measured use | Subtract reviewed compatible amount once | Unchanged | Expense/history unchanged; complete linked prep tasks |

## Practical limits
- Shopping alone has no total and cannot create a reliable expense. Add it from Purchase history or import the receipt before marking items bought.
- Receipt fingerprints prevent exact replay, not recognition of every differently scanned receipt. If a purchase was already marked bought, use the recorded-purchase option during receipt review, or attach its expense from Purchase history. Build 47 adds automatic recent-purchase detection with explicit link/new-purchase review. Linking does not repeat stock actions; see ADR 040.
- Unknown quantities are not zero; separate packs may be needed for different dates or sizes.
- Receipt line amounts are optional reviewed item totals; tax/discounts belong to the receipt expense total. They need not sum to the receipt total.
- Monthly reports separate currencies; there is no inferred conversion. Refunds/expense deletion do not undo physical inventory.
- Local/simulator validation does not prove live CloudKit delivery, simultaneous offline conflict handling, physical camera quality or on-device generative accuracy.

Validation results are recorded in TESTFLIGHT_RELEASE.md after execution.

## Component test plan
| Component | Automated checks | Remaining device check |
| --- | --- | --- |
| Pantry transfer | Measured-unit conversion, same-package counts, unknown amounts, duplicate choice, repeat completion | Owner purchase appears once on participant with the same amount |
| Receipt | OCR rendered image, item review, invalid-row rollback, exact replay, line/expense/history links | Real Costco/Indian-store receipt and user corrections |
| Expenses | Exact minor units, large amounts, month/year boundaries, currencies/refunds, dashboard navigation | Review familiar receipt total in the correct month/currency |
| Meals | Missing ingredients deduplicate against shopping; cooking subtraction and replay guards | Confirm user-reviewed portions match actual cooking |
| Persistence | Entire linked cycle survives disk reopen and backup restore | Offline edits followed by reconnect on both devices |
| Alerts | Existing assignment/prep notification domain tests | Purchased item no longer appears as pending; actual banner delivery/removal |

Use a clearly named temporary test household for live scenarios. Do not clear production household data. For cross-device testing, perform one purchase on the owner, wait for sync, check the participant quantity, then reopen/finish the same shopping item and verify that the balance does not increase again. Independently add a second shopping purchase and verify a second increase. Concurrent offline edits require separate conflict/reconciliation review and must not be counted as validated by the sequential test.
