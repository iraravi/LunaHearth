# 2.0.2 (84) — receipt itemization gate and reader experiments

Changes:
- Public receipt flow is expense-first. Scanned items are listed only when their amounts reproduce the printed subtotal (and subtotal + tax = total when readable); otherwise the list is hidden and the expense can still be saved. Same-line prices (`MILK 4.00`) are kept as proposals on the production scan path.
- Internal Receipt debug screen (RECEIPT_DEBUG only) compares three readers on the same photos: current pipeline, Vision document recognition (iOS 26+, language correction off) and Apple's on-device model reading the image (iOS 27+ with vision capability). Each is checked against OCR-printed totals.
- UI tests confirm the purchase date before saving; scroll helper fixed for landscape.

No network AI, schema change or data migration.

Validation: 385 unit tests / 74 suites passed on the iPhone 18 Pro Max simulator; 15 receipt and pantry UI tests passed (including landscape); public Release configuration builds. Internal device archive succeeded: /tmp/build84-archive.log, archive /tmp/NamIllam-2.0.2-Build84.xcarchive. Device accuracy of OCR, document recognition and the image model is untested.

Distribution: command-line upload failed ("exportArchive Failed to Use Accounts"); archive opened in Xcode Organizer for manual Distribute App → TestFlight Internal Only. Not yet confirmed uploaded. Target group: Developer Receipt Debug. No public App Review submission.
