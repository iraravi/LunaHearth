# ADR 036 — appointments, local alerts, and Siri review

Status: accepted for the user-requested Calendar and Siri feature.

FamilyEvent gains optional appointmentKind and reminderMinutes fields. Existing records decode as generic appointments with no alert. BackupCodec carries the optional fields through the existing explicit private/shared CloudKit transport. SwiftData remains local-first with additive optional properties; no destructive migration or automatic CloudKit mirroring is introduced.

Repeated plans are explicitly bounded (up to 52 occurrences, custom interval 1–30 days/weeks/months). The preview and save use Calendar arithmetic in the device time zone, anchored to the original start and end, preserving civil times across DST where representable. Month ends clamp to the available day. Saved occurrences are independent records; editing/deleting one does not mutate the others. No infinite series engine is implied. Saving validates the entire batch before one transaction. Member/household references and edit modification timestamps are checked. Overlaps involving the same member or household-wide appointments require explicit user confirmation.

Appointment reminder timing is shared; notification authorization and recipient selection remain device-local. A coordinator passes only IDs and trigger dates to a UserNotifications adapter behind a domain protocol. Notifications have generic lock-screen text. Only the selected member's and unassigned household appointments are scheduled. The adapter reserves room for other features, queues at most 24 future appointment alerts, and reconciles edits/deletions/reassignment after local changes, foreground sync, and an existing sharing push callback. iOS delivery and background execution are not guaranteed; users must open the app to fetch changes when background sync is unavailable. Notification taps open the existing event in the active household or show an unavailable state. Device choices are not authentication or changes to CloudKit membership.

Siri integration uses Apple's App Intents and AppShortcutsProvider. Explicit user invocation can open a draft with title, start, and optional person name, or show a date's calendar. It requires device authentication. The intent never writes the store directly. URL inputs are bounded and date-validated; the normal editor validates again. Exact unique member-name matches preselect a person; ambiguous/missing matches require review in the editor. The create flow always requires Save. No household database, documents, or photos are sent to a network AI service. Siri voice processing follows Apple's system settings; it is not represented as entirely on-device.

No new proprietary account, app-operated network service, runtime dependency, health tracking domain, or financial tracking domain is introduced. Doctor is a user-chosen calendar icon, not a health record schema.

Reference: https://developer.apple.com/documentation/appintents/appintent
