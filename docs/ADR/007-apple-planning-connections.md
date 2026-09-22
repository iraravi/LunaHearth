# ADR-007: Explicit Apple Calendar, Reminders and Notes sharing

Status: Accepted for the requested Apple-service integration.

## Scope

More → Connections configures optional Calendar and Reminders access. Calendar also links to these controls, and Lists links to connected Apple Reminders. Five root tabs remain unchanged. Core local household features still require no system authorization.

Calendar reads only individually selected calendars for the chosen day. Each calendar defaults to Hidden and offers Busy only or Event titles. Private event notes/attendees/locations are not copied. Results exist only in presentation memory; neither SwiftData nor CloudKit backups receive external events. Calendar account sources can include providers configured in Apple's Calendar settings; LunaHearth does not add provider OAuth or network clients.

Reminders reads only selected lists and lets users explicitly complete/reopen writable reminders in Apple Reminders. These are separate from local household tasks, not imported or silently merged. A household task's context menu or details can create a reviewed copy in a chosen writable list. Stable task URLs prevent repeated export into the same list and open the local task when available. Due dates export as civil day components without an invented clock time. Completion and subsequent edits are not synchronized between copies.

A LunaHearth event offers Add a copy to Apple Calendar using Apple's EventKitUI editor. The user reviews destination, dates and content before saving. On iOS 18 this editor requires no calendar-library read permission. Repeated explicit exports create independent copies; there is no claim of continuous synchronization.

Notes sharing uses a temporary reviewed text draft and Apple's share sheet, which can offer Notes, Mail, Messages and other installed destinations. It does not access the Notes database or claim bidirectional Notes sync. Event details can prefill the draft; entry context menus share only the selected entry's title and available notes. Nothing is sent until the user completes the system destination's action. Notes availability depends on the installed apps/system configuration.

## Architecture and persistence

`ApplePlanningService` and immutable Sendable values live in Domain. `CalendarIntegrationService` owns the lazy EventKit store and authorization logic in Services. The EventKitUI wrapper is also in Services. `AppleConnections` is a MainActor presentation coordinator with injected service/preferences for testing. Source IDs, opt-in flags and per-source visibility choices are device preferences, excluded from household backups. No SwiftData schema changes or runtime packages are introduced.

Disconnect immediately clears presented data and invalidates in-flight reads. Foregrounding also invalidates old reads before views refresh. Permission revocation/fetch errors clear external data and expose retry/Settings guidance. Disconnecting within LunaHearth is distinct from revoking Apple's system permission; the screen explains how to do both. Local household records are never deleted by these operations.

## Privacy and threat review

- Calendar/Reminders authorization is requested only after the user taps Connect (or Connect within an explicit reminder-export flow), never during setup or app launch.
- Full calendar read access is necessary for selective overlays. All source visibility starts Hidden; no nil/empty predicate is allowed to mean all sources. Calendar export alone uses the lower-access Apple editor.
- Reminders requires Apple's full-access authorization. UI selections still constrain which lists are displayed. Completion is a deliberate action against a writable selected list.
- Copies into calendars/reminder lists can reach the account provider and participants already sharing that destination. The reminder export screen explains this; the Calendar editor lets users choose/review the destination. These are explicit system-mediated writes, not automatic household-content uploads.
- Notes/Mail/Messages sharing is user-completed through Apple's UI, not an automatic send action. No connector credentials or message APIs are added.
- No personal calendar/reminder content, access tokens or account identifiers are logged. External content is not included in cloud backups.
- Imported deep links are checked for scheme, host and UUID route. They can only open an existing task from the currently loaded local household; they cannot create, change or delete records.
- Delayed reads after disconnect/source changes are discarded using request identities. Permission-denied and restricted states preserve local operation.

## Validation and live checks

Offline tests use a fake provider and isolated device preferences. They cover explicit opt-in, per-calendar visibility, stale-read suppression, revocation, list scoping, guarded writes, backup isolation, date-only export and deep-link validation. UI tests keep live EventKit disabled and verify the unavailable path plus Notes draft entry.

Before release, use a physical device to verify allow/deny/revoke for both services, local and iCloud/shared lists, Calendar export save/cancel, Reminders export/retry, links back to existing/missing tasks, account removal, recurring/all-day events, calendar sources disappearing, and Notes availability. Actual provider synchronization follows Apple/system account behavior; the app does not guarantee remote delivery offline.

Apple references:
- https://developer.apple.com/documentation/eventkit/accessing-the-event-store
- https://developer.apple.com/documentation/eventkit/ekeventstore/requestfullaccesstoevents(completion:)
- https://developer.apple.com/documentation/uikit/collaborating-and-sharing-copies-of-your-data
