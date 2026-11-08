# Costco receipt parsing correction

User reported a real receipt showing item codes in names, payment AMOUNT as an item, and no detected total. Local Apple Vision recognition using the scanner's existing settings reproduced mixed `E + SKU` / `SKU` prefixes and the inverted total misread as an integer, while the currency-labeled AMOUNT line remained readable.

## Changes

- Strip tax markers before numeric item codes; exclude amount/payment approval rows from products.
- Recognize asterisk-decorated TOTAL and explicit AMOUNT: labels. Reject unmarked integer totals on dollar receipts instead of interpreting a missing decimal as a huge expense. Payment-card lines and subtotal alone remain insufficient evidence.
- Costco-only SKU enrichment counts repeated priced unit rows and applies negative SKU-linked coupon rows. Grouping is exact and bounded. Generic receipt quantities retain existing conservative behavior. Item descriptions remain printed names, not invented expanded product names.
- Ambiguous shared names across SKUs, excessive discounts and proposed item amounts exceeding the bill leave monetary allocation unset for user review.
- Review-only line amounts are cleared when importing without Expenses, preserving repository validation and pantry-only flow.

## Data and privacy

Affected domain values: transient ReceiptLine name, quantity and amount; ExpenseRules receipt total proposal. No schema, migration, permissions, CloudKit or AI changes. Vision runs locally. No receipt photo, membership/card details, or full private OCR text is committed. Tests use a sanitized product/price transcript. User review and explicit Pantry choice remain required.

## Expected reproduction

One FAIRLIFECHOC review row, 3 purchased units (not inferred container contents), three 8.00 discounts applied to three 39.99 prices: net 95.97. Expense total 95.97. No payment or coupon products. Existing saved records are not rewritten.

## Validation

XcodeGen and simulator build passed. Final suite: 324 Swift Testing tests across 60 suites plus the XCTest performance check passed. Receipt exact-total review/save UI passed in the initial run; separate-pack purchase UI passed in the final run.

Initial result: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_13-59-23--0600.xcresult`. Final result: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_14-01-58--0600.xcresult`. Actual attachment was exercised locally through Apple Vision with the scanner settings; deterministic parser tests use its sanitized product/total transcript. No claim of every Costco receipt being supported. Not uploaded to TestFlight.

## Follow-up: saved item-name matching

Compact labels can now propose a unique saved Shopping/Pantry name offline (for example FAIRLIFECHOC → Fairlife chocolate). Exact compact matching permits a small explicit abbreviation set; it does not discard brand, flavor, package size or dietary terms. It is review-only and does not broaden automatic IngredientMatching pantry identity. Shopping matching offers explicit selection; accepting a saved name enables the existing exact-name Pantry workflow. Multiple possible saved names never silently choose one. The original OCR remains in receipt text.

Saved-name suggestions are visible in the item overview and distinguished from AI suggestions in detail. Optional on-device AI remains available for other names and cannot overwrite a saved-name suggestion. No added networking, model invocation, schema or permissions. Tests cover conservative matches, ambiguity and a confirmed import preserving the family assignee while linking existing stock. Follow-up validation: XcodeGen/build, 328 Swift Testing tests in 62 suites plus the XCTest performance check, and the exact-total receipt review/save UI flow passed. Result: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_14-05-59--0600.xcresult`. Not uploaded to TestFlight.
