# Interactive home entrance

## Scope

Today → Step inside your home opens an optional full-screen home scene. The front doors follow the physical Duo hinge using the existing availability-gated Apple adapter. A regular iPhone has an explicit Open door button. Unknown/unavailable transient hinge updates preserve the last known state. Reduce Motion removes the entrance movement.

The noticeboard opens existing Tasks & Chores, Kitchen opens virtual Fridge/Pantry inline, with a List control for the existing Inventory screen, and the grocery bag opens Shopping. Each destination has an explicit Home view control. Dashboard exits the scene. Narrow and accessibility layouts use a scrollable set of labelled actions instead of spatially placed hotspots. This is guided illustrated navigation, not a navigable 3D engine or a scan of the user's actual home.

No records are written by door changes. Navigation is not popped when the device closes, so saved data and in-progress editors are not discarded by posture changes. Existing task, grocery and inventory workflows retain their own local persistence and validation. No permissions, backend, analytics or runtime network requests added. No schema migration.

## Artwork

Original generated background using the imagegen skill and built-in image tool, copied to `LunaHearth/Resources/Assets.xcassets/LivingHomeInterior.imageset/interior.png`. Generation used generic scene instructions and no household content. Source: `exec-dd832930-fe49-41c3-9848-e77adb9e7f7d.png`. Front doors and handles are native SwiftUI drawing.

Prompt: Create an original premium photorealistic 3D rendered home interior background for a native family organizer app, landscape 3:2. View from the entrance at eye level into a beautiful compact modern open-plan home. Charcoal, warm white, soft daylight, subtle terracotta and blue accents, NO wooden cabinetry. Carefully arranged three clear destinations: LEFT third a small entrance alcove with a charcoal noticeboard bearing a few BLANK white cards and a simple desk; CENTER BACK a bright fitted kitchen with white cabinets, brushed steel French door refrigerator and a tall charcoal pantry cabinet; RIGHT foreground a tasteful bench with one canvas grocery tote with a few colorful vegetables. Elegant white tile floor and soft realistic contact shadows, spacious uncluttered composition. No people, no writing, no numbers, no logos, no branding, no interface controls. Render all furniture grounded and at realistic scale. This is a generic illustrative interior, not anyone's actual home. High fidelity materials, architectural visualization, friendly and inviting, not a dollhouse.

The vegetables in the background illustration are decorative; actual inventory appears in the Kitchen destination.

## Validation

- XcodeGen and simulator build passed (`/tmp/interactive-home-build.log`).
- 339 unit tests in 65 suites passed, plus the Duo entry/destination/exit UI test (`/tmp/interactive-home-tests.log`).
- Regular iPhone entry and accessibility/large-text/dark/Reduce Motion UI tests passed (`/tmp/interactive-home-phone-tests.log`).
- Manual physical fold check found that presenting from the adaptive child dismissed the scene during a width change. Presentation state and the full-screen cover were moved to the stable TodayView. Rebuild passed (`/tmp/interactive-home-fold-build.log`).
- Manual simulator check after correction: enter while folded → closed doors; unfold → interior; fold again → closed doors without leaving scene; unfold again → interior. Screenshots `duo-closed-door.png` and `duo-interior.png` captured from the active display, not XCTest's inactive-display attachment.
- Final Duo navigation and entrance-state regression passed (`/tmp/interactive-home-navigation-tests.log`). An earlier navigation check exposed nested full-screen kitchen covers; the kitchen now stays in the home navigation stack, keeping Home view reachable when switching to the inventory list.

- Final iPhone regular and large-text/dark/Reduce Motion navigation tests both passed after the inline kitchen change (`/tmp/interactive-home-final-phone.log`).

Not uploaded to TestFlight or the App Store.
