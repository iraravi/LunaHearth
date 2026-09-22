# Running private iCloud backup and restore

The app includes the CloudKit adapter and entitlement for `iCloud.com.neuralluna.lunahearth`. The selected Apple team is now preserved in `project.yml`. A signed device build succeeded and its provisioning profile includes the CloudKit container and the connected iPhone. Debug builds target the Development CloudKit environment; Release builds target Production. Automated UI tests still show an unavailable message without contacting live iCloud.

## Configure the authorized Apple team

1. Open the generated LunaHearth Xcode project and select the Apple Development Team that owns the container. Record that team's ID in `project.yml` under `settings.base.DEVELOPMENT_TEAM` so XcodeGen preserves the choice. Do not commit signing credentials or provisioning profiles.
2. In Signing & Capabilities, verify iCloud / CloudKit and the container `iCloud.com.neuralluna.lunahearth` are provisioned for `com.neuralluna.lunahearth` on that team. Regenerate the project after configuration changes.
3. Build for a device signed into iCloud. The existing `CloudKitDevelopmentTeam` Info.plist setting resolves from the build's team; it is an availability guard, not a credential or proof of correct provisioning.
4. Create a sample household, room, item, warranty and maintenance completion. From More → iCloud backup, confirm Save backup. Verify a success status before relying on it.
5. On a second device signed into the same Apple Account with an empty LunaHearth store, select Restore from iCloud on the welcome screen. Review and restore the backup; verify room geometry, item links, civil meal dates and maintenance history.

The CloudKit development schema uses `LHBackupManifest` and `LHBackupEntity`, created through a development build. Deploy the schema to the production environment before distributing a production build. No query indexes are needed by this implementation: catalog and entity records are fetched by record ID.

## Required live checks

Exercise no account, airplane mode, restricted account, insufficient iCloud quota, an interrupted multi-batch upload, concurrent backup attempts, and account switching. Failures must never replace the local store or advertise a partial snapshot as complete. A failed restore must leave onboarding available. The automated test suite verifies local round trips and unavailable-cloud UI; it does not use live iCloud credentials.

This feature is manual private backup/restore. It does not implement CKShare invitations, participant acceptance, automatic uploads or conflict merges for live collaboration. Refer to [ADR-006](adr/006-private-cloudkit-backup.md) for privacy, limits and deferred work.

Apple references: [CloudKit containers](https://developer.apple.com/documentation/cloudkit/ckcontainer), [iCloud capability configuration](https://help.apple.com/xcode/mac/current/en.lproj/devcae40ccb9.html).

User validation update: live private CloudKit backup was confirmed working on September 12. Cross-device restore, concurrency/failure cases and production deployment remain separate checks.

## Live household sharing

1. On the owner’s device, open More → iCloud & sharing → Enable private iCloud sync. Review the upload description and confirm.
2. After sync completes, choose Invite people / manage sharing. Use Apple’s UI to invite the intended Apple Account; public links are not enabled.
3. On the other device, open and accept the invitation, then Join shared home in LunaHearth. Any existing local home remains separate.
4. With both apps open, add a shopping item on one device and complete it on the other. Check each side after sync; edits also sync on foreground and through Sync now.
5. Verify offline/relaunch recovery and removal of a participant before release. Do not delete/reinstall either app to test this.

Both builds must use the same container and CloudKit environment. Development can create `LHHouseholdEntity` fields automatically; deploy its schema in CloudKit Console before using Production/TestFlight. `CKSharingSupported` is enabled. Existing iCloud container entitlements are reused; no new account, telemetry or background entitlement is added.

## Production schema deployed — September 12, 2026

During build 3 distribution, CloudKit Console confirmed “Changes Deployed” and
“The schema is deployed to Production.” Deployment included LHBackupEntity,
LHBackupManifest, LHHouseholdEntity, cloudkit.share and their indexes/default roles.
This resolves the earlier schema prerequisite. App household data still uses
owner-private and participant-shared databases; no public records were uploaded.
Physical two-account sync, restore and failure testing remain required.
