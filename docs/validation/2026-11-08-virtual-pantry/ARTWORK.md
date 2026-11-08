# Realistic refrigerator artwork

Generated with the built-in imagegen tool and imagegen skill. Generic unbranded artwork informed by the user's French-door refrigerator reference, not copied retail photography. Empty backgrounds; saved grocery icons are overlaid locally. No household data sent for generation.

Assets:
- `LunaHearth/Resources/Assets.xcassets/VirtualFridgeClosed.imageset/fridge.png`
- `LunaHearth/Resources/Assets.xcassets/VirtualFridgeOpen.imageset/fridge.png`

## Closed prompt

Use case: product-mockup. Create a photorealistic app background texture of a premium unbranded French-door refrigerator, straight-on orthographic front elevation. Portrait 2:3. Fridge fills image edge to edge, no room, no floor, no margin. Brushed stainless steel left upper door with inset dark water dispenser; right upper door has a large smoked black glass viewing panel, subtly illuminated but EMPTY, no food visible. Vertical center seam exactly at 50% width. Upper two doors occupy exactly top 70% of image. Two horizontal stainless freezer drawers fill bottom 30%. Beautiful realistic recessed handles, precise metal edging and subtle reflections. No logo, text, labels, controls UI, numbers, stickers, branding, watermark. This is original generic appliance artwork, not an LG product photograph. Highly realistic materials, neutral lighting. Consistent technical geometry for use as animated door texture.

## Open edit prompt

Use case: precise-object-edit. Edit the generated unbranded fridge image immediately above into the MATCHING OPEN state for an app. Keep the bottom two steel freezer drawers EXACTLY in place (lower third), same framing, image size and metal treatment. Upper two refrigerator doors are now swung open toward left/right edges, revealing their thin empty clear door bins along the margins, and a spacious EMPTY luminous white refrigerator cavity with three glass shelves at approximately y=22%, 40%, 58% of the full image. Upper fridge cavity uses top two-thirds; lower drawers remain closed. Front-facing orthographic photorealistic view. No groceries, no bottles, no labels, no branding, no letters, no UI, no watermarks, no room. Fill image edge to edge. This is a production app background and the app overlays the user's actual groceries; all shelves and bins must be empty.

## Integration

Output geometry measured visually: top door region ends at 66.5% height; central shelf levels about 20%, 32.5%, 44.7%. SwiftUI positions food icons to these levels and clips each half of the closed image into independently animated upper doors. The bottom drawers are decorative; controls still expose storage selection and the existing editor. Runtime stays native and offline. Original earlier interior asset retained for existing references.

## Modular pantry assets

Generated original assets copied to `VirtualCupboardClosed.imageset/cupboard.png` and `VirtualCupboardOpen.imageset/cupboard.png`. No household data supplied. Final output files were `exec-210e6a8e-9b74-4bd1-8060-d429a5f826cc.png` (closed) and `exec-c6272e94-7370-40e1-bdf5-e58c64bde1a0.png` (open).

Closed prompt: Photorealistic modular kitchen pantry CLOSED exterior, straight-on orthographic portrait 2:3. Entire image filled edge to edge by TWO full-height smooth matte dark charcoal lacquered metal slab doors, seam exactly at 50% width. Sleek thin brushed stainless vertical handles either side of the center at mid-height, subtle realistic soft reflections and fine seams, premium contemporary kitchen. No room or margins, no wood or grain, no brown, no glass, no food, no text, labels, logos or UI. Flat flush slab doors without decorative panels. Matched pair for an app whose open state has a warm-white fitted pantry interior and metal pull-out baskets.

Final open edit prompt: Remove ALL wood and wood grain: replace both wooden door inner faces and every wooden trim with smooth MATTE DARK CHARCOAL painted metal. Preserve the warm-white modular interior, the two white shelves with brushed-metal edges, both empty pull-out wire baskets, hinges, rails, exact composition and shelf positions. Neutral white lighting, not yellow/brown. Everything empty. Photorealistic, no writing, labels, logos or UI. The final image must contain absolutely no wood anywhere.

Food remains native illustrative symbols over empty artwork, not photographs of the user's actual products. Shelf contact positions use normalized coordinates so they follow the scene size.
