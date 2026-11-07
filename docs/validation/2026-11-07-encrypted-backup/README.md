# Encrypted portable backup validation — 2026-11-07

Branch: `codex/encrypted-portable-backup`. New `.nlbackup` export/import; no distribution or changes to uploaded build 72.

## Automated checks

- `xcodegen generate`: passed.
- Simulator build: passed, using Xcode at `/Applications/Xcode.app` and `/tmp/NamIllamBackup` DerivedData.
- All Swift Testing unit tests: **300 tests in 57 suites passed**. XCTest grocery search performance test also passed.
- New UI tests passed: password/confirmation gating, Files export presentation/cancellation, password clearing, restore entry on an empty installation.
- Inspected attached dark export, light restore, and system Files picker screenshots. Secure text contents are hidden by the system in screenshots.
- An initial UI run encountered a simulator event-synthesis timeout. After restarting, the new tests passed; the older iCloud regression needed its existing scroll/reveal helper because the added file-backup section moved status below the viewport. Its final rerun is recorded below.
- `git diff --check`: passed.

Target: available iPhone 18 Pro simulator, iOS 27.2, UUID `45A49484-C4E5-46DA-B35E-9F9009A64117`; the requested iPhone 17 Pro simulator was unavailable.

Logs: `/tmp/namillam-backup-build.log`, `/tmp/namillam-backup-final.log`, `/tmp/namillam-backup-regression.log`. The combined unit/new-UI run's result bundle is `/tmp/NamIllamBackup/Logs/Test/Run-LunaHearth-2026.11.07_17-51-06--0600.xcresult`; that combined invocation failed only the older UI check before the reveal correction. Do not report that entire invocation as passing.

## Covered behavior

Standard crypto interoperability fixture generated independently in Python; wrong password; fresh salt/nonce; authenticated header/ciphertext/tag; unsupported format/work factor; truncated/oversized input; record and document/room-file round trip; preserved IDs and document hashes; local-only restore; existing-home refusal; malformed attachment metadata, missing files, traversal and symlinks. No live iCloud credentials or network calls required.

## Remaining release gates

Physical-device Files save/reopen/restore with attachment-bearing homes, airplane mode, full iCloud, low device storage, long/Unicode passwords and cancellation. Simulator UI tests exercise the save picker and cancel, not a physical device-to-device transfer. The complete content round trip is covered below the UI through local persistence and filesystem tests.

Maximum encrypted file 96 MB; attachments 32 MB total. Forgotten passwords are not recoverable. Restore requires an empty installation. Android implementation remains future work; the public versioned format and fixture are ready for it. Review export-compliance answers before distributing a new signed build containing this encryption feature.

## Final regression result

The rebuilt app and `testSetupRestoreAndCloudUnavailableKeepLocalHome` passed with zero failures after using the existing scroll/reveal helper; xcodebuild exited 0 with `TEST SUCCEEDED`. Result: `/tmp/NamIllamBackup/Logs/Test/Run-LunaHearth-2026.11.07_17-55-24--0600.xcresult`. This rebuild includes the final post-commit restore-reload recovery message.

Nonfatal observations: Xcode's simulator diagnostic collector could not find `simctl` through the host's default CommandLineTools selection despite the explicit build `DEVELOPER_DIR`; tests still completed. The existing setup flow emitted an invalid-frame runtime warning while entering the home name. This validation does not claim a warning-free app-wide review or a full UI-suite run.
