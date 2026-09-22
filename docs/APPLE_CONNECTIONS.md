# Apple connections

> Current foundation (ADR-012): local household reminders, shopping, schedules and home records support optional private CloudKit sync and CKShare invitations. Foreground changes sync automatically; live two-account device acceptance is still a release check. Apple Reminders is a separate optional connection. Setup no longer asks for a room. Earlier Apple-only/manual-backup-only implementation notes below are historical. See [ADR-012](ADR/012-live-private-household-sharing.md).



## Shopping and Reminders

Apple Reminders is the source of truth for new shopping items and reminders. Open **Lists → Shopping** or **Lists → Reminders**, then connect when ready. Setup offers:

- **Create a standard list:** choose an existing writable list's account. LunaHearth creates LunaHearth Shopping or LunaHearth Reminders there, or reuses a writable list with that exact name in that account.
- **Browse existing lists:** select one, review its account, and confirm Use this list.

Only the chosen list's items appear in that feature. Each feature remembers its own list; deliberately selecting the same list for both shows the same records in both places. The list row changes this choice without moving data.

Tap **+** to add directly to Apple Reminders. Quantity is stored in the reminder's notes. Complete or reopen items using their circles. Shopping includes undated items. Reminders offers All, Today (including overdue), and Upcoming. Show completed reveals finished items. Pull to refresh after external changes. Quick Add and maintenance replacement entry use the selected destination too.

No new reminder/shopping content is written into household storage or backups. Existing local tasks and groceries remain accessible in labeled recovery sections. Apple handles synchronization; permission/provider failures do not create fallback local copies. With no usable account/list, set one up in Apple Reminders first.

## Share a list

The person-plus button opens **How to share**, showing the selected list and account. Open that list in Apple Reminders, tap Share, and invite people there. Collaborators need an Apple Account and iCloud Reminders. LunaHearth cannot create invitations or manage list participants through EventKit; existing shared-list changes use the same Apple records.

[Apple's sharing instructions](https://support.apple.com/105124)

## Calendar

More → Connections → Calendar offers individual calendar choices: hidden, busy only, or event titles. Selected calendar events are an optional overlay and are not copied into household backups. Household-owned events remain local. Event export uses Apple's reviewed editor.

## Notes and sharing

More → Connections → Share to Notes opens a temporary text draft. Apple's share sheet lets the user choose Notes or another destination. This does not read or synchronize the Notes library.
