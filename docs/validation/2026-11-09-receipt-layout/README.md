# Tilted receipt rows and discount validation

The supplied mixed Costco basket exposed a gap beyond metadata keywords: raw OCR bounding-box midpoints misaligned the price column on tilted receipt text. A local reproduction confirmed prices and coupon amounts being assigned to neighboring SKU rows. Background keyboard characters and faint/overprinted amounts also affected recognition.

Changes:
- Vision observations are assembled using a median text-line slope and normalized baselines; deterministic geometry is tested independently from Vision.
- Costco product proposals stop before the subtotal/tax/total section, retaining the complete OCR text separately for expense review. Corrupted payment/tax footer labels no longer bypass keyword filtering.
- Costco coupon parsing accepts trailing tax letters (including OCR Cyrillic A), and product labels may begin with a number (e.g. 4LB ENVY).
- Item amounts must reconcile to the merchandise subtotal. A missing coupon cannot be masked by sales tax. Unverified allocations are cleared and marked for explicit review in the UI.
- AI name validation rejects suffix-only shortening such as FAIRLIFECHOC -> Chocolate. This does not establish semantic correctness for all AI suggestions; confirmation remains required.

Domain: receipt review proposals, OCR text layout and name suggestions. No persisted schema changes; amountNeedsReview is transient presentation state. No network, model dependency or permission changes. Existing saved purchases are not rewritten.

Validation: simulator build passed; 347 unit tests in 66 suites passed. Includes tilted-column cases in both directions, the nine-product/twelve-unit mixed basket, numeric product labels, tax-suffixed coupons, corrupted footer labels and tax masking a missed coupon. Clean fixture subtotal 723.19; tax 47.44; total 770.63. Clean-fixture correctness is distinct from photographic OCR accuracy.

Final verification: 349 tests across 67 suites passed, consisting of 348 retained unit tests and one temporary actual-photo integration test. The photo test ran through the iOS simulator VisionReceiptScanner, returned nine product review rows (including the recovered Dyson name), excluded the corrupted payment/tax footer entries, and marked all unreconciled amounts for review. The private image and temporary test path were not retained in the repository. Sanitized malformed-price fixtures remain in the unit suite.

Limitations: this photo still produces imperfect labels (ALB ENVY and E X801 MANDARINS) and unreadable monetary text. It is not a fully accurate automatic scan. The app retains the readable products and requests amount review rather than claiming correct financial extraction. No production data was modified. These changes are not yet uploaded to TestFlight.
