# Virtual Pantry

Native SwiftUI optional view for Pantry, enabled by default with a persistent List/Virtual toolbar switch. The original shelf/list view, filtering, search, scan and edit workflows remain available. No root tab added.

## Design and interaction

Bundled generated photorealistic empty refrigerator interior, overlaid with saved item illustrations and labels; empty sections contain no demonstration groceries. Native metallic doors open once when the view appears, with brief translucent cold mist. No repeating movie, particle timer or remote rendering. Reduce Motion skips doors/mist; accessibility text uses a scalable item list instead of fixed-size shelf labels. Tap a pack to edit on compact screens, or inspect it in the right-hand detail panel on wide layouts. The detail panel links to existing quantity, restock and used-up controls in the pack editor.

Fridge/Freezer/Cupboard/Other are visual groups. Explicit saved locations take precedence; unrecognized locations stay Other. Otherwise existing offline food categories suggest a visual section. This does not set or change storage locations and is not storage/food-safety advice. Dates, low-stock state and quantities remain the user's saved data. Packs stay separate; nine items per visual page, with bounded pagination and clamping after changes. Search and existing filters apply to both views.

## Domain, privacy, assets

Affected entities: InventoryItem, read-only rendering; all writes use existing InventoryEditor workflows. No schema/migration, CloudKit, permission, third-party runtime, AI runtime or network changes. Illustration is generated during development with the imagegen skill from a generic empty-appliance prompt (no household data). Source: `/Users/ira/.codex/generated_images/01a091aa-8a50-7532-b4c6-1a30885b7335/exec-04426271-3d64-408a-8ca2-da393ff43968.png`; copied into VirtualFridgeInterior.imageset. App uses bundled image and native SF/emoji symbols. Synthetic produce exists only in the DEBUG in-memory UI fixture.

## Validation

- XcodeGen project generation and simulator build passed.
- 332 Swift Testing tests in 63 suites passed, plus the existing performance XCTest.
- iPhone 18 Pro: virtual pantry light, dark, and accessibility/Reduce Motion UI flows passed.
- Duo: light, dark, and accessibility/Reduce Motion UI flows passed. After the final shelf spacing refinement, light/dark checks were rerun and passed.
- Verified opening pack editor, switching storage sections, switching to existing list and back. Domain coverage includes saved location precedence and pagination without dropped/duplicated packs.
- Reviewed actual active Duo display screenshots; XCTest attachment capture can select its inactive display. Screenshot uses synthetic DEBUG data, not household content.
- No physical-device performance profiling or VoiceOver audio audit performed. No TestFlight upload for this feature.

Full suite evidence: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_14-25-40--0600.xcresult`.
Final visual checks: `duo-dark.png`, `duo-light.png`.
Final UI evidence: `/tmp/NamIllamFix/Logs/Test/Test-LunaHearth-2026.11.08_14-28-45--0600.xcresult`.
