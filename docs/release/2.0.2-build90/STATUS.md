# 2.0.2 (90) — Brand look, Today tiles, automatic categories

Changes since 89:
1. Colors match the website: ivory and deep amber in light mode, mocha and champagne in dark mode, with Increase Contrast variants for every custom color (Apple HIG). Legacy blue accent follows the brand.
2. Today: Tasks and Shopping tiles with an icon chip, large count and a preview of tasks or item icons.
3. Pantry categories: broader word list and icons; unrecognised items are categorized by the on-device model in the background and remembered on the phone. Pantry rows show item icons instead of a generic box.

Validation: 433 unit tests passed (contrast test across light, dark and high contrast); UI tests passed: App Store screenshots, Today dark. AI categorization not exercised in the simulator.

Distribution: Xcode Organizer → TestFlight Internal Only; Xcode showed "Uploaded to Apple" on November 18, 2026 at 5:26 PM. The tester confirmed running 2.0.2 (90) on November 19.
