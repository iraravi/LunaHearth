# ADR 022: Task assignment alerts

Status: Implemented; physical delivery validation pending.

HouseholdTask assignments now appear in Today > For you alongside shopping. A separate explicit opt-in enables task assignment alerts on this device. Existing shopping permission does not automatically opt users into task alerts. The selected household member remains a device-local display preference, not identity or access control.

Task alerts reuse the existing private/shared CloudKit change subscription and foreground sync. Notification text includes only the number of new tasks. No schema, backend, sharing boundary, or new permission type is introduced. Local UUID baselines prevent repeated alerts on relaunch or title edits; completion/reassignment removes an active assignment and reopening can alert again. Historical tasks are baselined when enabling or selecting a person. Task and shopping alert preferences remain independent.

Tapping either alert opens For you. Assignment alerts are not timed due-date reminders. Background pushes are best effort and do not prove instantaneous delivery; foreground sync is the fallback. Tasks and chores remain available offline.

Validation covers opt-in isolation, historical baselines, filtering, completion/reopen, durable deduplication and permission denial. Real cross-account APNs behavior requires testing on both signed-in physical devices.
