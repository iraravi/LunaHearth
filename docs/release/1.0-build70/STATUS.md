# Nam Illam 1.0 (70)

Updated 6 November 2026.

- Installed Mac App Store Xcode: 27.2 (27B52); first-launch readiness check passed; iOS 27.2 SDK present.
- Scope: build number only. No feature, schema, permission, network or privacy changes from build 69.
- XcodeGen generation and simulator build passed.
- Unit tests: 292 Swift Testing tests in 53 suites passed. Result: `/tmp/namillam-build70-unit.xcresult`.
- UI regression tests: Home workspace light, receipt exact total with explicit inventory selection, and receipt review dark mode all passed. Result: `/tmp/namillam-build70-ui.xcresult`. Test output also emitted a simctl lookup warning after the cases; overall test command exited 0 with TEST SUCCEEDED. System xcode-select remains on CommandLineTools; builds explicitly use DEVELOPER_DIR.
- Release archive succeeded at `/tmp/NamIllam-1.0-70.xcarchive`. Code signature verification passed; archived DTXcodeBuild is 27B52 and CFBundleVersion is 70.
- CLI export initially failed because the new Xcode installation had no account. Owner signed into Xcode; Organizer then confirmed “LunaHearth 1.0 (70) uploaded.”
- App Store Connect finished processing build 70. Selected and saved 1.0 (70) for the public release; Add for Review validation succeeded with no remaining beta-SDK or screenshot-processing errors. Existing 18 screenshots were verified saved on 1 November.
- Public submission completed on 2 November 2026, approximately 09:51 America/Chicago. Apple displayed “1 Item Submitted” and version status **Waiting for Review**. Submission ID: `51c731ef-3db5-442b-be04-ceffc5e23285`. Automatic release after approval remains selected. Submission is not approval or proof of live App Store availability.
- Owner authorized acceptance of updated Apple Developer Program License Agreement. After attempted Agree action, account update banner and agreement modal were absent; acceptance-history date did not refresh. Subsequent public submission succeeded without an agreement blocker.

- TestFlight distribution verified on 2 November 2026: build 70 status **Testing**, assigned to **LunaHearth Beta** (4 internal testers) and **Ravi Home** (1 external tester). Build-specific testing notes saved; external beta Submit for Review completed with Automatically notify testers enabled. Public App Store review submission remains separate.

## Released baseline

- Apple review completed: version 1.0 (70) Approved; Ready for Distribution verified on 6 November 2026. US public listing opened successfully at https://apps.apple.com/us/app/nam-illam/id6811447245.
- Git release tag: `v1.0.0` (App Store version `1.0`, build `70`). Source baseline is build-69 implementation commit `e0c2833` plus the build-70 version change; no native source changes were present when the release baseline was recorded. This records source provenance; it is not a claim of a bit-for-bit reproducible signed archive.
- Screenshot evidence: `../1.0-build69/screenshots/manifest.json`; those 18 native captures were used for build 70 because its app behavior was unchanged.
