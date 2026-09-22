# LunaHearth 1.0 (54) — release candidate package

Prepared September 16, 2026. This package is a candidate, not a declaration that the app is ready for public release. No upload or public submission is performed by preparing it.

## Contents
- `screenshots/iphone-6.9` and `screenshots/ipad-13`: real app captures using fictional, isolated in-memory records. No personal household data. Upload in numeric order.
- `app-icon-1024.png`: current bundled icon, copied without redesign.
- `metadata/en-US.json` and `listing-copy.txt`: proposed listing text with field lengths checked.
- `metadata/review-notes.txt`: offline review instructions and optional hardware/service capabilities.
- `metadata/privacy-and-age-rating-review.md`: publisher answers requiring confirmation.
- `website/privacy.html` and `support.html`: drafts ready for publisher review and hosting. They are not live URLs.
- `validation/`: audit results, artifact inventory and checksums.
- `index.html`: local visual gallery.

## Wording review update
See `validation/LEGAL_REVIEW.md` for corrected claims and unresolved legal/publisher facts. The revised source wording is later than the archived and installed build 54; a fresh numbered binary is required before distributing these copy changes. This package does not certify legal compliance.

## Before public submission
1. Confirm the public support email, hosted support/privacy URLs, rights holder, app-name/asset rights, pricing/territories and regulatory/trader details. Replace all pending metadata and publish approved pages. The September 14 Connect audit is historical, not a current live listing check.
2. Verify real owner/participant CloudKit sync, offline recovery/conflicts, invitation revocation and background notification delivery on both unlocked devices. Do not delete the user's real home for testing.
3. Complete physical VoiceOver/keyboard checks, iPad window resizing and minimum iOS 18 runtime validation. Current simulator coverage uses iOS 27, not every supported OS.
4. Review Apple's live privacy and age-rating questionnaires. Local privacy manifest validation does not complete either questionnaire.
5. Validate/export the archive with App Store distribution signing, upload 1.0 (54), wait for processing, select it in the 1.0 draft and verify production schema/capabilities. An archive alone is not an App Store upload.
6. Review screenshots against that exact build; select manual release. Submit only after required device and publisher gates are complete.

## Apple reference
Screenshot dimensions and format requirements checked against:
https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
The set targets 6.9-inch iPhone and 13-inch iPad. App preview video is optional and not included. Extra localizations and custom product pages are not included.
