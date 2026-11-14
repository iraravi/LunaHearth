# Nam Illam — website, privacy and legal readiness review

Reviewed 24 October 2026. Scope: current working-tree app source and the marketing/support website. This is a technical evidence review and legal drafting aid, not an attorney opinion, trademark clearance, penetration test, or Apple approval. Existing unrelated native changes were preserved. No native build or simulator tests were run for this website/content task.

## Decision and delivered scope

The user selected **Nam Illam / நம் இல்லம்** (Our home). Website branding, metadata, navigation, support email subject and explanatory captions now use this name. NeuralLuna remains the publisher brand; it is not asserted to be an incorporated legal person. Existing app screenshots still show LunaHearth and are labelled accordingly. Bundle identifiers, CloudKit container, Swift types and native display name were not changed.

Eight website pages now include five independently editable, validated legal content files: privacy, terms, legal information, data controls, website/cookies. All remain dated review drafts with no invented effective date. The owner selected support@namillam.com and namillam.com on 24 October 2026. Mail delivery and production domain connection remain unverified. The existing private Sites audience is preserved. Firebase Hosting and Pages CMS remain planned, not connected.

Affected information: household member profiles, events, tasks, shopping, pantry, purchases, meal plans, rooms/assets, notes, cloud sync metadata, Apple source identifiers, local diagnostic categories, support messages and website connection information. No new collection, account, network request, permission, persistence schema or runtime dependency was added. Website content is rendered at build time and HTML-escaped; invalid files stop the build.

## Evidence and corrected disclosures

| Topic | Current source evidence | Website consequence |
|---|---|---|
| Local first | Data/Local/LocalStoreConfiguration.swift; Data/Local/LocalHouseholdRepository.swift | Core records on-device; do not claim everything always stays on-device. |
| Sharing | Data/CloudKit/CloudKitHouseholdService.swift; Features/Sharing/HouseholdSharingView.swift | Optional private/shared CloudKit, recipient access and copied information disclosed. |
| Manual backups | Data/CloudKit/CloudKitBackupService.swift | Separate snapshot lifecycle; old generation cleanup can fail; explicit delete action targets generations. No immediate universal-erasure promise. |
| File limitations | LocalHouseholdRepository.swift:107-108; Features/Sharing/HouseholdSharingView.swift | Backup rejects document/room-plan attachments; no complete document vault or file backup promised. DocumentStorageService is only a directory helper, not proof of a production secure vault. |
| Deletion markers | Domain/Sync/HouseholdSharing.swift:23-25; CloudKitHouseholdService.swift:235-270 | Empty content payload on tombstones; identifiers/type/timestamps remain, with no scheduled expiry found. |
| Cleanup | Features/More/DangerZoneView.swift; Data/Local/LocalHouseholdRepository+Cleanup.swift | Category deletion can sync. Local reset blocks connected homes. Backups and Apple entries remain separate. |
| Apple integrations | Services/Calendar/CalendarIntegrationService.swift:19-28 and selected-list predicates | Full OS permission, then selected-source filtering. This is not OS-level permission limited to one list. New reminders saved to Apple. |
| Operational configuration | Services/Configuration/PublicConfigurationStore.swift; Data/CloudKit/CloudKitPublicConfigurationService.swift | Public fixed-record reads are distinct from opt-in household sync; not a legal-policy updater. |
| AI/photo/receipts | Services/AI/OnDevice*; Services/PantryPhoto/OnDevicePantryPhotoScanner.swift; Services/Receipts/VisionReceiptScanner.swift | On-device framework use; reviewed suggestions, capability limits and no remote AI endpoint. |
| Diagnostics | Domain/UseCases/AIRequestDiagnostics.swift; Features/More/AIStatusView.swift | Local result categories/timestamps and clear-history control, not raw prompt logging. |
| Dependencies/permissions | project.yml; Resources/Info.plist; Resources/PrivacyInfo.xcprivacy | Empty runtime dependency list; tracking false; explicit Apple/camera permission strings. This does not establish all App Store privacy labels. |
| Website | dist/assets/site.js, motion.js; generated HTML | No custom forms, fetch, analytics, cookies or web storage in authored scripts; hosting authentication/logging is separate. |
| Native policy | Features/More/PrivacyPolicyView.swift; docs/PRIVACY_POLICY_DELIVERY.md | Older offline draft remains; public URL and final copy must be aligned before launch. |

Paths above are relative to LunaHearth/ unless prefixed docs/ or website paths. Source claims were reviewed against the working tree, not a signed release binary. Historical architecture docs include superseded shopping/reminder flows; current source and current user-facing controls were prioritised.

## Blocking decisions before public release

1. **Operator identity:** full legal person/company, required contact address, responsible support/privacy/grievance person. Brand ownership is not corporate registration.
2. **Working contact:** owner selected support@namillam.com; test inbound/outbound messages and restricted staff access. Publish actual support response handling, not an aspirational SLA.
3. **Retention:** approve and implement mailbox/ticket retention, attachment deletion, backups, access controls and any legally required retention. No arbitrary 30/90-day claim has been made.
4. **Production hosting:** provide Firebase project/domain; verify actual logs, cookies, provider terms, access settings and cross-border processing. Firebase Hosting documentation describes IP use for abuse prevention and retention for a few months. Do not claim Firebase is deployed or all processing stays in India. Pages CMS access would be publisher/admin-only; household records must never enter that repo.
5. **Public policy URL:** current owner-only preview cannot serve as the public App Store privacy URL. Deploy accessible HTTPS documents and verify from signed-out mobile/desktop browsers. Connect policy in App Store Connect and in-app; keep dated offline copy aligned.
6. **Name/rights:** formal Nam Illam exact/phonetic/class search, App Store title availability, screenshots/icon/artwork/font rights. Domain ownership and web-search absence are not clearance.
7. **Distribution:** confirm price, India territory, seller identity and actual EULA selected in App Store Connect. Terms draft does not set a subscription or replace Apple’s EULA.
8. **India legal assessment:** determine applicable current IT Act/SPDI requirements and phased DPDP obligations for the actual operator and launch date. Assess children's data even with adult-managed profiles, notices/consent, grievance handling, provider contracts, incident response and transfers. Do not infer complete exemption merely from local-first design.
9. **Native reconciliation:** app title, support links, old policy copy and screenshot naming need a separately validated native release update. Do not rename bundle IDs or CloudKit containers as a cosmetic change.
10. **Release evidence:** actual-device sharing/revocation, deletion scopes, backups and restore, Apple permissions and on-device AI checks remain distinct from static policy analysis. Reconcile App Store privacy declarations with the final binary and support/hosting practices.

## Legal drafting choices

Terms explicitly retain mandatory consumer rights. No blanket liability waiver, invented jurisdiction, forced arbitration, refund promise, established company identity or unverified security certification is asserted. Food/meal, room-layout, spending and AI limitations are grounded in product behaviour. No blanket legal guarantee is made. Draft content is not represented as an effective contract.

The DPDP Act commencement notification and Rules use staggered commencement (immediate, one year and eighteen months after Gazette publication). As of this review the core eighteen-month tranche is not yet effective; counsel should verify commencement and any intervening amendments at launch. The policy does not incorrectly claim all DPDP duties already apply, or that none of the existing privacy/security laws apply. A calendar date should not be used to postpone operational privacy safeguards.

## Official references checked

- Apple App Review Guidelines, especially privacy: https://developer.apple.com/app-store/review/guidelines/
- Apple Standard EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- Firebase privacy/security and Hosting retention: https://firebase.google.com/support/privacy
- DPDP Rules 2025, official Gazette hosted by MeitY: https://www.meity.gov.in/static/uploads/2025/11/53450e6e5dc0bfa85ebd78686cadad39.pdf
- DPDP commencement notification: https://www.meity.gov.in/static/uploads/2025/11/c56ceae6c383460ca69577428d36828b.pdf
- IT SPDI Rules 2011, India Code: https://indiacode.gov.in/server/api/core/bitstreams/e9545daf-b012-49cd-a697-388039b9b7e0/content

## Validation

- Website build: eight pages.
- All legal JSON files validated; malformed content/duplicate sections/missing effective date rejected; injected HTML escaped in a temporary generated site.
- Website reference/accessibility-structure checks: 313 local references, no errors before final packaging.
- Offline repository heuristic audit: 196 Swift sources, permission/transport/privacy declarations and runtime dependency configuration; no findings. This is not a Sonar/CVE scan or proof that the app has no bugs.
- Content test suite: six tests passed.
- Browser checks at 390px and 1280px: all eight pages had one H1, no horizontal overflow and no broken loaded images. Privacy and legal layouts visually inspected; legal navigation opened the correct privacy page. Screenshot: `legal-preview.png` (local build).
- Private deployment succeeded: source `37845a7f8d2f4071ec4747876b05283f116b73a5`; deployment `appgdep_6add27b8a7b08191a15db64b9740b8fd`; URL https://orynvi-home-preview.keencocoa257.chatgpt.site . Existing owner-only audience preserved.
- Hosted browser handoff reached the expected sign-in gate; hosted page content could not be visually verified without that session. Local build was visually verified. This private URL is not suitable for App Store submission.
- Native app build/tests were not run; native source was not changed. Temporary local preview server stopped after review.

## AI terms expansion — 24 October 2026

Added AI/OCR fallibility and verification, no professional or emergency reliance, availability/fallback limitations, truthful preview labelling, on-device privacy and output rights, qualified warranties and liability exclusions. No blanket immunity, mandatory arbitration or monetary cap. These remain review drafts; native confirmation screens have not changed.

Counsel review required: legal operator and contract acceptance; enforceability under Indian consumer/contract law; overlap with the selected Apple EULA; warranties and exclusions; complaints, jurisdiction and remedies; privacy/children obligations. User confirmation UI and marketing must match these statements before release.

Primary references checked: https://www.indiacode.nic.in/bitstream/123456789/15256/1/a2019-35.pdf and https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ .
