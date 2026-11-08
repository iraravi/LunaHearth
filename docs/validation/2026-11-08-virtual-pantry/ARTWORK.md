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
