# Running private iCloud backup and restore

The app includes the CloudKit adapter and entitlement for `iCloud.com.neuralluna.lunahearth`. The repository leaves `DEVELOPMENT_TEAM` blank because no signing team has been selected for this project. Unsigned builds and automated UI tests show an unavailable message without constructing a CloudKit container.

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
