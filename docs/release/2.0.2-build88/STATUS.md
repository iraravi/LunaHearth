# 2.0.2 (88) — Receipt item names

Changes since 87:
1. Offline receipt name decoding: common printed abbreviations are expanded right after a scan (NICHOLS RSTD NO-SALT PIST F → Nichols Roasted No-Salt Pistachios). Leading line numbers and trailing register flags (F, T, N, X, O, S) are dropped; unknown brand words are kept as printed.
2. On-device AI name decoding now runs automatically after a scan when the phone supports Apple Intelligence; its names replace offline ones.
3. Each receipt item shows "On bill" beside "AI says" / "Decoded" / "Your saved item", with Accept AI name (or Use this name) and Keep bill name. "Use N suggested names" accepts all at once.
4. Decoded names also help match receipt lines to the shopping list and pantry.

Includes everything in 87. No schema change or data migration.

Validation: 430 unit tests / 82 suites passed. UI tests passed: bill name beside decoded name, receipt review and import, mutton matching, link bought item. Internal device archive succeeded: /tmp/build88-archive.log, /tmp/NamIllam-2.0.2-Build88.xcarchive. AI decoding not exercised (simulator disables model generation); real-device testing pending.

Distribution: Xcode Organizer → Distribute App → TestFlight Internal Only; Xcode confirmed "LunaHearth 2.0.2 (88) uploaded" on November 18, 2026. Command-line export failed first (Xcode account needs re-sign-in for CLI). After the user signed in to App Store Connect again, 2.0.2 (88) showed Ready to Test (uploaded 2:29 PM) and was added to the Developer Receipt Debug internal group (a3280c67-8135-47f7-9d48-3e5bd050f84b), which now lists 7 builds with 2.0.2 (88) Testing. No other groups changed. No public App Review submission.
