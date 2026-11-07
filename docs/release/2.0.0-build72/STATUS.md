# Internal TestFlight 2.0.0 (72)

Prepared November 6, 2026 on `codex/v2-duo-redesign`, source `cd06a95` (navigation fixes `edba061`). Build 71 remains available; an already uploaded build cannot be replaced.

- Navigation validation: final simulator build, 295 Swift Testing tests, grocery performance XCTest, and nine targeted navigation UI checks passed. See `docs/validation/2026-11-06-navigation.md` for scope and the corrected obsolete warranty test.
- Signed Release archive succeeded. Archive metadata verified version 2.0.0/build 72 and strict code-signature verification passed.
- Archive: `/tmp/NamIllam-2.0.0-Build72.xcarchive`.
- App Store Connect upload succeeded (`EXPORT SUCCEEDED`). Logs: `/tmp/namillam-build72-archive.log`, `/tmp/namillam-build72-upload.log`.
- Apple processing completed. Assigned build 2.0.0 (72) to the existing LunaHearth Beta internal group and verified its status is Testing, expires in 90 days. Group shows 4 testers and 17 builds. Tester device installation is not yet verified.

Internal testing only. No external beta review or public App Store submission requested or performed for this build.

## Public release request — November 7, 2026

User authorized submission of 2.0.0 (72) for public App Store review and release. Prepared updated description, What's New and review notes in `app-store/`; these are local drafts and have not been saved to App Store Connect. The Distribution page redirected to sign-in with `authResult=FAILED`. User sign-in is required to continue creating/updating the public version, checking screenshots, selecting build 72 and submitting. No public submission has been made. Intended release setting: automatic after approval.

### Signed-in continuation

Created the public 2.0.0 version at `/apps/6811447245/distribution/ios/version/inflight`, selected build 72 (not 71), and saved it. Automatic release after approval is selected, with immediate release to all users and existing ratings retained. Six iPhone medium-display and six iPad 13-inch screenshots carried over; the Duo slot is empty. Screenshot content still needs validation against v2 before submission.

Native coordinate interaction failed with `noWindowsAvailable`; AX clicks work but text replacement via paste/setValue did not change the fields. User asked to unlock the Mac and bring Safari forward. The new description, What's New and reviewer notes remain local drafts. No Add for Review or Submit for Review action performed.

### Metadata saved and screenshot capture — November 7

Saved the updated public description, What’s New and reviewer notes in App Store Connect and verified the field values. Version remains Prepare for Submission, with build 72 attached. No review submission has occurred.

Captured six fresh screenshots each on iPhone 18 Pro (1206 × 2622), iPad Pro 13-inch M5 (2064 × 2752), and iPhone Duo (1398 × 2034), using the existing testAppStoreScreenshots UI test and fictional Maple House data. All three capture tests passed. Reviewed all 18 images; files in screenshots/ are unchanged simulator captures. Result bundles: /tmp/namillam-build72-store/{iphone,ipad,duo}.xcresult.

Upload is still pending. Safari native pointer input reports noWindowsAvailable; the upload picker ignores keyboard navigation despite text entry having recovered temporarily. Closed the picker without removing the existing screenshots. The inherited screenshots must be replaced and all Media Manager sizes checked before Add for Review and final submission. No claims that these new screenshots are already uploaded.

### Uploaded assets, Apple processing blocker — November 7

On the next live inspection, App Store Connect contained six screenshots each for iPhone medium display, Duo, and iPad 13-inch (18 total). The rendered iPad Today/Home/Calendar/Expenses thumbnails matched the fresh v2 captures. Some thumbnails remained processing, so final visual verification of every remote image remains pending. Media Manager showed large Dynamic Island iPhone and older 12.9-inch iPad using existing assets rather than separate overrides.

Reconfirmed build 72 and automatic release after approval. Clicked Add for Review twice, separated by a processing wait. Apple refused with: “Unable to Add for Review … 1 or more screenshots must finish processing.” Version remains Prepare for Submission. No final Submit for Review action or public release occurred. Next step: allow Apple image processing to finish, verify remaining previews, retry Add for Review and finish submission.
