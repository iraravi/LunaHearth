# Shopping screen design

The shopping list now has its own focused SwiftUI view, with a compact illustrated
header, outstanding Now/Later counts, a shopping-ideas card, timing and buyer
filters, store sections, and a persistent Add item action. Item rows keep quantity,
buyer, timing, completion and editing accessible. Checked items can be shown again;
empty filtered lists offer a reset. Dynamic Type uses flexible stacked layouts.

Affected entity: GroceryItem, presentation only. No persistence, CloudKit schema,
permissions, AI requests, or household sharing behavior changed. List reads and
writes still use the local repository first. Artwork is bundled and works offline.

## New artwork

Built-in image generation tool; original asset, no reference image.
Saved to `LunaHearth/Resources/Assets.xcassets/ShoppingBasket.imageset/shopping-basket.png`.

Final prompt:

> Use case: stylized-concept. Asset type: premium iPhone household shopping screen header artwork. Create an original polished 3D editorial still life: a cobalt blue open grocery basket filled with vibrant red tomatoes, green leafy vegetables, yellow lemons, an orange, a clean white milk carton with no writing. A few fruits beside it. White to very pale cool blue seamless studio background, soft realistic shadows, clean refined materials, crisp elegant product rendering, colorful and fresh, no brown bags, no beige palette. Landscape 3:2 composition, whole basket centered with generous breathing room, visually simple, no text, no logos, no people, no UI, no watermark. Save as a new project artwork.

This design is included in TestFlight build 0.1.0 (2). Build 1 predates it.

## Validation

XcodeGen generation and simulator build passed. All 69 unit tests and the three
shopping UI flows passed: manual store/buyer/Now-Later entry and completion,
shopping-ideas review/fallback, and dark/large-text form. The final compact header
was rechecked with manual shopping and accessibility UI runs; both passed.
Simulator screenshots were inspected and a large-text wrapping issue corrected.
At accessibility sizes decorative header artwork is omitted and counts stack.

Preview: `shopping-redesign.html` with `47-Shopping-Redesign-Light.png` and
`48-Shopping-Redesign-Large-Dark.png`.


## Artwork revision: fresh groceries

Replaced the blue basket in the screen with an original editorial grocery still life.
Built-in image generation; no reference image. New bundled asset:
`LunaHearth/Resources/Assets.xcassets/ShoppingFresh.imageset/shopping-fresh.png`.
The earlier basket asset is retained but no longer used by the shopping screen.

Final prompt:

> Use case: product-mockup. Asset type: refined colorful grocery illustration for a professional household shopping app, small header artwork. New original composition: a sculptural white ceramic shallow bowl with two bright lemons and one orange, a small cluster of ripe red tomatoes with green stems beside it, a clear glass milk bottle with white milk and plain white cap behind, a few fresh green basil leaves. No basket, no cart, no shopping bag, no blue objects. Premium editorial food photography meets refined 3D product rendering, realistic natural textures, clean precise silhouettes, soft diffused studio light and subtle contact shadows. Seamless very pale neutral background, no brown or beige cast. Compact beautifully balanced still life, entire objects visible, centered composition with breathing room, landscape 3:2. Rich fresh natural red green yellow orange colors, restrained elegant styling. No text, no logos, no watermark, no people, no UI.

## Sage palette and offline store picker (development)

Shopping now uses soft sage instead of stark white surfaces, and charcoal-green
surfaces in dark mode. The produce illustration blends into a pale sage header
with multiply compositing; it is not a transparent asset. A generated transparency
attempt contained a checkerboard and was rejected. No new image is shipped.
Header text has its own dark palette in both modes to preserve contrast.

Manual entry and reviewed shopping ideas offer Browse stores, with US/India
filters, search, saved shops and custom names. The bundled catalog contains 32
common chain suggestions, not every retailer or branch. It works offline without
location permissions or a store API. Retailer names are text, with no affiliation
or logo licensing implied. Examples checked against official directories:
- https://www.walmart.com/store-finder
- https://www.dmartindia.com/about-us
- https://www.relianceretail.com/reliance-smart.html

Case, whitespace and punctuation variants resolve to canonical names on add/edit.
A small explicit alias list handles common shortened names. Existing records are
grouped using the same rule without rewriting them; custom branches stay distinct.
Custom shops remain selectable from the household's shopping history. Country
filters apply to the catalog; saved shops remain visible in Your stores.

Affected entity: GroceryItem.storeName (existing optional text). No schema change,
migration, new network service or permission. Shopping remains local-first with
optional owner-private CloudKit sync and participant shared-database access.
Production schema deployment and live two-account verification remain pending.
This revision is not included in TestFlight build 2.

Validation: simulator build, 73 unit tests, and three UI flows passed (manual
store/buyer entry, store search and selection in dark mode, and large-text dark
form). Screenshot inspection covered light, dark, store search, and accessibility
text. Artwork edge feathering uses SwiftUI masks; a duplicate custom-selection
button was removed when the catalog already supplies the matching store.
The final two UI flows were rerun after those refinements and passed. Updated
light, dark and search screenshots are included in the development preview.

## Reusable private stores

Browse stores → search → Add opens a labeled store-name and optional branch form.
Save store creates a household record immediately; cancelling the shopping item
later does not remove that saved store. Known catalog selections and typed stores
on manual/AI item saves reuse the same household records. Your stores now reads
those records, with legacy item-name fallback during upgrade.

Build and all 79 unit tests passed, followed by seven focused store tests including
two additional mapper/old-backup tests (81 distinct unit tests). The new custom-store
UI flow passed, including persistence after cancelling the shopping item. These are
local and fake-transport checks; live production CloudKit remains unverified.
The regular shopping entry/buyer flow also passed after the store-record changes.
Screenshots 51 and 52 were inspected: labeled name/branch fields, privacy message,
Save store action, and the saved store shown without creating any shopping item.

Release update: shopping palette, store picker and reusable private stores are now in TestFlight 0.1.0 (3), confirmed Testing for LunaHearth Beta. Production CloudKit schema deployment succeeded; live device sync verification remains pending.

## Guided entry after build 3 (unreleased)

Inline store suggestions make Browse optional, with saved-store feedback and an
explicit Use existing action in the duplicate store form. The shopping form warns
about pending duplicate items and requires a deliberate separate-entry choice.
Amount and unit are separate controls; Later reveals a date picker. Main actions
use a compact trailing button instead of a full-width pill. Sage colors remain.
See ADR-015 for validation, migration and private sync behavior.

Validation: XcodeGen, simulator build, all 87 unit tests and three UI flows passed
(inline store/units/date/duplicate item; existing store/buyer; dark/large text).
Screenshots were inspected. The final store-selection state hides the redundant
matching row once its exact name is selected. New preview: shopping-entry.html.
Final UI verification also passed for custom-store creation and duplicate-store
Use existing, plus a rerun of the inline store/units/date/duplicate-item flow.
All four distinct UI flows passed. The final selected-store screenshot was inspected
and the preview updated. This revision is not deployed to TestFlight.
