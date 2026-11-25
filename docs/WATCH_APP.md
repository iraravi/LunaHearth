# Apple Watch app (3.0)

Companion app for watchOS 11+. It needs the iPhone app and never works on its own data.

## What it does

- **Shopping**: open items grouped by aisle in store-walk order (produce, dairy, meat, grains, dals, spices, essentials, other); items bought today stay at the bottom so a mistaken tick can be undone.
- **Today**: open tasks due today or overdue, plus ones finished today.
- **Add**: dictate or type. The iPhone splits the words (`WatchSnapshotRules.dictatedList`, then `QuickCaptureRules.parse`) and saves shopping items, tasks, plans and expenses directly, like Siri does, because the words are the person's own. Shopping already on the list is skipped.
- **Widgets** (watch face and Smart Stack): items left to buy, next task. Circular, rectangular, inline and corner families.
- **Notification actions**: meal prep reminders have Mark done and Snooze 10 min. They show on the watch automatically.

## How it syncs

WatchConnectivity only; no CloudKit, no network, no schema change.

| Direction | Channel | Content |
|---|---|---|
| iPhone → watch | `updateApplicationContext` (latest only) | `WatchSnapshot`: home name, shopping items, today's tasks, IDs of watch actions already saved |
| watch → iPhone | `sendMessage` when reachable, else `transferUserInfo` (queued) | `WatchAction`: set bought, set done, add text |

- The iPhone is the source of truth (`PhoneWatchConnector`). It sends a snapshot after every saved change, on foreground, after an iCloud refresh and when the watch state changes.
- Actions state the end result ("bought", "done"), so a repeat delivery changes nothing. Adds are remembered by action ID (last 100) so they are never saved twice.
- The watch (`WatchStore`) shows taps at once on top of the last snapshot and keeps them queued until a snapshot lists their IDs as saved. Pending actions survive relaunch.
- The watch saves the snapshot in one keychain item in the team group `647V74N5JV.com.neuralluna.lunahearth.watch`, which its widgets read. App Groups were not used because they can't be registered with the App Store Connect API key used for builds.
- While the iPhone store is in recovery mode the connector is not started, so the watch never writes into the temporary store.

## Code

- `Shared/WatchLink/WatchLink.swift`: snapshot, action, keychain store (compiled into the iPhone app, watch app and widgets).
- `LunaHearth/Domain/UseCases/WatchSnapshotRules.swift`: what goes into a snapshot; dictation splitting.
- `LunaHearth/Services/Watch/PhoneWatchConnector.swift`: iPhone end.
- `LunaHearthWatch/`: watch app. `LunaHearthWatchWidgets/`: widgets.
- Tests: `LunaHearthTests/WatchLinkTests.swift`.

## Testing on simulators

Use a paired iPhone and Watch simulator (`xcrun simctl list pairs`). Install the watch app only after the pair shows `connected`, or WatchConnectivity reports the counterpart app as not installed. Launch the watch app with `--watch-tasks` (debug builds) to open on the Today page for screenshots.
