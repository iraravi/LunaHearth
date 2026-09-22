# Shopping shelves and inventory attention

Shopping keeps its sage palette and gains store-grouped food-icon cards, category filtering, a List switch, optional on-device category hints and a fresh header illustration. Inventory uses adaptive red/amber badges with text and icons for recorded expiry dates and an explicit user-reported Running low flag. See ADR-020 for data scope and limits.

## Artwork

Generated with the built-in image-generation tool and copied into the workspace at `LunaHearth/Resources/Assets.xcassets/ShoppingShelvesFresh.imageset/ShoppingShelvesFresh.png`. No runtime image-generation call was added.

Exact prompt:

Use case: stylized-concept. Create a premium editorial 3D still life for a professional iOS family grocery shopping screen. Bright ripe red tomatoes, a lemon, green leafy vegetables, a small glass bottle of milk, a pale reusable mesh produce bag and a small jar of golden lentils, arranged elegantly on a clean pale sage and mint studio surface. Sophisticated soft daylight, realistic textures, colorful food, restrained composition with generous breathing room. Landscape 3:2 crop. No shopping basket, no trolley, no brown overall cast, no dark backdrop, no people, no text, no brand labels, no logos, no interface. Fresh, friendly and refined. Keep the food centered so the illustration works in a rounded rectangular header thumbnail.

## Validation — 2026-09-13

All 112 unit tests passed (`/tmp/LunaStockAndShopping20260913.xcresult`), including new household isolation/legacy-stock-field/expiry tests and the extended fake-server sync test. Inventory expiry and low-stock editing UI passed in `/tmp/LunaStockShoppingUI20260913.xcresult`; shopping shelves/list switching, AI fallback and purchase-to-inventory passed in `/tmp/LunaShoppingShelvesVisible20260913.xcresult`; dark low-stock UI passed in `/tmp/LunaLowStockDark20260913.xcresult`. Earlier shopping tap verification was rerun with the card fully visible above the bottom toolbar.

Screenshots inspected: [expiry colors](71-Inventory-Expiry-Colors.png), [shopping artwork/header](72-Shopping-Shelves-Header.png), [shopping cards](73-Shopping-Shelves-Cards.png), [dark low-stock status](74-Low-Stock-Dark.png). Signed Release build succeeded. Live two-account iCloud delivery and real Foundation Models output quality remain unverified.

## Shopping duplicate comparison

Shopping entry now includes the inventory-style offline alias/typo warning and optional on-device AI name comparison. Keep existing cancels the new entry; Keep a separate entry explicitly permits another purchase. Review similar items shows existing pending aliases with buyer/store/quantity/timing before confirmed removal. Existing inventory is preserved.

Shopping duplicate validation: simulator build and all 113 unit tests passed; the full alias warning, unavailable-AI fallback, separate-purchase confirmation, extra-entry removal, typo warning and powder distinction UI flow passed in `/tmp/LunaShoppingDuplicateAIFinal20260913.xcresult`. Inspected [comparison](75-Shopping-Duplicate-AI.png) and [existing duplicate review](76-Shopping-Duplicate-Review.png). Real device model output quality remains unverified.

## Shopping → existing inventory fix

Transfer now requires a keep-existing/separate-pack choice when an active ingredient alias is already at home. Keep existing completes the purchase without changing quantity/dates or creating another entry; separate packs require explicit intent. All 114 unit tests and the Milk shopping-to-existing-inventory UI flow passed in `/tmp/LunaPurchaseInventoryMatch20260913.xcresult`. Screenshot [77](77-Shopping-Existing-Inventory.png) was inspected. New inventory creation, invalid match rejection, preserved metadata, reopen/retry and explicit second-pack paths are covered by unit tests. No schema or cloud mapping change.

## One existing-item action and cleanup

Multiple matching inventory packs now produce one Use existing action. Its picker shows each saved pack's details and allows confirmed removal of an accidental duplicate before selecting the entry to keep. No existing pack is removed automatically.

All 114 unit tests passed in `/tmp/LunaOneMilkAction20260913.xcresult`. The final two-pack cleanup UI flow passed in `/tmp/LunaOneMilkCleanup20260913.xcresult`, checking one initial action, confirmed removal, selection of the remaining pack and shopping completion. An earlier UI assertion expecting automatic selection after removal was replaced with explicit user selection. Inspected [single action](78-One-Existing-Milk-Action.png) and [saved-pack picker](79-Existing-Milk-Cleanup.png). Signed Release build succeeded and was installed and launched on Ravi's iPhone.

## Category control parity

Shopping and inventory share category chips/counts, Similar items + List/Shelves actions, and consistent AI organization/reset controls. Reset clears hints and returns to All without changing stored records. Counts follow the other screen-specific filters; zero-count selected categories remain visible.

All 115 unit tests and the UI flow passed in `/tmp/LunaCategoryParity20260913.xcresult`. The strengthened reset assertion (All selected without tapping it) passed for both screens in `/tmp/LunaCategoryResetFinal20260913.xcresult`. Inspected [shopping](80-Shopping-Category-Controls.png) and [inventory](81-Inventory-Category-Controls.png) screenshots. AI results in this UI test are synthetic DEBUG-only fixtures; real model quality is not validated. Signed Release build installed and launched on Ravi's iPhone.

## Always-visible AI actions

Organize and Reset now remain visible with explicit availability copy, including lists containing only known names. All 115 unit tests plus known-item visibility and category/reset UI flows passed in `/tmp/LunaAIVisible20260913.xcresult`. Inspected [shopping controls with no AI hints](82-Shopping-AI-Always-Visible.png). Reset testing uses synthetic on-device-service results in DEBUG only. Release built successfully and was installed and launched on Ravi's iPhone.

## Content-first shopping layout

The populated shopping header is now a compact summary with a small decorative thumbnail. Category chips stay on the main screen alongside Filters & AI, Ideas and List/Shelves. A scrollable native Filters & AI sheet contains timing, buyer, bought visibility, filter reset, AI organization/reset and duplicate review. Active filter count remains visible on its entry button. The duplicate bottom Add bar is removed; the labeled accessible Add toolbar action remains.

Accessibility text sizes omit decorative header content and stack action labels, preserving readable text rather than squeezing it. Cards use the existing adaptive grid, widening at accessibility sizes. The sheet uses native iPad presentation. This is GroceryItem presentation only: no data-model, offline behavior, AI processing or CloudKit changes.

Validation: 115 unit tests and standard/large-text iPhone flows passed in `/tmp/LunaCompactPhone20260913.xcresult`. Standard/large-text iPad flows passed in `/tmp/LunaCompactPad20260913.xcresult`. Screenshot review caught squeezed iPhone action labels; these now stack at accessibility sizes. Final category/reset flow passed in `/tmp/LunaCompactFinalPhone20260913.xcresult`. After explicitly propagating Dynamic Type into the tools sheet, final accessibility flows passed on both iPhone and iPad in `/tmp/LunaCompactAccessible20260913.xcresult`. Inspected standard iPhone/iPad and corrected accessibility screenshots (84–87, with iPad suffixes). VoiceOver speech order, landscape and resized iPad windows were not manually verified. Signed Release installed and launched on Ravi's iPhone.

## Organization status redesign

Filters & AI uses separate sage cards with explicit timing/buyer labels, a bought-items toggle, and a category-status card. Known-only lists use an enabled Check categories action with deterministic feedback and no model call. Unfamiliar names use Organize with AI. Reset is shown only when it can undo hints or cancel a request. This supersedes the disabled controls shown in earlier screenshots.

All 115 unit tests, known-item check feedback, synthetic AI suggestion/reset, and iPhone accessibility flows passed in `/tmp/LunaOrganizeRedesign20260913.xcresult`. iPad accessibility flow passed in `/tmp/LunaOrganizeRedesignPad20260913.xcresult`. Screenshot review prompted explicit picker captions and white primary-button text. Actual device model availability/output remains unverified. No schema or sync changes.

Final known-item feedback UI rerun passed in `/tmp/LunaOrganizeFinal20260913.xcresult`. Inspected [redesigned status panel](88-Shopping-Organization-Status.png), including labeled filters and primary-button contrast. Final signed Release installed and launched directly on Ravi's iPhone.

## Inventory and shopping layout alignment

Both screens now use GroceryShelfActions for the same Filters & AI / Ideas / List-Shelves action order and Dynamic Type layout. Inventory adopts the same compact 64-point artwork summary and category chips; its former large ideas card, inline AI status, and status segments are replaced by the same themed scrollable tools sheet structure. Inventory-specific status and date/low-stock summary controls live in that sheet, while item cards retain expiry/low-stock badges. Color palettes and domain-specific filters remain distinct. No item, persistence, AI or CloudKit semantics change.

Validation: all 115 unit tests plus standard/large-text layout parity and synthetic category/reset flows passed in `/tmp/LunaMatchingShelves20260913.xcresult`. Inspected inventory standard/large-text screenshots in the 89 series. Final signed Release build installed and launched on Ravi's iPhone.

The matching-screen accessibility flow also passed on iPad in `/tmp/LunaMatchingShelvesPad20260913.xcresult`.

## Larger shared header artwork

Shopping and inventory now reuse GroceryShelfHeader: a full-height 136×124-point artwork panel on compact layouts (220 points wide on regular layouts) replaces the 64-point inset thumbnail. Text remains alongside the image in a single rounded card; accessibility text omits decorative artwork and retains the readable summary. Existing bundled artwork is reused, with no image generation, networking or data changes.

Validation: 115 unit tests and standard/large-text matching-screen flows passed in `/tmp/LunaLargerHeader20260913.xcresult`; the standard iPad flow passed in `/tmp/LunaLargerHeaderPad20260913.xcresult`. Inspected [shopping](90-Shopping-Larger-Artwork.png) and [inventory](91-Inventory-Larger-Artwork.png) iPhone screenshots. Signed generic iOS Release build succeeded. Ravi's iPhone was unavailable, so this revision has not been installed on the physical device.

## UI polish audit

Shared action controls use explicit spacing; both adaptive grids align cards at the top; header artwork fades gently into the surrounding card. Dark-mode audit found shopping's fixed pale hero was using adaptive light text, and AI primary buttons used white text on pale dark-mode accents. Hero text now uses its dedicated dark ink; AI button text uses the theme's surface color for contrast in both appearances. No behavioral, data, AI or sync changes.

Polish validation: iPhone large-text flow passed in `/tmp/LunaCleanUIPhone20260913.xcresult`; final dark-mode checks and screenshot inspection passed in `/tmp/LunaCleanUIDarkFinal20260913.xcresult`. Initial iPad landscape interaction checks passed, but app-bounded screenshots clipped the rotated screen; the capture helper now uses XCUIScreen.main for full-screen evidence. Signed Release build succeeded. Physical installation remains pending while Ravi's iPhone is unavailable.

Final landscape interaction test passed in `/tmp/LunaCleanUIFullLandscape20260913.xcresult`; full-screen shopping/inventory landscape captures were inspected and saved in the 92 series, replacing the clipped captures. Dark-mode screens/tools are in the 92/93 series. Manual VoiceOver speech navigation and arbitrary iPad window resizing remain unverified.
