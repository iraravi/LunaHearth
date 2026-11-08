# System sans-serif typography

Use Apple's default system font through SwiftUI Font.system, with bold large-title and section-title styles. Replace serif display headings in the shared theme, onboarding, setup guide and demo illustrations. Body text remains native system text. Semantic text sizes preserve Dynamic Type where already used; demo illustration captions retain their existing fixed composition sizes.

No Uber font files, third-party font downloads, custom font registrations or embedded font assets are introduced. Apple's system font is not described as copyright-free: this implementation requests the system-provided font through native APIs rather than redistributing font files. Apple documents the default design as SF Pro for iOS and provides language-specific system designs: https://developer.apple.com/documentation/technologyoverviews/fonts . See also https://developer.apple.com/fonts/ .

This is a typography-only change with no domain, schema, permissions or data changes. Scope is the iOS app, not the website. Validation results are appended below.

## Validation

- Xcode simulator build succeeded on iPhone 18 Pro, iOS 27.2 (the configured iPhone 17 Pro is unavailable).
- UI tests `testColorfulHomeIconsLightAndDark` and `testTodayWorkspaceAccessibility` passed, covering both themes and large-text navigation.
- Inspected exported Home screenshots in both themes: bold sans-serif headings and colorful artwork render correctly.
- Screenshots: `../validation/2026-11-07-system-typography/home-dark.png` and `home-light.png`.
- Build/test log: `/tmp/namillam-fonts.log`.
- No bundled TTF/OTF/WOFF font assets found. No release or upload performed.
