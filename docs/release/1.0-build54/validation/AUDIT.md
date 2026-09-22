# Candidate audit

## Fixes
- Pantry category selection could conceal a valid name-search match while the header reported matching items. Search edits now reset the category restriction; the UI regression selects Rice & grains before searching cumin and requires Jeera to be visible, Rice absent and a count of one.
- Release version mismatch: prior builds used 0.1.0 while the existing public App Store draft was 1.0. Candidate project version is now 1.0, build 54.

## Scope and privacy
Source review plus synthetic unit/persistence/sync and UI testing. Screenshot fixtures compile only in DEBUG and require explicit UI-test flags; their repository is in memory. They do not access or reset the user's household. No runtime dependencies, permissions, remote AI or data schema added. Existing uncommitted work is preserved.

## Pending evidence
Final test, screenshot and archive outcomes are appended below. Physical two-device sync, APNs, spoken Siri, permission prompts, VoiceOver and minimum-iOS execution remain outside automated evidence. Support/privacy hosting and App Store Connect answers are not completed by file generation.

## Additional audit findings
- iPad onboarding-to-Expenses test found utility destinations absent from the accessibility hierarchy even after Home reached the bottom. Replaced the three-item lazy utility grid with the existing eager measured card layout. Verification pending rerun below.
- Corrected singular Home task summary (one task).
- Large-text receipt automation could tap a partially visible purchase button beneath the modal navigation bar. Updated the test helper to scroll a hittable target fully below the visible navigation bar before tapping. This is an automation correction, not evidence of a persistence defect; outcome pending rerun.
- Initial gate: 237 unit tests across 44 suites passed; all eight selected iPhone flows passed. iPad passed six of eight; Expenses and large-text receipt are the failures above. Initial result bundles remain preserved rather than relabeled as successful.

## Verified reruns
- Pantry category/search regression passed on 6.9-inch iPhone (`/tmp/Luna54StorePhone.xcresult`).
- Both iPad failures passed after the changes: onboarding → Expenses monthly tracking and large-text receipt → existing purchase → original inventory quantity (`/tmp/Luna54PadRetest.xcresult`). The receipt test correction did not change receipt persistence code.
- Screenshot capture initially passed for all six iPhone destinations. Final captures were refreshed after the Home layout/copy changes; both device capture tests passed.

## Candidate archive
Final signed archive succeeded: `/Users/ira/Documents/Project/LunaHearth/ReleaseArtifacts/1.0-build54/LunaHearth-1.0-54.xcarchive`. Bundle version 54 and marketing version 1.0 verified. Bundled PrivacyInfo.xcprivacy passes plist validation. Screenshot fixture flag and fictional household string are absent from the Release executable. This does not validate App Store distribution export or processing.

Physical iPad installation of the final archive app succeeded after the user made it available. Existing household data was preserved; no synthetic fixtures are in Release. Launch result is recorded separately. No real two-account workflow is implied by installation.
The physical iPad automatic launch was denied because it locked again. Installation succeeded; interactive physical launch and workflow verification are not claimed.

## Final screenshot package
All 12 unretouched PNG captures validated: six iPhone images at 1320 × 2868 and six iPad images at 2064 × 2752, without alpha. Final result bundles: `/tmp/Luna54FinalCaptures/phone.xcresult` and `/tmp/Luna54FinalCaptures/ipad.xcresult`. See screenshots.json for per-image hashes and provenance.
