# ADR-009: Apple Reminders owns new reminder data

Status: Accepted by explicit user request. Supersedes ADR-007 and ADR-008 for reminders.

## Domain and storage

New task/reminder entry uses EventKit directly. Apple Reminders is the sole persistent store for new reminders; LunaHearth holds transient display values and an unsaved editor draft only. No new HouseholdTask, delivery link, outbox, or household CloudKit backup record is created by the reminder UI. Homes, maintenance plans, groceries, meals and household calendar events retain their existing storage. This is the user-authorized exception to the app's local SwiftData-first task workflow.

## Navigation and account choice

Lists → Reminders is the central workspace, also reachable from Today and Connections. Users grant access just in time, browse existing Apple lists, and select one active list. The list and its account are shown before saving. Users can create a standard LunaHearth list in the account of an explicitly chosen writable existing list. A matching writable LunaHearth list in that account is reused. EventKit lists are supported; Apple Reminders groups, smart lists and account provisioning are not exposed as app-created folders. If no usable lists exist, users set up Apple Reminders first.

## Privacy and failure behavior

EventKit writes to the system store. Apple manages provider synchronization and shared-list visibility; LunaHearth adds no network service. Permission denial, removed accounts, read-only lists and save failures must not create a local fallback task. Drafts stay in the open editor after a failed save. Offline availability depends on the system Reminders store; provider propagation may wait for connectivity. Only selected-list contents are fetched. Account/list identifiers are device preferences, not household records. No contents are logged.

## Existing data

The old automatic delivery worker is no longer invoked, so local edits cannot overwrite Apple reminders. Existing HouseholdTask and delivery tables remain intact for non-destructive compatibility. Existing tasks are reachable through an explicitly labeled recovery section in Reminders. They are not merged with the Apple list and no longer offer copy/export controls. Existing data is not silently deleted or moved; a reviewed migration can be added separately. Historical household backups can still contain these legacy tasks. No schema migration is introduced.

## Validation

Unit tests cover exclusive list selection, standard-list selection and failure retention, direct-write routing, and Apple-only links. A UI fixture exercises connect, select, direct create, and completion without real account access. Full simulator build and test outcomes are recorded in the task response. Actual provider/account permissions and list creation need device acceptance testing.
