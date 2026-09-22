# ADR 040 — Receipt reconciliation and release recovery

Accepted September 14, 2026. User requested closure of the launch-readiness gaps.

## Purchase review
Receipt review automatically finds canonical-ingredient purchases within seven civil days of the reviewed receipt date, including missing/different merchants. This is a conservative warning, not proof that two purchases are identical. The user must select an unlinked recorded purchase or explicitly confirm a new purchase. An existing expense/receipt is visibly identified and cannot be linked again as a new expense. A different scan is not assumed to be a different physical purchase. Older receipts require the correct receipt date; this is not general fuzzy receipt identity detection.

The repository repeats matching/ownership/selection checks before one local transaction. Linking reuses the original PurchaseEntry UUID, moves it into the receipt group, attaches its expense/optional line total and saves an optional receiptLineKey. Stock quantity, Low stock, consumed status and expiry remain untouched. New receipt lines follow normal reviewed restocking. An unrelated pending shopping item is not completed when linking historical evidence. Replays remain detectable after the original shopping record is deleted, via PurchaseEntry's optional key. No past inventory balances are automatically repaired.

## Schema and privacy
PurchaseEntry.receiptLineKey is a nullable string; existing SwiftData stores migrate additively. BackupCodec validates and includes it in existing private/shared CloudKit payloads. No new server record type, public database, network LLM, permission or photo/OCR retention. Existing clients must upgrade together so older edits cannot omit the new key. A frozen build-46 PurchaseEntry schema is used in an actual on-disk migration test, separate from legacy-payload and backup tests.

A bundled PrivacyInfo.xcprivacy declares app-local UserDefaults access (CA92.1) and no tracking. This is a required-reason declaration, not a replacement for App Store Connect privacy disclosures or the privacy-policy URL. The code audit found no third-party runtime SDK or additional direct required-reason API category. Source: [Apple required reason API documentation](https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api) and its NSPrivacyAccessedAPIType approved-reasons table.

## Recovery and notifications
If the persistent store cannot open, the app presents an explicit recovery screen. It never deletes/replaces the original store or exposes a temporary empty household. Background sync is disabled in this state. An in-memory container exists only to support the recovery scene. Reopening retries the original store. Task assignment summaries now clear when any previously pending task disappears, matching shopping-summary behavior.

## Sync and release scope
Existing three-way conflicts keep both local and remote versions until explicit review; stock quantities are not automatically summed across offline devices. Conflict review now displays pantry flags/dates and expense amounts as well as quantities. Automated tests cover simultaneous restocks, persistent conflict review, sequential shared purchase/receipt linking, retries and record replay. Real CloudKit/APNs, Siri voice invocation and permission prompts remain separate physical-device checks. Synthetic tests must never imply those checks passed.
