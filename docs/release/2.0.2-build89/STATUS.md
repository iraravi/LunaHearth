# 2.0.2 (89) — Receipt name layout

Changes since 88:
1. Receipt name choice layout: "On bill" and the suggested name sit in aligned columns; Accept (Accept AI when AI suggested it) and Keep bill are equal-width buttons with no off-center icons.
2. Long receipt item titles are left-aligned instead of centered.

Includes everything in 88. No schema change or data migration.

Validation: 430 unit tests / 82 suites passed; UI tests passed: bill name beside decoded name, receipt review and import. Internal device archive: /tmp/NamIllam-2.0.2-Build89.xcarchive. Real-device testing pending.

Distribution: Xcode Organizer → Distribute App → TestFlight Internal Only; Xcode confirmed "LunaHearth 2.0.2 (89) uploaded" on November 18, 2026. App Store Connect showed 2.0.2 (89) Ready to Test (uploaded 3:56 PM); it was added to the Developer Receipt Debug internal group (a3280c67-8135-47f7-9d48-3e5bd050f84b), which now lists 8 builds with 2.0.2 (89) Testing. No other groups changed. No public App Review submission.
