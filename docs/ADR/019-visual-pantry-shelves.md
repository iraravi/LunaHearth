# ADR-019: Visual pantry shelves

Status: Implemented; real-device AI category quality requires validation.

Inventory defaults to adaptive cards grouped into rice/grains, dals/beans, spices, fruit/vegetables, dairy/eggs, essentials and other. Colorful system emoji illustrate foods; category text and item names remain visible and accessible. Icons are illustrative, never photos or evidence of stock. The compact populated header reports distinct ingredients and pack count. Every card remains a separate InventoryItem pack with its entered amount, expiry status and optional location. No totals are inferred from incompatible quantity strings. Accessibility text sizes use wider cards; List remains a device-local preference.

A domain rule classifies familiar names using the shared alias matcher and bounded category vocabulary, prioritizing preparations such as oil/flour over source ingredients. Unknown names remain Other. Category chips filter existing inventory; At home, Check dates, Used up, search, editing and restock remain available. No database schema or CloudKit changes occur.

An explicit Organize unfamiliar items with AI action uses an optional on-device Foundation Models adapter behind PantryCategorizationService. Input contains only up to 40 unique unfamiliar active ingredient names, capped at 200 characters each, with transient numbered indices. Output categories and indices are validated against the allowed enum and supplied array. The model cannot change stock, dates, quantities or ownership. Category hints are presentation-only, labeled AI category, resettable and held only while this view is alive; they are not saved or synced. No AI output is used as food safety/storage advice. Failure/unavailability retains offline categories and an explicit status. Household changes clear hints and discard in-flight results. No cloud AI, telemetry, network access, new permission or external dependency is introduced.

Validation covers alias classification, preparations and unknown fallback, visual-card navigation, list switching and unavailable-AI behavior. Live on-device inference quality is outside simulator verification.

2026-09-13 icon correction: the shared shopping/inventory visual vocabulary recognizes explicit common produce plurals and water/juice. Banana and bananas use 🍌; bottled/sparkling water uses 💧. Preparation categories take precedence (banana bread 🍞, banana leaves 🥬, coconut water 💧). Item icons are constrained to their category so source ingredients do not override preparations. This is offline presentation only; GroceryItem/InventoryItem persistence, duplicate identity and CloudKit payloads are unchanged. Unknown names retain a generic category fallback. All 115 unit tests passed, including plural, modifier, preparation and whole-token regressions, in `/tmp/LunaGroceryIcons20260913.xcresult`.

2026-09-13 category-control parity: shopping and inventory now reuse the same horizontal category chips with counts and the same on-device organization/status/reset controls. Counts respect the screen's non-category filters. A selected category stays visible even at zero items, so users can see and clear it. Reset AI categories clears transient suggestions, cancels any organization request and returns category selection to All; it does not change items, quantities, dates, shopping status or stored data. Shopping retains timing/buyer/store grouping; inventory retains stock/date filters. No schema, permissions or network changes.

2026-09-13 discoverability correction: Organize unfamiliar items with AI and Reset AI categories remain visible on both shopping and inventory even when unavailable. Organize is disabled while running or when no unfamiliar active names exist. Reset is disabled until there are hints or a running request to cancel. Inline copy explains automatic categories and the absence of AI suggestions. This replaces conditional hiding, which made ordinary known-item shopping lists appear to lack the feature. No persistence or privacy changes.

2026-09-13 organization feedback correction: category status is explicit. Known-only lists expose an enabled Check categories action that returns a deterministic all-categorized result without invoking the model. Unfamiliar names expose Organize with AI with loading/failure/fallback feedback. Reset appears only for applied suggestions or an active request. This supersedes the always-visible disabled controls, which looked actionable and confused users. Shopping tools now use separate themed filter/status cards, explicit Buyer and Include bought labels, a scrollable layout, inherited Dynamic Type and a bounded iPad content width. No record schema, network, persistence or permissions changed.

2026-09-13 full screen parity: inventory adopts shopping's compact summary/action/category hierarchy and moves its status filters, date/stock summary, duplicate review and AI controls into Filters & AI. Both use the same GroceryShelfActions component, including stacked accessibility-size controls. Inventory item warning badges remain on the shelf. Themes and domain filters remain specific to each screen; stored data and AI behavior are unchanged.

2026-09-13 tools redesign: both sheets now share full-width cards, inline native
filter menus, a compact 44-point AI action, a separate similar-items row and an
About disclosure for longer explanations. New transparent decorative grocery
artwork is bundled for offline display. Filters and category hints remain local
presentation state. Empty model output reports that no new categories were
suggested. See `visual-review/grocery-tools-redesign.md` for artwork provenance
and validation.

2026-09-13 shelf actions correction: shopping cards use one explicit More menu
per item. Swipe actions and row context menus are restricted to List presentation:
SwiftUI's shared grid row accumulated card swipe actions and could resolve a
long-press menu to a neighboring item. The card menu offers one Edit, Share and
Delete action and has a 44-point minimum touch target with an item-specific
accessibility label. Editing and deletion confirmation retain the selected record
ID. Inventory cards continue to open their pack editor directly. This changes
GroceryItem presentation only; no schema, repository, CloudKit or permission changes.
