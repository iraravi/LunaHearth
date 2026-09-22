# ADR-013: User-controlled private cloud deletion

Status: Accepted by user request on September 12, 2026 to add an option to delete private cloud data. This authorizes the feature, not executing deletion on the user’s behalf.

## Scope and privacy

More → iCloud & sharing offers owners a confirmed Delete this home from iCloud action. It permanently deletes only that household’s custom private zone and its share. Participants cannot delete an owner’s cloud home. Local household entities are preserved. Other devices retain their existing recovery copies when access disappears; the app does not promise remote erasure. Manual snapshots and Apple Reminders are separate.

More → iCloud backup offers a separately confirmed Delete private iCloud backups action, available even before home creation. It removes the current Apple Account’s LunaHearth manual snapshot zones and catalog, including older unreferenced generations. It does not touch live household zones, shared databases, other apps or local records. Concurrent backups from another device can create new snapshots after deletion.

Both operations use existing optional CloudKit integration; no new network destination, identity model or schema migration is introduced. Zone deletion is permanent, and the confirmation states its scope before any request. No destructive cloud operation is executed automatically during testing or installation.

## Failure and offline behavior

The household sync configuration is durably disabled and enters recovery before the network call. Failed or uncertain deletions leave it paused across app relaunch, with a visible retry option. Discovery cannot resume a paused configuration; enabling sync is only allowed without a configuration. After acknowledged deletion, only local sync metadata/baselines are cleared, preserving the home and making it editable locally. A future explicit enable may create a new cloud copy. The automatic worker never recreates a missing zone.

Account binding and owner/zone validation are checked before deleting. Missing zones are treated as an idempotent success. Partial backup deletion reports that snapshots may remain and permits retry; restore preview and last-backup metadata clear only as appropriate. Local records survive all failures. No user content is logged.

## Verification

Fake-server tests cover offline deletion failure, durable pause/reopen, successful retry, preserved groceries, no automatic re-upload, and rejection of participant deletion. A UI test covers backup deletion confirmation, cancellation and unavailable iCloud without losing the local home. Live deletion is intentionally not run against the user’s data.

Reference: [Apple deleteRecordZone(withID:)](https://developer.apple.com/documentation/cloudkit/ckdatabase/deleterecordzone(withid:))
