# Two-device household test

Use the same TestFlight build on both devices. The intended setup is iPhone on ravi.dorairaj@icloud.com and iPad on ravidorairaj@icloud.com. TestFlight access does not share household data by itself.

1. On the iPhone, create one fresh home and add two profiles, Ravi and Ravi Home, in More > Family.
2. In More > iCloud & sharing, enable private sync and invite the iPad account using Apple's sharing screen. Accept on the iPad and open the shared home. Do not create a second unrelated home as the participant.
3. On each device, open Today > For you and select the matching profile. Enable task alerts and shopping alerts separately, and allow notifications when prompted.
4. After both devices have synced, create a task and a shopping item on the iPhone and assign them to Ravi Home. Verify both arrive on the iPad. Complete them there and verify completion on the iPhone.
5. Repeat in the opposite direction with the Ravi profile. Background the recipient app normally; do not force quit. Check Notification Center as well as For you.
6. Edit an existing item's title and verify no repeat assignment alert. Reassign away and back after syncing each change; verify a new alert. Complete and reopen after syncing each step; verify the reopened assignment returns.
7. Test airplane-mode creation, then reconnect and verify eventual delivery without duplicate records.

Alerts are generated after sync and background delivery is best effort under iOS. Task assignment alerts are not timed due-date reminders. If a banner is absent, check notification permission, Focus, the selected profile, and last sync. Foreground Sync now distinguishes sync issues from delayed background notification delivery.

## Clean start

Permanent cleanup requires explicit confirmation. Deleting or reinstalling the app alone does not delete CloudKit records. The owner can delete each synced home in More > iCloud & sharing. Delete separate manual snapshots in More > iCloud backup. Only after cloud deletion is confirmed, remove local copies on both devices by deleting the app and reinstalling from TestFlight. Other apps' data and Apple Reminders are outside this cleanup.

## Current evidence

Build 8: 122 unit tests passed, including separate task opt-in, historical baselines, member filtering, durable deduplication, reopening and denial. Task-detail completion and existing personal-shopping purchase UI flows passed. Signed Release archive succeeded. Physical cross-account acceptance and APNs delivery have not yet been verified. No account data has been erased.

Build 8 is now Testing in the internal LunaHearth Beta group. Both requested iCloud accounts are listed; the iPad tester still needs to accept its invitation. Device Hub control timed out, so live cross-account testing and permanent cleanup remain outstanding.
