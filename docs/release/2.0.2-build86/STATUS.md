# 2.0.2 (86) — bug-scan fixes

Changes since 85 (see docs/review/2026-11-13-bug-scan.md):
1. Item-code receipt rule only activates on code-led rows ending in a price, and cuts only at a summary row after the first product — "TAX INVOICE" headers, store names starting with TOTAL, street addresses and PIN codes no longer remove all items.
2. Header store-name suggestions must start their row ("TOTAL WINE & MORE" no longer suggests "More").
3. iCloud sharing uses a sync snapshot that leaves document files and room scans on the device instead of refusing to sync.
4. Deleting an expense (single or Cleanup → Expenses) unlinks its purchases so a later receipt can be attached without restocking.
5. Receipt screen restores scanned item prices when "Record in Expenses" is turned back on.
6. Pantry-only receipt imports use the receipt date when read.

Includes everything in 85. No network AI, schema change or data migration.

Validation: 414 unit tests / 78 suites passed (7 new in BugScanRegressionTests); Release configuration builds; UI tests passed: receipt review/import, explicit inventory choice, bought-item linking, expense dashboard, expense-only receipt deletion, saved shopping stores. Internal device archive succeeded: /tmp/build86-archive.log, /tmp/NamIllam-2.0.2-Build86.xcarchive. Real-device testing pending.

Distribution: Xcode Organizer → Distribute App → TestFlight Internal Only; Xcode confirmed "LunaHearth 2.0.2 (86) uploaded" on November 13, 2026. App Store Connect showed 2.0.2 (86) Ready to Test (uploaded 12:02 PM); it was added to the Developer Receipt Debug internal group (a3280c67-8135-47f7-9d48-3e5bd050f84b), which now lists 5 builds with 2.0.2 (86) Testing. No other groups changed. No public App Review submission.
