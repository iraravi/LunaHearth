# Interactive home entrance

## Regular iPhone framing refinement

Tall compact windows now use a dedicated full-height portrait composition of the same interior, preserving the office, kitchen and shopping area together without blurred padding. Generated with the built-in imagegen tool from the existing original home artwork: pull the camera back into the entry hallway, preserve the three destinations, furniture, materials and daylight, tall 9:19.5 composition, no labels or UI. Source: exec-57859d08-24cb-4699-8bf2-9d051281352f.png. Bundled asset: LivingHomeInteriorPortrait.imageset/interior-portrait.png. Small labelled room controls use at least 44-point icon targets; accessibility text sizes retain scrollable full destination rows. Wide windows retain the existing scene layout. This is presentation only: no schema, permissions, network access or record changes. App Store recordings use the fictional in-memory Maple House fixture at normal animation speed.

Closed fridge doors now show only the bundled exterior artwork. Removed the decorative inventory stack on the glass, which was not anchored to shelves and appeared to float. Interactive items remain on interior shelf surfaces and are revealed only after opening.

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

## Full-screen entrance refinement

The home scene now uses the fridge view's edge-to-edge presentation: ignored safe area for scenery, hidden status bar, and hidden root navigation bar. An accessible 48-point close button returns to Today. Destination editors retain their navigation controls. The closed entrance shows a wider exterior with canopy, planters, and steps; native doors open with the existing hinge state and the exterior transitions into the interior. Reduce Motion disables these animations.

New original `LivingHomeExterior` artwork was generated with the imagegen skill from a generic prompt: square, symmetrical modern warm-white home facade, charcoal trim, shallow canopy, two planters, stone steps, straight-on camera a few metres back, empty black central doorway for native animated door overlays, no text/brands/people/wooden doors. No household content was used or transmitted. The generated asset is bundled offline. Door bounds were matched to the actual generated doorway.

Build passed (`/tmp/home-fullscreen-build.log`). Entrance unit tests and unfolded Duo destination/return/exit test passed (`/tmp/home-fullscreen-tests-open.log`). An initial run with the simulator folded correctly stayed at the entrance; the navigation test requires unfolding first. Manual closed-to-open verification confirms status/navigation bars are absent in `fullscreen-entrance.png` and `fullscreen-interior.png`.

### Direct hinge opening and realistic doors

Follow-up refinement removes all instructional text on the physical Duo entrance. Regular iPhone retains an accessible icon-only Open door control. The original exterior was edited through imagegen to add photorealistic charcoal double doors with narrow smoked-glass panels and steel pulls, preserving the facade. `LivingHomeExteriorDoors` supplies the cropped door leaves; SwiftUI animates those leaves rather than drawing substitute panels.

Final requested behavior matches the fridge: hinge changes directly open/close the door leaves and reveal/hide the full interior with a 0.85-second transition. There is no camera zoom, timed approach, or waiting sequence. Reduce Motion makes the transition immediate. No content writes or network calls occur. An animated-entry UI regression exercises the destinations after the reveal.

Final direct-hinge unit tests and animated navigation/return/exit test passed (`/tmp/home-direct-hinge-open-tests.log`). The iPhone large-text/dark/Reduce Motion route also passed during this refinement (`/tmp/home-cinematic-phone.log`); the final change removes the timed sequence and uses the same immediate Reduce Motion behavior. Updated entrance screenshot confirms realistic doors and no instruction text. No release upload performed.

### Regular iPhone virtual kitchen entry correction

The Inventory toolbar incorrectly required physical hinge support before exposing virtual mode. Regular iPhones now have a Virtual kitchen control which presents the same full-screen fridge and pantry interiors. Manual phone presentation is separate from the saved Duo preference so normal inventory navigation remains a list until requested. Returning to the list and reopening are supported. No model, household data, network, or permission changes. UI regression coverage enters from Home → Pantry, switches storage, returns to the list, and reopens virtual mode.

Regular-iPhone correction verification: build succeeded and 339 unit tests passed. UI test initially found both the covered toolbar and the full-screen List view identifier; narrowed the test to the List view label. Retest passed, including entering from Inventory, switching to Pantry, returning and reopening. Logs: `/tmp/NamIllam-phone-virtual-test.log`, `/tmp/NamIllam-phone-virtual-ui-retest.log`. Candidate build 79 walkthrough captures passed on iPhone Pro, Pro Max and iPad. Build 79 is not uploaded.

Candidate 79 Duo manual capture: verified Home closed/open, Fridge closed/open with mist, Pantry closed/open using Device Hub's physical posture controls on iOS 27.1. Six unretouched screenshots retained in `docs/release/2.0.1-build79/screenshots/iphone-duo/`. The inside display produces black frames while powered off; those are excluded from the App Store preview edit.
