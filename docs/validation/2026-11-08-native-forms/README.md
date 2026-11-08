# Native forms redesign

Branch: codex/friendly-forms-redesign

## Scope

SwiftUI-only presentation changes to Meals, feature illustrations, expense entry, receipt review, connected-calendar choices, and Today household summary. Domain entities and storage are unchanged. No new networking, permissions, dependency, or schema migration. 21st MCP was used only for development-time design reference metadata.

- Warm red/orange SF Symbol feature tiles, with appearance-aware foreground contrast.
- Meals uses swipeable native suggestion cards, with two columns on regular-width screens and one at accessibility text sizes. Real ingredient availability and review-before-save remain intact.
- Optional expense notes/refund controls expand automatically when editing a record that uses them.
- Calendar choices can be collapsed and searched by title/account. Existing privacy choices remain unchanged.
- Today separates My day and Family, with expandable aggregate overview. Explicit Summarize opens that overview.
- Receipt image and raw-text details follow item review. Image retention remains opt-in.

## Validation

- XcodeGen completed.
- Simulator build succeeded.
- Unit suite: 315 Swift Testing tests across 59 suites passed; performance XCTest passed.
- UI: expense saved-store selection and real-pantry meal planning through cooking/pantry update passed.
- First calendar UI run found a DisclosureGroup identifier overriding child identifiers. Removed the group identifier and retained individual calendar identifiers; rerun passed on the final source revision.

## Remaining review

This is a first native simplification pass, not a claim that every app form has been redesigned. Full Duo, accessibility-size, dark/light visual review and broader receipt UI regression remain before release. No App Store or TestFlight upload was performed.
