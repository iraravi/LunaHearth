# Privacy policy delivery

September 16, 2026 — build 55

More → Privacy & data → Privacy policy provides a native, selectable-text, Dynamic Type offline draft. It explicitly says publisher details and the published policy are not finalized. It is a preview for testing, not legal clearance or the final release notice. Source text mirrors the release website draft.

No policy download or new network connection is implemented. Household records remain local/optional CloudKit; this screen does not read them. No permissions, schema changes or dependencies are added.

## Proposed final delivery
Use an approved public HTTPS policy page on publisher-controlled hosting, plus a versioned offline copy in the app. Opening the public page on request gets the current policy without needing iCloud. A private CloudKit record is not publicly accessible; a public CloudKit record would still need a website for App Store visitors and reviewers, and requires unnecessary database/schema/auth handling for a static document.

Before connecting a URL: confirm legal operator, privacy/support contact, launch territories and approved policy text. Review hosting access logs/cookies and disclose actual practices. Use a stable HTTPS URL, no account gate and no advertising or analytics scripts. If a future in-app downloader is chosen, document its privacy/threat review and ADR, use a bounded trusted endpoint, avoid executing remote content, retain the dated offline version on failure and distinguish fetched policy version from the bundled one. Do not silently imply an old offline copy is the current hosted policy. Policy edits do not authorize new data processing or replace required consent.

## Release blockers
Publish the approved page; configure the actual URL both in App Store Connect and in an accessible in-app link. Replace the draft banner/text only after facts and policy are finalized. Do not invent a URL or publish unconfirmed contact details. Verify hosted and offline copies, accessibility and unavailable-network behavior. The app currently offers only the offline draft, with no claimed dynamic updates.

Apple references:
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- https://developer.apple.com/app-store/review/guidelines/#privacy
