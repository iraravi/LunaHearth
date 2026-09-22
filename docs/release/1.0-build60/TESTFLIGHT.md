# TestFlight deployment — September 21, 2026

Requested deployment of current 1.0 (60).

- Regenerated project with XcodeGen.
- 240 unit tests in 44 suites passed on iPhone simulator.
- Release archive succeeded using Xcode 27.1.
- Upload attempted with automatic signing and the existing team, 647V74N5JV.
- Apple rejected export/upload: "Failed to Use Accounts. App Store Connect access for 647V74N5JV is required. Ensure that your Apple Account usernames and passwords are correct in Accounts settings."
- No successful upload; processing and tester availability unverified.
- User asked to reauthenticate the existing account in Xcode Settings → Accounts. Retry prepared archive upload after login.

Archive: /Users/ira/Library/Developer/Xcode/Archives/2026-09-21/LunaHearth 1.0 (60).xcarchive

Logs: /tmp/luna60-testflight-archive.log, /tmp/luna60-testflight-tests.log, /tmp/luna60-testflight-upload.log.

Upload options: /tmp/LunaHearth60-Upload.plist. Does not change production App Store release, data, permissions or tester membership.

## Retry succeeded — September 21, 2026, 16:39 CDT

After the user renewed Xcode's account, the same archived 1.0 (60) uploaded successfully. Xcode reported "Uploaded package is processing", "Upload succeeded", and "EXPORT SUCCEEDED". No rebuild or version change was needed.

Log: /tmp/luna60-testflight-upload-retry.log.

Apple processing completion and tester-group availability are not yet verified. The App Store Connect browser still requires sign-in; successful binary upload is not evidence of tester availability. No public App Store submission was performed.

## Tester access resolved — September 21, 2026

Signed-in App Store Connect showed upload processing Complete, build Ready to Submit, and no assigned groups. Added existing LunaHearth Beta internal group (3 testers), added existing Ravi Home external group (1 tester), entered build-specific What to Test notes, and submitted for external beta review with automatic tester notification enabled. Verified status Waiting for Review and both group associations persisted.

Internal tester page includes both Ravi iCloud addresses. Apple reports ravi.dorairaj@icloud.com Installed 1.0 (60); ravidorairaj@icloud.com still shows Installed 0.1.0 (8). No new testers or account permissions added. External approval remains pending; no public App Store submission.
