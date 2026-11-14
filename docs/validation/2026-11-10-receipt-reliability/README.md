# Receipt reliability follow-up

Scope: finish the expense-first fallback without claiming that all product OCR is solved.

- Receipt total evidence distinguishes absent, unreadable, conflicting and readable amounts. Contradictory subtotals/taxes/totals cannot pass the product-list gate by falling through to another matching field. Existing printed payment corroborated by subtotal plus tax remains supported.
- An expense-only receipt can retain its compressed image with explicit opt-in. The original deterministic `purchase|receiptKey` storage key is reused, so existing saved images remain compatible.
- The saved expense exposes its receipt image even when there are no PurchaseEntry records. Viewing/removing the copy uses the existing protected local image service.
- No synthetic purchases, shopping completions or pantry stock are created to attach an image.

Affected entities: transient receipt-total evidence and receipt review state; existing HouseholdExpense receiptKey, PurchaseEntry linkage and local image sidecars. No schema migration, CloudKit mapping change, networking, permission change or external dependency. Image retention remains local-only, excluded from encrypted exports and CloudKit, and bounded by existing four-page/one-MB-per-page limits. Storage failure leaves the saved expense intact and displays a recoverable error. Saving an expense without opting in writes no image.

Validation covers total conflicts, repeated import without duplicate expenses, image save/reopen/removal without products, and light/dark UI flows. Synthetic UI fixtures exercise the fallback and retention controls; they do not prove real-device OCR accuracy. TestFlight and public release are separate steps and are not performed by this change.

Deletion lifecycle: confirmed deletion of an expense-only receipt removes its local image first, then deletes the expense. A storage failure retains the expense for retry; if expense deletion fails after image removal, the error explicitly reports that the image was removed and the expense remains. Images still linked to a purchase group are preserved. Save, duplicate delete and dismissal controls are disabled during the operation.

## Verified results

- Xcode project opened in the native Xcode app.
- `xcodegen generate` and simulator `xcodebuild build` passed.
- Final test run: **396 Swift Testing tests in 76 suites passed**, plus the existing XCTest performance check.
- Final targeted UI tests passed: expense-only image retention in light and dark modes; confirmed expense-only deletion after reopening its image.
- Existing itemized-receipt image UI test also passed in the preceding run. That run exposed an incorrect new test setup (the reopened repository needed `reload()`); corrected before the final passing run.
- Screenshots `expense-only-light.png` and `expense-only-dark.png` use synthetic test data and show the image retention control enabled without product selections.
- Final result bundle: `/tmp/solid-receipt-final.xcresult`. Final log: `/tmp/solid-receipt-final.log`.
- No TestFlight upload or public submission performed. Physical-device receipt photos are the next acceptance step; local test success does not establish OCR/model accuracy.

## Debug/main parity

Both screens use `ReceiptReconciliation.check` and `ExpenseRules.receiptTotalEvidence`. The internal report now explicitly shows missing/unreadable/conflicting/readable total evidence, conflicting printed amounts, and a main-screen preview with the number of scanned products that would actually be visible. All raw candidates remain available in a clearly labelled diagnostic section, rather than being described as final items. Main-screen image retention applies to expense-only receipts; the diagnostic lab deliberately remains read-only and never saves records or images. Release builds continue to omit the lab.

Debug/main parity validation: 398 unit tests in 76 suites passed after adding debug-report regressions for conflicting totals, accepted candidates, unknown amounts and absent/unreadable evidence. Experimental readers B/C are explicitly identified as debug comparisons, not the main-screen pipeline. The main screen's previously verified save/image flows are unchanged by this report-only follow-up.
