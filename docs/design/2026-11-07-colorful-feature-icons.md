# Colorful feature illustrations

Original artwork generated with the built-in image-generation tool, following the imagegen skill. User reference: neutral light/dark service cards with colorful miniature objects. No Uber artwork or logos are copied into the application.

## Final assets

All assets are stored under LunaHearth/Resources/Assets.xcassets:

- FeaturePantryV1.imageset/icon.png
- FeatureShoppingV1.imageset/icon.png
- FeatureRemindersV1.imageset/icon.png
- FeatureReceiptsV1.imageset/icon.png
- FeatureMealsV1.imageset/icon.png
- FeatureExpensesV1.imageset/icon.png

Generated PNGs were exported at 384 pixels with sips, retaining alpha. Six files total 885,525 bytes. Asset catalogs and the shared FeatureIllustration view force original rendering, keeping full color in both themes. There are no network downloads or runtime image generation. Decorative images are hidden from VoiceOver; the existing visible button labels and identifiers remain. Main navigation/control glyphs stay simple.

## Final generation prompts

Common prompt, applied once per subject with transparent_background=true:

“Use case: stylized-concept. Create one polished colorful miniature 3D app feature illustration: [subject]. Isolated centered object on genuine transparent background. Friendly premium product-service icon, softly rounded tactile forms, bright clean saturated accents, white highlights, subtle contact shadow, consistent isometric three-quarter view, soft studio light from upper left. Readable at 64 points on both near-black and white cards. Object occupies central 75% of square canvas. No words, letters, logos, watermark, surrounding tile or background. Original artwork for a household organizer. Output single square icon.”

Subjects:

- Pantry: a teal open kitchen cupboard with neatly arranged cream jars, orange carrots and green produce
- Shopping: a coral-red grocery basket with a green leafy vegetable, yellow carton and blue milk bottle
- Reminders: a sky-blue clipboard with white paper, three green check marks and an orange pencil
- Receipts: a small ivory receipt with abstract dark lines emerging from a violet scanner, small mint check badge
- Meals: a turquoise bowl of colorful vegetables and rice with a coral spoon
- Expenses: a cobalt-blue wallet with a golden coin and mint-green miniature bar chart

## Scope

Home compact cards and wide workspace actions; shared HearthIcon uses; Today shopping/meal overview links; More feature icons. Existing non-feature symbols use a colored SF Symbol fallback. This is presentation-only: no domain logic, permissions, persistence, schema, household data or release-version changes.

## Verification

XcodeGen generation and iPhone 18 Pro iOS 27.2 build passed. testColorfulHomeIconsLightAndDark passed, checking Home-to-Pantry navigation in both appearances. Both captured Home screens were visually inspected and retained under docs/validation/2026-11-07-colorful-icons. Alpha verified on the exported pantry asset. Log: /tmp/namillam-color-icons.log. Wide layout is wired to the same component but was not separately exercised in this change. No release upload.
