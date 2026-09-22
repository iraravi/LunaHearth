# Release hardening — build 47

## Code fixes
- Receipt review detects recent matching purchased items and requires an explicit existing/new purchase decision. Linking reuses historical stock action and adds the expense once; stock is not added again.
- Receipt replay keys survive shopping deletion, local migration and backup/CloudKit transport.
- Task notifications clear a stale summary after one task completes while others remain.
- Storage-open failure shows recovery guidance without deleting data, opening a replacement home or running background sync.
- Sync conflict review includes pantry flags/dates and expense amounts.
- App-local UserDefaults usage is declared in the bundled privacy manifest.
- Receipt title and the unmeasured-unit label are shortened to avoid large-text truncation. Scan/Add move into pantry content at accessibility sizes so native toolbar overflow does not obscure them.

## Repeatable automated gate
Run `scripts/release-check.sh` on a Mac with Xcode and XcodeGen. It discovers an iPhone and iPad simulator, runs the domain/persistence/sync tests once, then eight critical UI flows on each device. Results/logs are saved to a unique `/tmp/LunaHearthRelease-*` folder (override RELEASE_RESULTS_DIR). Tests use synthetic local stores and fake integrations; they do not need iCloud credentials or alter the real household.

The separate SystemCalendarIntegrationTests opt-in test exercises the actual EventKit adapter with its own temporary **local simulator calendar**. Set `TEST_RUNNER_RUN_SYSTEM_CALENDAR_TESTS=1` when selecting that suite; the simulator must already have Calendar access for the host app. It is excluded from the normal suite. RUN_SYSTEM_CALENDAR_DENIED_TESTS similarly opts into the revoked-access check on a simulator with Calendar permission denied. Pre-granted simulator access does not validate the permission prompt or personal Apple account syncing.

## Physical release gate — still required
1. On the unlocked owner iPad and participant iPhone, use a clearly named temporary test home. Verify one purchase and a linked receipt arrive once, with identical stock and expense total.
2. Edit different items offline, reconnect and verify both. Edit the same stock record offline and confirm visible conflict review retains both versions. Quantities do not automatically add across conflicting records; the user must review the actual balance.
3. Opt into notifications on the receiving device. With it backgrounded, assign an item, observe the banner, purchase the item and verify the pending list/old summary update after sync.
4. Use an explicitly selected Apple test calendar: create, edit and delete an exported appointment; verify denied permission leaves LunaHearth usable. Invoke Siri by voice and confirm its draft before saving.
5. Check VoiceOver reading order and actions, minimum supported iOS 18, light/dark mode and iPad split-window resizing. Automated large-text checks alone are not a full VoiceOver audit.
6. Confirm App Store Connect metadata, screenshots, privacy disclosures, support/privacy URLs and the selected distribution build before submitting. No public submission was authorized or performed by this hardening task.

No passing simulator or mocked-server test should be reported as live CloudKit, APNs, real-device permission, Siri voice or App Store review verification. Device lock state currently prevents those checks; direct installation is separate from successful launch.

Final run evidence is recorded in TESTFLIGHT_RELEASE.md.

## App Store Connect audit — September 14, 2026
Authenticated and inspected the existing LunaHearth distribution draft. Version 1.0 is **Prepare for Submission**. The visible iPhone 6.5-inch screenshot slot has zero screenshots; description, keywords, support URL, copyright and review contact fields are blank. No distribution build is selected. The draft incorrectly defaults to sign-in required, although LunaHearth has no app login. App Privacy has no privacy-policy URL and its questionnaire has not been started. These are observed incomplete fields, not an Apple rejection. No listing changes or submission were made.

The current app build is 0.1.0 (47); the distribution draft is 1.0. Align the release version before uploading/selecting a public candidate. Public support/privacy hosting and publisher details need confirmation before completing those fields. Keep accessibility claims limited to capabilities actually verified.

Minimum-version execution remains unverified: Xcode's download catalog rejected iOS 18.0 (arm64 and universal) and iOS 18.5 (arm64) as unavailable. Installed simulator checks ran on iOS 27. This does not justify raising the iOS 18 deployment target or claiming runtime compatibility passed.
