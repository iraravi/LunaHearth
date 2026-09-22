# ADR-028: Reviewed on-device receipt photo import

Status: Accepted for implementation; real customer receipts and live two-device delivery remain device checks.

## Workflow

Shopping and pantry toolbars expose Scan receipt. Choose up to four photos of one receipt with PhotosPicker, or use Apple's document camera when supported. Vision OCR runs in a service actor on the device, with orientation correction and bounded image decoding. No generative model or server is required. Core manual entry and pantry templates remain available offline.

The review is a proposal. Users can edit names and quantities, exclude lines, add missed items, link a pending shopping item, and opt out of home inventory for gifts/elsewhere. Linking an abbreviated line to a shopping item uses that item's canonical name. Unique ingredient-alias matches are suggested automatically; ambiguous saved packs require a choice. Totals, tax, payment and negative refund/discount lines are excluded. The conservative parser proposes priced product lines and explicit `N x` quantities only; prices never become quantities. Repeated ingredient lines are grouped, summing only explicit piece counts. Unclear quantities stay unset. OCR may miss or misread products: the original recognized text remains available during review.

Confirm applies a single local transaction. Existing matched shopping items become bought and preserve their assignment; unmatched items become bought shopping history. Existing inventory clears Low stock while preserving its free-text amount, dates and provenance. New ingredients copy confirmed quantity and optional store; purchase date is today and expiry is unknown. This release does not infer numeric remaining stock or automatically add to an existing free-text quantity. Stale references, duplicate review names and read-only/recovery households reject the save without partial writes.

## Records and privacy

Affected entities: GroceryItem, InventoryItem, ShoppingStore. GroceryItem adds an optional `receiptImportKey` with a nil default; the existing grocery backup/sync payload includes and validates it. This is additive migration and does not change record types or CloudKit schema. Older payloads decode with nil. Household devices should update together because older clients do not preserve the new optional marker when rewriting a grocery record.

A SHA-256 key of normalized complete OCR text and source line position identifies an import line. New bought grocery IDs derive deterministically from household ID and that key. Reimporting identical recognized text skips previously imported lines, including after backup/sync; partial selections can be imported later. Existing matched shopping rows retain their stable IDs and receive the marker. Previously imported history rows cannot be reused for a different receipt. Changed OCR, different page order, or deleted purchase history can defeat repeat detection: this is not a globally unique receipt identity, and review remains required. No raw text, payment details, receipt image or image file is retained in SwiftData, logs or CloudKit. Only reviewed household item data and the opaque import marker use the existing optional private/shared transport.

PhotosPicker grants selected-image access only. Camera permission occurs only when the user opens document scanning. Existing usage descriptions cover receipts. At most four pages, 20 MB per image, 2600-pixel OCR thumbnails, 40,000 text characters and 150 proposed rows are processed. Readable text with no item candidates has a recovery flow; scan errors keep any previous review, cancellation saves nothing, and switching households dismisses the review.

## Verification

Unit tests exercise priced-line parsing, payment exclusion, explicit quantity handling, repeated ingredients, actual Vision OCR on a rendered receipt image, atomic shopping/inventory updates, unchanged existing pack amounts, alias reuse, backup/replay, excluded/elsewhere purchases, stale references, duplicate names and read-only rejection. UI tests use a deterministic receipt-text fixture to verify the review and confirmation on iPhone/iPad; this is separate from the image OCR test. Real crumpled/long/multilingual retailer receipts, camera permission and two-device delivery must not be claimed verified by these tests.

### On-device name proposals (build 26)
User requested generative decoding of abbreviated receipt items. Add a domain decoding protocol and a Foundation Models adapter, with transient, individually accepted name proposals. No schema or networking change. Existing validated receipt import remains the only write path; AI does not infer quantities, money, dates or purchase actions. See AI_ON_DEVICE.md for availability, privacy and cancellation behavior.
