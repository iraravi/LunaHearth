# ADR-008: Opt-in household task delivery to Apple Reminders

Status: Accepted for the user's request to send newly created LunaHearth tasks automatically to Apple Reminders. Supersedes ADR-007's manual-only scope for explicitly enrolled tasks. Manual copies remain available for older tasks.

## Behavior and domain

HouseholdTask stays the local source of truth. More → Connections → Reminders lets a user connect, choose a writable destination, and enable Sync new tasks. Enabling does not export existing tasks. New tasks are saved atomically with device-local ReminderDeliveryLink records. Subsequent title, civil due-day and completion changes update the same Apple reminder. This is one-way; Apple edits/completion do not modify household tasks. The next local task change overwrites those mapped Apple fields. Other Apple fields are left alone.

Disabling pauses enrolled tasks and leaves new tasks local-only. Re-enabling resumes existing links in their original lists; a new destination applies only to newly enrolled tasks. Disconnect in Connections also persists the disabled setting. Deleting a local task or stopping its sync retires only the local link, never deletes an Apple reminder. An already executing write may finish after disabling. Deleted/moved Apple reminders are not automatically recreated: restore the original reminder/link or stop syncing the task in its details.

## Local-first delivery and recovery

ReminderDeliveryService is a Domain protocol, implemented by the EventKit adapter. The MainActor coordinator runs after local commits, on launch/foreground and explicit Sync now. No background execution or remote delivery guarantee is made. EventKit saves into the system store; Apple manages subsequent account synchronization. Permission is never requested by the worker. Failure leaves tasks and outbox links local, with a 60-second per-revision retry backoff; Sync now bypasses the delay. Local edits are new eligible revisions.

Acknowledgements refer to the exact sent task revision, preserving edits made during an await. A stable task URL recovers an EventKit write whose local acknowledgement was lost. A failed fetch is never treated as an empty destination; ambiguous matches fail closed. Existing identifiers must still resolve in the original writable list with the expected task URL. A serialization guard prevents concurrent writes of the same task in the shared service instance.

## Schema and privacy review

Two additive, device-local SwiftData tables store opt-in/destination and delivery metadata. Existing entities are unchanged. CloudKit's explicit backup allowlist excludes both tables; restore never re-enables outbound writes. No destructive migration or new dependency is introduced. The existing model-container initialization failure limitation remains unchanged. Tests exercise upgrading a legacy on-disk schema and reopening pending work.

Titles, due days, completion and task UUID links are disclosed only after destination selection plus explicit opt-in. The destination may use iCloud, a system-configured provider or a shared list, and its existing participants may see those fields; the UI explains this before enabling. No assignees, household documents, private notes, credentials or unrelated content are sent. No raw provider errors or household content are logged. Status stores controlled, content-free errors. Source selection for viewing and destination consent for writing are separate controls. Removing view selection does not disable an already approved write destination.

## Validation

Unit tests cover future-only enrollment, local durability/reopen, additive migration, delivery failure/backoff/retry, same-ID updates, completion, stale acknowledgements, disconnect/pause, local unlink/deletion and backup isolation. A UI test uses an isolated in-memory service to connect/select/enable, create a task, and see it in the connected reminder list without accessing a real account.

Live Apple permission grant/revocation, iCloud/shared-list propagation, device-lock transitions and account removal still require physical-device acceptance testing. This feature does not claim two-way sync or guaranteed deduplication across independent devices.
