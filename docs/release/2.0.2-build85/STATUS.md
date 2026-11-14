# 2.0.2 (85) — store-free, multi-country receipt reading

Changes since 84:
- No store-specific receipt code. The former Costco parser is `ItemCodeReceiptDetails`, detected from item-code rows and code-referenced discount rows. Store-name suggestions use the offline catalog plus the household's saved store names.
- `ReceiptVocabulary` word lists for subtotal/total/tax/discount/payment labels in English, Indian bills, German, French, Spanish, Italian, Dutch and Nordic receipts.
- Tax-inclusive receipts (GST/VAT) can verify: items may match the subtotal or the total.
- Qty/Rate/Amount and weighed-goods columns accepted only when quantity × rate equals the line amount; count × unit-price rows and discounts in any currency; decimal-comma and Indian grouping amounts.
- Expense currencies widened from 6 to 25 two-decimal currencies.

Includes everything in 84 (itemization gate, receipt debug reader comparison, UI test fixes). No network AI, schema change or data migration.

Validation: 407 unit tests / 77 suites passed (iPhone 18 Pro Max simulator); receipt UI tests (review/import, explicit inventory, image dark mode) passed; Release configuration builds. Internal device archive succeeded: /tmp/build85-archive.log, /tmp/NamIllam-2.0.2-Build85.xcarchive. Country fixtures are synthetic; real-device OCR and real-receipt coverage untested.

Distribution: Organizer → Distribute App → TestFlight Internal Only. The first attempt stopped at "App Store Connect access for 'Vasanthi D' is required" (no Xcode account signed in); after the account holder signed in, Xcode Organizer shows 2.0.2 (85) "Uploaded to Apple", November 11, 2026 9:50 AM. App Store Connect showed 2.0.2 (85) Ready to Test (uploaded 9:51 AM); it was added to the Developer Receipt Debug internal group (a3280c67-8135-47f7-9d48-3e5bd050f84b), which now lists 4 builds with 2.0.2 (85) Testing. Group testers: ravi.dorairaj@icloud.com (had 2.0.2 (84) installed at the time) and vasanthi.dorairaj@icloud.com (status Invited). No other groups changed. No public App Review submission.

Note: Organizer also shows 2.0.2 (84) as "Uploaded to Apple".
