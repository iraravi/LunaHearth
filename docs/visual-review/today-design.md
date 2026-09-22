# Today dashboard

September 13, 2026. Today now leads with a quiet sage home illustration and three priorities: Buy, Use soon, and Restock. Small actions replace large repeated buttons. The daily brief uses a pale lavender surface; schedule, reminders, home care, and meals remain below the priorities.

On iPhone, compact priority selectors show one panel at a time. Wide iPad windows show all three panels and two columns for the rest of the day. Accessibility text uses a vertical heading and removes decorative hero art to make room for readable text. Dates and overdue states use text and symbols as well as color.

## Behavior and privacy

Purchases use the existing inventory-choice sheet. Restock uses the local repository's duplicate checks and does not infer quantities or clear low-stock status. Past expiry labels ask the user to check the item and are not food-safety advice. Personal shopping respects the selected member; pantry attention covers the home.

The optional daily summary passes only eight aggregate counts to the on-device model. No item names, household identity, or private notes are passed. An exact saved-data summary works offline without model availability. No CloudKit mapping, schema, ownership, or permission changes were made. See [ADR 021](../ADR/021-today-attention-dashboard.md).

## Artwork

Generated with the built-in image-generation tool. Bundled asset: [TodayTogether artwork](../../LunaHearth/Resources/Assets.xcassets/TodayTogether.imageset/artwork.png). This generic decoration contains no household data. The RGBA asset was resized to 900 pixels for bundling.

Exact prompt:

> Create one professional editorial 3D illustration for the Today dashboard of an Apple household app. A serene miniature contemporary home corner arranged as one compact still life: a soft sage sofa with a pale apricot cushion, a small ivory side table holding a yellow lemon and one red tomato in a shallow ceramic bowl, a leafy green plant, and an elegant small arched window with a subtle warm morning sun. No people, no text, no lettering, no numbers, no UI, no logos. Premium tactile ceramic and soft fabric materials, crisp refined forms, natural dimensional studio lighting, gentle short shadows. Sophisticated muted sage, ivory and pale lavender with small fresh yellow and coral accents. Avoid brown/sepia cast, dark heavy shadows, blue basket, cartoon faces or busy detail. Compact right-weighted composition, elevated three-quarter view, all objects fully visible, centered with comfortable margins. Actual transparent RGBA background so it blends into pale mist and dark charcoal UI. Square asset. This is generic decorative bundled artwork, not household data.

## Validation

120 unit tests passed, including overdue/date boundaries, alias restock grouping, selected-member scope, and duplicate prevention. UI flows passed for purchasing into existing inventory, opening a specific pantry pack, restocking once, deterministic daily summary, empty Today, personal shopping, dark appearance, accessibility text, and landscape iPad.

Screenshots: [Light](97-Today-Light.png), [Dark](97-Today-Dark.png), [Large text](97-Today-Large.png), [iPad](97-Today-Landscape.png), [Daily brief](100-Today-Brief-Light.png), [Rest of the day](101-Today-Day-Light.png).

Live two-account CloudKit sharing still requires Kira's device. Simulator tests exercise the deterministic brief fallback, not real model quality. No TestFlight upload is included in this change.
