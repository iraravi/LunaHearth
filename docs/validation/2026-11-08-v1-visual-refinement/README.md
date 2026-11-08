# V1-inspired visual refinement

User requested returning to the preferred version-one design after reviewing build 75. Baseline: git tag `v1.0.0`, especially ADR 047 and the shared AppTheme. Work is isolated on `codex/v1-visual-refinement`.

## Presentation

Restore regular native serif editorial headings, with native sans-serif body text, actions and amounts. Replace uniform red/orange gradient badges with medium-weight SF Symbols on neutral rounded surfaces. Category accents remain restrained: vermilion for Shopping/Meals, coral for Pantry and household tasks, plum for spending/documents, slate blue for calendar/security. Increased Contrast uses the primary ink for symbols. Labels remain visible and decorative symbols are hidden from VoiceOver.

Compact Home uses smaller, consistently left-aligned icons and neutral card outlines. Shared icon styling also applies to Today, expanded Home, Meals and More. Light and dark backgrounds remain unified across features. Existing explicit On/Off switch labels and build 75 receipt/pantry forms are preserved.

## Domain and privacy

Presentation only: no entities, data migration, permissions, sync, AI, network access, or runtime dependencies changed. All assets are bundled Apple symbols and existing semantic colors. This does not revert version-two functionality or change the live App Store release.

## Validation

XcodeGen and iPhone simulator build passed. The full unit suite passed (318 Swift Testing tests across 59 suites plus the XCTest performance check). Home navigation in light/dark appearances and Today navigation at accessibility text size passed. Expanded contrast checks cover all four category accents on canvas, surface and secondary surface (3:1 for symbols; 4.5:1 for text). After the final vermilion adjustment, contrast and both Home appearance checks passed again. Screenshots `home-light.png` and `home-dark.png` were exported from that final run and visually reviewed.

Final phone result: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_11-20-07--0600.xcresult`. Expanded Duo Home navigation passed in light and dark appearances, including opening receipt scanning and Pantry. Result: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_11-21-47--0600.xcresult`.

Initial result: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_11-17-45--0600.xcresult`.

## Follow-up: sans-serif and neutral icons

The user rejected the serif font and red icons after this preview. Shared display/section headings now use Apple's native default sans-serif in bold, retaining Dynamic Type and native body typography. No Uber font or third-party font asset is bundled. Feature icons and summary symbols now use adaptive primary ink (dark in light mode, white in dark mode) on neutral surfaces; removed the category-color mapping from these components. Error/destructive state colors are not changed. The earlier screenshots above describe the superseded visual direction.

Validation for this follow-up: XcodeGen, build, contrast tests and Home navigation in light/dark appearances passed. Result: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_11-38-52--0600.xcresult`. Updated previews: `sans-home-light.png`, `sans-home-dark.png`.
