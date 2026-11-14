# Privacy and submission worksheet — October 3, 2026

This is an evidence worksheet, not a completed privacy questionnaire or legal determination. India is the only user-confirmed launch territory. Public support/privacy contact, operator details, hosting practices and pricing remain unknown.

| Data/path | Source evidence | Proposed disclosure review |
|---|---|---|
| Household records, including names, schedules, pantry, purchases and expenses | SwiftData; optional private/shared CloudKit adapters | Assess optional iCloud sharing and access under Apple's current collection definitions. Do not simply equate local-first with Data Not Collected. |
| Receipts, selected photos, documents and AI | On-device adapters; deliberate document saving | Explain what remains local, what may enter household sharing/backup, and the retention/deletion controls. No third-party network model was found in the current source search. |
| Apple Calendar and Reminders | EventKit adapters and explicit connection choices | System account services have separate sharing/deletion behavior. Reminders entries belong to selected Apple lists; Calendar linked changes are one-way. |
| Public configuration | CloudKitPublicConfigurationService reads published settings | Include these routine Apple requests in policy; they are separate from user-enabled household backup. |
| AI diagnostics | Local result category, feature and timestamp | Included in current bundled draft; no prompts/images/model output in that diagnostics history. |
| Support communications and hosted pages | Operator not yet confirmed | Publisher must supply actual contact, handling/retention and hosting logging/cookie practices. These facts cannot be derived from app source. |
| Tracking and required-reason APIs | PrivacyInfo.xcprivacy: tracking false, UserDefaults CA92.1 | No advertising/analytics SDK or URLSession client found in the targeted source search. Confirm the final signed binary and all operational practices before publishing privacy answers. |

The proposed build uses Apple-system encryption and declares ITSAppUsesNonExemptEncryption=false. Retain that verified implementation basis; do not invent additional compliance claims.

Age rating must be derived from Apple's current questionnaire. The app supports private household collaboration and user-entered content; no public feed, gambling or advertisements were found in the reviewed product scope. Do not select Kids Category or assert a final rating before the live questionnaire.

Accessibility: preserve labels, Dynamic Type and Reduce Motion, but do not check App Store accessibility claims solely because a few UI tests pass. Physical VoiceOver and minimum-OS checks remain open.

India-only availability is a store-distribution choice, not legal clearance for India. Final policy/consumer wording and publisher obligations still require appropriate review. No jurisdiction-specific guarantee or legal conclusion is added here.

Apple sources: https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy and https://developer.apple.com/app-store/review/ .
