# ADR 037 — device-local, one-way Apple Calendar links

Status: accepted for the user's explicit LunaHearth → Apple Calendar request.

## Behavior
The appointment editor offers an optional Apple Calendar toggle and explicit writable-calendar selection. Full EventKit event access is requested only when connecting; write-only access cannot read/update existing events. Denial leaves the core local workflow available. A selected destination is saved atomically with the appointment(s), before EventKit work. Repeats remain independent records with one export link per occurrence.

LunaHearth owns the linked event's title, start/end, and notes. Apple-side edits do not flow back; a subsequent LunaHearth edit updates those fields again. Apple alarms and location are preserved. Calendar/person settings do not automatically enroll other appointments or other devices. Use one exporting device per Apple calendar to avoid concurrent cross-device exports. Existing unlinked manual copies are not automatically adopted.

## Durable local outbox
CalendarDeliveryLink is a new device-local SwiftData entity, excluded from BackupCodec and CloudKit. It contains the source IDs, selected calendar, external identifier, private recovery dates, last sent revision, attempt/error state, and a configuration token. No change to the shared FamilyEvent schema is needed. Local-first saves do not await EventKit. The coordinator retries after local writes, foreground sync, and the existing background sharing callback; explicit Retry is available in Calendar settings. iOS background execution and Apple account synchronization timing are not guaranteed.

A stable URL marker identifies the app-created copy. Lost identifiers can be recovered by matching that marker within the selected calendar and bounded original/current date windows. An attempted but unacknowledged create is never blindly recreated if lookup fails. Missing, moved, recurring, ambiguous, or unrelated events require review instead of creating or changing another event. Persisted attempts precede external writes; acknowledgement carries the source revision so later edits remain pending.

## Deletion and disconnect
Local deletion offers keeping the Apple copy or explicitly removing both. Apple removal is queued independently from the household tombstone and targets only the verified app-owned copy on this device. Remote household deletions retain the Apple copy for local review rather than silently deleting it. Calendar settings show orphaned/failed links and provide explicit remove-copy, pause, and forget-link actions. Forgetting retains the Apple copy and warns to review it before re-exporting. No global Apple calendar cleanup is performed.

## Privacy and capability
The EventKit adapter is behind CalendarDeliveryService; views do not import EventKit or contain authorization logic. Only the selected appointment fields leave LunaHearth for the user-selected Apple calendar. This calendar may itself be shared or backed by an account provider; that is the user's calendar choice. No new backend, runtime dependency, account, or network AI is introduced. The full-access usage description now explains updating selected appointments. API acknowledgement means saved to the device event store, not confirmation of Apple's server sync.

References:
- https://developer.apple.com/documentation/eventkit/accessing-the-event-store
- https://developer.apple.com/documentation/eventkit/ekcalendaritem/calendaritemidentifier
