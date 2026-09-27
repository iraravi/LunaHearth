# In-app help and setup

The question-mark control opens a short illustrated guide for Today, Home,
Calendar, Pantry, Shopping, Receipts, Expenses, Meals and Family. Guides use bundled
artwork, readable steps and explicit explanations of review/confirmation. They
do not run the workflows they describe.

More → Help & guides contains searchable guides and common questions, the
connected receipt → expense/pantry → meal → shopping explanation, the existing
introduction replay, and the existing setup checklist. This replaces the separate
How it works row in More. Preferences retains its existing setup link.

Setup progress continues to use the existing household-scoped, device-local
HomeSetupProgress preferences. Observed milestones are remembered even when the
guide itself has not been opened. Completed steps and skipped steps stay distinct.
The Home card's options menu hides it; the full guide can show it again. Hiding
does not delete progress or mark unfinished steps complete. All-reviewed checklists
remain available in Help without taking space on Home.

Affected entities: the guide reads existing inventory, groceries/purchases,
expenses, meals, planning and sync-configuration milestones. No household entity,
CloudKit mapping or database schema changes. Only a household-scoped local
"dismissed" preference is added. No new networking, permissions, analytics, AI
generation or dependencies. Help works offline; service use remains explicit.

Accessibility: native navigation, sheets, menus and disclosure controls; descriptive
VoiceOver labels; minimum 44-point help controls; Dynamic Type; single-column
accessibility layouts with decorative artwork omitted in quick guides. Content
widths are constrained on iPad. No automatic popups or motion are introduced.

Validation (September 22, 2026):
- 246 Swift Testing tests in 47 suites and the grocery search performance XCTest passed.
- Help search, guide open/close, checklist hide/restore, and the restored card's
  button accessibility role passed on iPhone 18 Pro and iPad Pro 13-inch simulators.
- Accessibility-size guide layout passed on both simulators. Introduction replay
  from Help passed on iPhone.
- iPhone and iPad screenshots were inspected; iPad guide cards now align within
  each row. See [iPad Help center](visual-review/help/help-center-ipad.png) and
  [iPhone quick guide](visual-review/help/quick-guide-iphone.png).
- Initial checks caught the collapsed search presentation and missing button
  accessibility role. Both were corrected and the affected flow rerun successfully.
- Physical device installation, manual VoiceOver operation and TestFlight upload
  are not part of this validation.
