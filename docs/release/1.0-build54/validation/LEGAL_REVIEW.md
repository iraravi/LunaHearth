# Release wording and legal readiness review

Reviewed September 16, 2026. This is a source/copy review, not legal advice, trademark clearance, a security certification or a guarantee of compliance. Final obligations depend on publisher identity, distribution countries, actual support/hosting practices and the shipped binary.

## Addressed

- Replaced in-app claims that offline edits simply sync when connected with language acknowledging connectivity and delay. Described participant access in terms of permissions, not absolute confidentiality.
- Replaced setup’s broad “Nothing uploads” statement with a statement about local home creation. Joining an existing shared home is a separate network workflow; system backups are separate from app-level sync.
- Clarified that clearing records or disconnecting integrations does not necessarily erase backups, exports, Apple Calendar/Reminders entries or copies already received by participants.
- Expanded listing/support language: AI and OCR can be wrong; review extracted records; meals do not establish allergen or food safety; expenses summarize entered records. These notices do not excuse inaccurate features or replace safety validation.
- Added privacy-draft explanation of household profile records, permission to share other people’s information and system backups. No new collection, permissions, network service, schema or business logic was introduced.
- No invented corporate identity, address, retention period, age threshold, jurisdiction, copyright ownership, certification, warranty waiver, arbitration provision or liability cap was added.

## Blocking before public submission

1. **Publisher and contact:** confirm actual legal operator/rights holder, public privacy/support contact, effective date and intended countries. NeuralLuna is a brand label, not evidence of an incorporated legal entity. Do not reuse private tester credentials or contact details as a public business contact without confirmation.
2. **Published privacy policy:** draft HTML is not a live policy. Publish the approved version, place its actual URL in App Store Connect, and add an easily accessible in-app link (More → Privacy & data currently has controls but no published policy link). Do not insert a guessed URL. Apple guideline 5.1.1 requires both locations.
3. **Complete operational privacy details:** identify support email/hosting providers, access, purposes and retention/deletion practices. Assess legal bases, data rights, international transfers and child-related obligations for selected countries. Do not publish “GDPR compliant”, “COPPA compliant” or equivalent claims without a jurisdiction-specific assessment. A family app or App Store age rating alone does not settle these obligations.
4. **Privacy labels:** resolve Apple’s collection definition against actual CloudKit, diagnostic, support and hosting practices. “Data Not Collected” remains an unsubmitted proposal, not a legal conclusion. Confirm encryption/export answers and manifest against the final app.
5. **Rights:** obtain name/trademark clearance for LunaHearth and NeuralLuna and retain provenance/licenses for every image, icon, generated asset and bundled template. Screenshots are actual app captures with fictional data, but that does not prove rights to underlying artwork. Avoid competitor marks and claims of Apple sponsorship; factual integration names are not an endorsement.
6. **Markets and children:** counsel should assess selected US/India/other markets once confirmed, including privacy and consumer requirements and whether actual audience/functionality triggers child-specific rules. Do not add child-facing claims or choose Kids Category from the word “family”. Review private sharing/reporting/access controls under Apple’s user-generated-content rules; no exemption is assumed.
7. **EU distribution:** if offered in the EU, determine trader status and supply required verified public contact information. Do not claim non-trader status merely to avoid disclosing details. Apple may display an address, phone and email for traders.
8. **License:** Apple’s standard EULA applies if no custom EULA is supplied. Verify the actual Connect configuration before representing it as selected. A custom EULA would need separate counsel review and Apple’s minimum terms. No bespoke contract was created or accepted here.

## Verification and scope

Listing length limits checked after revision. Changes to app source are copy-only. Build/test evidence is appended after execution. The previously installed/archived build 54 does NOT contain these later source-copy edits: build a fresh numbered candidate before distributing them. Existing screenshots show unaffected screens; current archive and screenshots are not evidence that a published policy link exists.

No App Store metadata, privacy labels, trader declarations, website or legal agreement was submitted or published by this review. Final policy cannot be completed until the operator/contact and operational facts are supplied.

## Primary references checked

- Apple App Review Guidelines: accuracy, privacy policy, intellectual property, children and user-generated content: https://developer.apple.com/app-store/review/guidelines/
- Standard/custom EULA handling: https://developer.apple.com/help/app-store-connect/manage-app-information/provide-a-custom-license-agreement/
- Apple standard EULA: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
- Custom EULA minimum terms: https://www.apple.com/legal/internet-services/itunes/dev/minterms/
- EU trader information: https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/

Validation: simulator build succeeded and all 237 unit tests in 44 suites passed after these source-copy edits (`/tmp/luna-legal-check.log`). No new device install, archive, hosted-page publication or UI screenshot run was performed in this wording review.

## Follow-up: user-requested food/AI guardrails
ADR 044 adds always-visible notices at meal suggestion, weekly drafting, meal editing/cooking, receipt and photo review points. New generative meal output has no recipe-step field; a deterministic factory supplies no cooking steps. Older/manual/built-in steps remain with notices, not a safety certification. AI Status and Today also explain fallibility. This does not guarantee safe food or eliminate liability; built-in/legacy recipe editorial review remains an open release item. Changes postdate the build 54 archive and installed app.

Guardrail validation: final simulator build and 238 unit tests passed; meal planning → shopping → cooked/pantry review passed after correcting an obsolete Home selector. Receipt review/import passed in the initial run. Cooking notice screenshot visually inspected and saved as `meal-safety-notice.png`. No live-model safety evaluation, physical-device or iPad visual verification is claimed. Logs: `/tmp/luna-safety-check.log`, `/tmp/luna-safety-retest.log`.
