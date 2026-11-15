# 2.0.2 (87) — Buy again

Changes since 86:
1. Buy again: Groceries suggests items the household usually rebuys by now, from checked-off shopping and saved receipt lines (at least 3 purchase days, median gap 2–90 days, hidden once 3 gaps overdue, skipped when already on the list). "Add to list" uses the usual quantity and store; "Not now" hides it on this device until it is next due.
2. Today → Restock lists due Buy again items below items marked low, with "Add to shopping".
3. Remote feature switch `buyAgain`.

Includes everything in 86. On-device arithmetic only; no network AI, schema change or data migration.

Validation: 425 unit tests / 80 suites passed (11 new in RepeatPurchaseTests); UI tests passed: Buy again adds a usual purchase to the list, measured shopping restock. Internal device archive succeeded: /tmp/build87-archive.log, /tmp/NamIllam-2.0.2-Build87.xcarchive. Today Restock panel not checked on screen; real-device testing pending.

Distribution: Xcode Organizer → Distribute App → TestFlight Internal Only; Xcode confirmed "LunaHearth 2.0.2 (87) uploaded" on November 15, 2026. App Store Connect showed 2.0.2 (87) Ready to Test (uploaded 4:05 PM); it was added to the Developer Receipt Debug internal group (a3280c67-8135-47f7-9d48-3e5bd050f84b), which now lists 6 builds with 2.0.2 (87) Testing. No other groups changed. No public App Review submission.
