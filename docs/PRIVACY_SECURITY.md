# Privacy & Security Design

## 1. Threat/privacy posture

LunaHearth contains potentially sensitive household information: names, schedules, home contents, serial numbers, receipts, warranties, and documents. The primary risk reduction strategy is to avoid collecting that data into NeuralLuna infrastructure at all.

## 2. Storage modes

### Device Only
- SwiftData metadata on device
- documents in app sandbox
- OCR/intelligence on device
- no family synchronization

### Optional iCloud Family Sync
- local copy remains
- selected LunaHearth records synchronize through the user’s CloudKit container/share
- shared participants receive data through CloudKit
- NeuralLuna does not operate a separate household-content backend

Do not claim “never leaves device” when iCloud mode is enabled.

## 3. No custom identity

MVP has no:
- email collection for login
- password database
- auth tokens
- user-profile backend

CloudKit/iCloud account availability is handled by Apple system services.

## 4. Data minimization

Do not collect fields merely because they may be useful later.

Examples to avoid without explicit feature need:
- precise location
- health data
- financial account data
- contact-book upload
- government identifiers
- child account credentials

## 5. Children

MVP is an adult-managed household application.

A child member record is a profile/assignment target, not an independently authenticated user.

Do not:
- market MVP as a child-directed social service
- create child login/email requirements
- add public child profiles
- add advertising/tracking

Any future child-facing authenticated experience requires separate legal/product review (including COPPA and applicable regional requirements).

## 6. Permissions

Just-in-time only.

Calendar/Reminders:
- request only when integration selected
- prefer least access required

Photos:
- use system pickers to reduce broad library permission where possible

Camera:
- scanning flows only

Notifications:
- after user creates reminder value

## 7. Local file security

When document vault is implemented:
- store under Application Support, not a publicly shared directory
- apply appropriate `FileProtectionType` (e.g., completeUntilFirstUserAuthentication or stricter based on UX testing)
- use random UUID directory/file identifiers
- sanitize display filenames
- never execute imported content
- preview through system-safe APIs

## 8. Logging

Prohibited in logs:
- event titles
- free-form notes
- child names
- serial numbers
- document text/OCR output
- receipt content
- CloudKit share URLs

Log only:
- entity type
- redacted IDs if necessary
- counts
- error domain/code
- timing

Use `Logger` privacy controls.

## 9. AI privacy

Default AI path is on-device.

- Pass only minimal context.
- Avoid assembling the entire household database into a prompt.
- Do not persist raw model prompts/responses unless feature explicitly needs it.
- Never transmit to a remote model without a future explicit product/legal architecture decision.
- User reviews structured extraction before important writes.

## 10. CloudKit security model

CloudKit share ownership and participant permissions are controlled through Apple APIs.

Product must still:
- present clear member/permission UI
- handle removed participants
- handle revoked shares
- avoid leaking share metadata through logs
- not assume product child/adult role equals CloudKit permission primitive

## 11. Export and deletion

Before release:
- user can export household records
- user can export documents
- user can delete local household data
- shared-household owner/participant deletion semantics are documented and separately confirmed

Never silently delete local-only data due to iCloud sign-out.

## 12. App Store privacy label

Fill based on actual implementation, not intended marketing.

If no third-party SDKs and no NeuralLuna backend are added, the privacy label may be relatively minimal, but CloudKit/system behavior and any diagnostics/support features must still be evaluated under Apple’s definitions at submission time.

## 13. Security review checklist

Before each release:
- dependencies reviewed
- permission strings match behavior
- no secrets in repo
- no private data in logging
- file protection tested
- share/revocation tested
- import validation tested
- export/delete tested
- screenshots/demo data contain no real household data
- privacy policy matches exact code paths
