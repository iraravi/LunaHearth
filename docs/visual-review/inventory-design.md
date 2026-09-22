# Home grocery inventory

The new inventory uses soft peach/coral surfaces, adaptive dark colors, and ingredient photography. Shopping keeps its existing green palette. The primary entry point is Home → Groceries at home; Shopping also has an Inventory shortcut. Only the item name is required.

## Artwork

Generated using the built-in image-generation tool, then copied into the workspace. No runtime image-generation service was added to the app.

Asset: `LunaHearth/Resources/Assets.xcassets/PantryStillLife.imageset/PantryStillLife.png`

Final generation prompt:

Use case: stylized-concept. Asset type: premium iOS home grocery inventory hero artwork for LunaHearth. Create a refined editorial 3D still life of a well-organized South Indian pantry: elegant clear glass jars containing white rice, golden toor dal and pale urad dal, one short jar of red dried chillies, a coconut half, a few fresh curry leaves, and a small coral storage tin. Bright natural ingredient colors, sophisticated soft peach and apricot studio background, warm coral and pale terracotta accents, ivory ceramic details. Soft daylight, realistic glass, subtle shadows, clean premium Apple-like product photography composition with generous breathing room. Landscape 3:2, centered compact arrangement, no shelves, no text, no labels, no logos, no people. Avoid brown overall tint, rustic wood, grocery baskets, clutter, dark background, and UI mockup elements.

## Interaction

Shopping → finish item → Add to home inventory or Bought without adding. Inventory → Use up → Add to shopping. Pantry ideas begin with no items selected; people select what they already have, then confirm Add. On-device AI can tailor the starter list, with a clearly labeled fallback.

## Verified 2026-09-13

Simulator build and 102 unit tests passed, including inventory persistence, purchase choices, repeated purchases, separate packs, date validation, schema-table addition, and simulated shared sync/tombstones. Four UI flows passed: name-only entry and South Indian selection; home versus friends purchases and restocking; personal-shopping completion; dark mode with accessibility text sizes and optional dates. Screenshots 62–66 were inspected. Real Foundation Models generation and live two-account CloudKit delivery remain unverified.

- [South Indian suggestions](62-South-Indian-Pantry-Ideas.png)
- [Inventory](63-Home-Grocery-Inventory.png)
- [Purchase choices](64-Shopping-Purchase-Choice.png)
- [Large text in dark mode](65-Inventory-Large-Dark.png)
- [Optional dates in dark mode](66-Inventory-Optional-Dates-Dark.png)

Evidence: `/tmp/LunaInventoryFinal20260913.xcresult`, `/tmp/LunaInventoryFlows20260913.xcresult`, `/tmp/LunaInventoryAccessibility20260913.xcresult` (unit suite), and `/tmp/LunaInventoryDatesFinal20260913.xcresult` (final dark-mode UI pass). Earlier failed UI attempts in these bundles were resolved and rerun.

## Ingredient duplicate review

ADR-018 adds an inline already-at-home warning, a separate-pack confirmation, optional on-device name comparison and a review screen for existing matching entries. Cumin/jeera aliases are filtered from starter ideas and pending shopping. Existing pack data remains intact until a user confirms removal of a specific extra entry.

Validation on 2026-09-13: simulator build, all 107 unit tests and the full duplicate-warning/separate-pack/removal UI flow passed. Screenshots [67](67-Ingredient-Duplicate-Warning.png) and [68](68-Ingredient-Duplicate-Review.png) were inspected. Evidence: `/tmp/LunaIngredientDuplicates20260913.xcresult`. Live Foundation Models semantic comparison remains unverified; the UI test exercises the explicit offline fallback.

## Visual pantry shelves

ADR-019 makes category shelves the default populated inventory view, with colorful system emoji illustrations, individual pack cards, a smaller header, category chips and a List switch. Each card opens the existing editor. Amount and expiry remain explicit; unknown values are labeled. Optional on-device AI suggests presentation-only categories for unfamiliar names and can be reset. No new image-generation service or generated pack photos are used.

Visual shelves validation: all 109 unit tests passed in `/tmp/LunaVisualPantrySplit20260913.xcresult`; final icon classification tests passed in `/tmp/LunaVisualPantryFinal20260913.xcresult`. The complete UI flow passed in `/tmp/LunaVisualPantryButtons20260913.xcresult` after fixing shared header-button activation. Inspected [shelves](69-Visual-Pantry-Shelves.png) and [overview](70-Visual-Pantry-Overview.png). Signed Release build succeeded and was installed directly on Ravi's iPhone. Real Foundation Models category quality remains unverified.
