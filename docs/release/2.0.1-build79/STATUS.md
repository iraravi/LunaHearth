# Nam Illam 2.0.1 (79) — candidate and media

Build 78 is verified Testing in LunaHearth Beta (4 internal testers, 23 builds). Build 79 archived and uploaded through Xcode Organizer using App Store Connect distribution on November 8, 2026. Tester assignment and public submission remain pending. Public 2.0.0 is unchanged; 2.0.1 remains a draft.

## Regular iPhone correction

Inventory no longer hides Virtual kitchen behind physical-hinge capability. Regular iPhones can open the full-screen Fridge and Pantry from Inventory, return to the list, and reopen. Separate transient phone presentation preserves the saved Duo preference and existing list-first phone navigation. No data model, network, permission, or household identity changes.

Validation: XcodeGen and build succeeded. 339 unit tests in 65 suites passed (`/tmp/NamIllam-phone-virtual-test.log`). Initial UI test failed because two accessibility elements shared the view-mode identifier across the presentation boundary; the selector was narrowed to the List view label. Retest passed (`/tmp/NamIllam-phone-virtual-ui-retest.log`). Actual preview walkthrough passed on iPhone 18 Pro, iPhone 18 Pro Max and iPad Pro 13-inch using candidate build 79.

## Media

12 unretouched PNG captures: entrance, whole home, fridge and pantry for each of those three device layouts. Original dimensions and SHA-256 hashes recorded in validation/*.json. App data is the fictional in-memory Maple House fixture.

Three silent H.264/AAC previews at 30 fps, Rec.709, natural 1x speed. Phone exports 886x1920; iPad 1200x1600. Source recordings are immutable. Timeline files record source ranges. Generated with preview/record.py, package.py, render.py and gallery.py using the local Python imageio-ffmpeg environment. Trimmed launch screens and idle intervals; no invented interface, retimed action, or unrelated marketing graphics.

A first export exposed an invalid inferred encoder frame rate and gray first frame. Explicit post-concat 30 fps and output 30 fps corrected it; rejected drafts are kept under preview/source/draft*. Final files were fully decoded for errors and sampled frame-by-frame at one-second intervals; continuous normal-speed playback is not yet verified. Do not call the package fully publication-ready until that review and App Store upload processing succeed.

## Pending

- Unlock Mac to capture Duo's physical fold/unfold states and watch all final previews normally.
- Capture Duo screenshots from its active display; inactive-display black frames are rejected.
- Review and upload approved assets, save release metadata, select the intended public-eligible build.
- Archive/upload candidate 79 if it is the chosen release build. No App Review submission performed.

## Duo capture completed

Mac access recovered. Installed binary verified as 2.0.1 (79). Captured six actual Duo screenshots on iOS 27.1: Home, Fridge and Pantry in closed and fully open states, using display 1 for the exterior and display 3 for the interior. Inspected the captures together: no inactive black screenshot was retained and closed fridge has no floating inventory overlays. Screenshot sizes are 1398x2034 closed and 2853x2007 open; alpha is fully opaque.

Preserved native recordings in preview/source/duo-entrance.mov and duo-interior.mov. The interior display powers off while folded, so final editing explicitly excludes those black intervals and cuts between real front/interior footage; it does not synthesize physical-device folding or invent transitional frames. Preview retains complete UI with neutral margins in the App Store landscape canvas. Public upload/submission and continuous normal-speed playback approval remain pending.

## Release upload — November 8, 2026

User authorized uploading all assets and publishing. Archive `/tmp/NamIllam-2.0.1-Build79.xcarchive` succeeded; archive metadata verified version 2.0.1 and build 79. CLI export failed with `Failed to Use Accounts`; Xcode Organizer then uploaded successfully using App Store Connect (not Internal Only). Organizer explicitly displayed `LunaHearth 2.0.1 (79) uploaded`.

Safari still cannot enter web text or complete file selection: coordinate input returns `noWindowsAvailable`; file picker shows selected PNG with Upload disabled. No new media or release notes have been saved to App Store Connect. Updated local metadata is in metadata/. Public submission has not occurred.

## Metadata saved

After the user unlocked the Mac, release highlights and reviewer notes were entered and Save completed in App Store Connect for 2.0.1. Notes identify build 79 and describe virtual Home/Fridge/Pantry behavior and fictional screenshot data. Input subsequently failed again before any media upload; the same disabled file-picker issue recurred.

## Partial media verification

Build 79 appeared in the normal TestFlight build table after processing. Safari subsequently displayed the Duo gallery at 10/10 screenshots: six existing Store-* files plus 05-Pantry-Closed.png, 04-Fridge-Open.png, 06-Pantry-Open.png, and 03-Fridge-Closed.png. Duo previews remained 0/3. New Home captures and remaining device assets are not yet verified uploaded. Safari inspection repeatedly timed out after reconnection, preventing completion. Build 79 has not yet been selected for the public draft, and no final App Review submission occurred.

## Build selected

After the user reported uploads complete, selected public-eligible build 79 (version 2.0.1) in the Add Build chooser and saved. The saved draft displays build 79 and automatic release after approval. Duo gallery now includes all six new closed/open Home, Fridge and Pantry screenshots plus three existing screenshots (9/10). Duo previews remain 0/3; do not claim videos uploaded. Add for Review initiated under existing publish authorization.

## Public App Review submitted — November 8, 2026

Selected and saved build 2.0.1 (79). Added for Review, verified draft item 2.0.1 (79), and clicked Submit for Review under the user’s prior publish authorization. App Store Connect confirmed `1 Item Submitted` and `2.0.1 Waiting for Review`. Submission ID: 338f9c49-3383-4dc0-bc8d-aa6786d2ed16. Automatic release after approval was selected. This is submission, not approval or public availability. User reported uploads complete; the Duo gallery was verified with all six new stills, but 0 previews, so do not report video publication.
