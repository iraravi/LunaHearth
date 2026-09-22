# ADR-010: Selected Apple lists for shopping and reminders

Status: Accepted by explicit user request. Extends ADR-009 to new shopping items.

## Product and domain

Apple Reminders owns new shopping items and reminders. Setup explains this before requesting permission. Each feature has two choices: create a standard list (LunaHearth Shopping or LunaHearth Reminders) in a reviewed account, or browse existing lists and confirm Use this list. One destination is remembered per feature. The same list can be intentionally selected for both, in which case both screens display those same records. Switching destinations never moves or deletes content.

ReminderPurpose describes the connection role; ReminderScope provides deterministic All, Today (including overdue), and Upcoming filtering with civil-day handling. Shopping shows all unchecked items, including those without dates. Both workspaces offer completed items. Today reads selected lists independently so dashboard reads do not replace a workspace's filter.

Quick Add grocery creation and maintenance replacement shopping entry now save directly to EventKit. Quantity is an Apple reminder note. New shopping content is never inserted into GroceryItem or the household backup. Existing local groceries remain in a clearly labeled recovery section, without silent deletion or migration. Other household domains are unchanged. No schema change is introduced; the shopping list identifier is a device preference.

## Sync, privacy, and offline behavior

Writes are restricted to selected lists and require current write access. Only selected-list content is fetched. Apple manages account synchronization and existing list participants. No extra backend, SDK, household-content transmission, or automatic invitation is added. Save failures preserve the open draft and do not create a local fallback. Offline operation depends on the system Reminders store; remote propagation is not guaranteed while offline. Revocation/disconnect clears transient display values. Dashboard fetches do not alter list filter state.

## Sharing capability and limitation

The public EventKit API and EKCalendar SDK interface provide no list invitation or participant-management API. LunaHearth therefore provides an in-app How to share guide showing the selected list/account. The guide explains the invitation steps in Apple Reminders and the iCloud/Apple Account requirement. It does not claim an invitation was sent or expose a fake collaboration share sheet. A user-initiated link opens Apple's public help page; no household information is included in the URL. No undocumented Reminders deep link or private API is used.

References:
- https://support.apple.com/105124
- https://support.apple.com/guide/iphone/iph2a8f9121e/ios
- https://developer.apple.com/documentation/eventkit/ekcalendar

## Validation

Unit tests cover independent persistent selections, unrelated-list exclusion, disconnect clearing, selected-destination writes, and DST/date-boundary filters. UI fixtures cover existing-list confirmation, standard-list creation, Apple-only shopping/reminder creation, completion and sharing instructions without using a live account. Existing Home tests cover replacement drafts without local fallback when disconnected. Actual iCloud list creation, invitation acceptance, and provider propagation remain physical-device acceptance checks.
