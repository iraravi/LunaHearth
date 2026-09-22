# Filters & AI redesign

September 13, 2026. Responds to the shopping and pantry screenshots showing a tall
AI button, stacked menu labels, long explanatory copy and a pantry card that shrank
to the width of its selected filter.

## Layout and behavior

Both screens now use `GroceryToolsSheet`, `GroceryToolsCard` and `GroceryToolsMenu`.
Cards fill the same column before their background is drawn. Each menu places its
label and selected value in one row, with the entire row opening the native picker.
Larger text stacks the value below its label. Shopping retains When needed, Buyer
and Include bought. Inventory retains status and date/low-stock shortcuts.

Check, Organize and Refresh use a small tinted control with a minimum 44-point hit
target. System prominent-button padding is removed. Categories have a short status
label, optional result/error feedback and a separate reset action. Similar items has
its own navigable row. Explanations about on-device categorization and temporary
suggestions are available in a collapsed About disclosure. Reset filters appears
when a filter can be cleared.

A new full-color grocery organization illustration sits beside the introduction.
Its transparent background blends into the existing sage and peach themes and
their dark appearances. Decorative artwork is hidden from VoiceOver and omitted
at accessibility text sizes. Native text remains scalable; all content scrolls and
the sheet column is bounded on iPad. No decorative animation was introduced.

## Data and privacy

Affected presentation: GroceryItem and InventoryItem filtering and category hints.
No record schema, repository, CloudKit transport, sync ownership, permission,
network request or runtime AI integration was added or changed. Filters remain
local view state; category suggestions are transient and resettable. Empty AI
output now reports no new suggestions instead of claiming that categories were
applied. Important stored records are never changed by the tools.

## Validation

Simulator build and all 115 unit tests in 21 suites passed. Five UI flows passed:
the redesigned tools, known-item category feedback, dark appearance, accessibility
text, and iPad landscape. The flows verify native filter selection and reset,
equal-width cards, a 44-point minimum AI action target, synthetic category
suggestion/reset feedback, nested duplicate review and dismissal. The final
accessibility flow was rerun after keeping decorative glyphs within their icon
tiles; adjacent text continues to scale.

Shopping and inventory screenshots were inspected in light and dark appearances,
accessibility text and iPad landscape. Evidence is stored beside this document as
`94-*-Tools-*.png` and `95-*-Tools-Applied-*.png`. XcodeGen generation and the signed
Release archive for 0.1.0 (5) succeeded. That build was installed and launched on
Ravi's iPhone with the Production CloudKit entitlement preserved.
It also completed Apple processing and is Testing in the existing LunaHearth Beta
TestFlight group as 0.1.0 (5).

AI interaction tests use synthetic suggestions. Real Foundation Models output and
live two-account CloudKit delivery were not exercised by these presentation checks.

## Artwork

Mode: built-in `image_gen`, generated from generic objects, then edited by the
same tool for a transparent background. No household content was supplied.

Workspace asset:
`LunaHearth/Resources/Assets.xcassets/GroceryOrganization.imageset/artwork.png`

Source:
`/Users/ira/.codex/generated_images/01a096cc-c31b-70a2-9e14-ccdd50c33fc6/exec-74d78685-4140-46f2-b9a7-5b6e105b8820.png`

Final transparent source:
`/Users/ira/.codex/generated_images/01a096cc-c31b-70a2-9e14-ccdd50c33fc6/exec-e1362030-2dc2-45dd-b83e-d6214ba18ac1.png`

The project copy is resized to 768 pixels for this small UI placement, preserving
alpha. The original generated files are retained.

Generation prompt:

> Use case: stylized-concept. Asset type: bundled decorative illustration for a professional Apple household app's Filters & AI sheet, used beside native text at about 140 points wide. Create one premium, beautifully lit 3D still-life illustration of groceries neatly organized into two low, open, rounded white ceramic trays: a vivid red tomato and yellow lemon with a fresh green leaf in one tray, a small clear glass jar of golden grains and a simple white milk bottle with a mint cap in the other tray. Add one small tasteful mint-green rounded tile with a simple embossed check mark, suggesting organization. Composition: compact, cohesive centered arrangement, three-quarter elevated product view, objects fill most of a square canvas with comfortable outer padding. Clean white studio background, soft short contact shadows, no horizon line. Mature polished product-render aesthetic, natural accurate recognizable food, crisp shapes, vivid fresh colors with mint and soft coral accents. Not a basket, no blue basket, no brown or sepia cast, no wood, no cartoon faces, no text or letters, no logo or watermark. All content is generic decorative artwork, not user data.

Final edit prompt:

> Use case: background-extraction. Edit this decorative grocery organization illustration for an iOS app. Remove the white studio background and deliver actual transparent RGBA pixels around the complete object arrangement. Preserve the two white trays, tomato, lemon, green leaf, grain jar, milk bottle, mint lids and checkmark tile exactly. Keep their colors, composition, realistic material detail, and soft short contact shadows; no text, no new objects, no cropping of the subjects. The result must composite cleanly on light sage, light peach and dark charcoal app surfaces, with no white rectangular backdrop or white edge halo.
