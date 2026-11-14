# LunaHearth launch checklist

Updated October 14, 2026. Target: initial public iPhone/iPad release in India. **Not ready to submit yet.** A checked item needs evidence; a prepared draft is not a completed store setting. See the [October 14 UI/accessibility and copy review](validation/2026-10-14-final-review.md) for the latest changes and scoped verification.

## 1. Publisher decisions — owner

- [ ] Confirm legal publisher/copyright name and rights to the product name.
- [ ] Confirm public support/privacy email, private App Review contact and launch price (free or paid).
- [x] India-only launch requested. Applying and verifying this setting remains below.
- [ ] Approve final privacy policy, including effective date and actual support-data handling/retention.

## 2. Public pages and in-app policy — engineering + owner

- [x] FAQ, product guide, support/privacy page drafts and listing drafts prepared in `release/1.0-build66/`.
- [ ] Publish approved support/privacy pages at stable HTTPS URLs. Check both while signed out and test contact links.
- [ ] Replace `PrivacyPolicyView` draft notice/text with approved policy and public link; keep an offline copy.
- [ ] Check listing claims against actual features: Notes is a share-sheet export, AI is optional/on-device, and manual room entry is available.
- [ ] Review screenshots against the final candidate. Existing October 3 screenshots are draft assets; their sample currency is USD, not evidence of INR testing.

## 3. Code and security — engineering

- [x] October 4 review fixed ten confirmed defects. 276 Swift tests plus performance coverage passed; 114 distinct phone UI cases had passing evidence across runs, not one complete final-binary run.
- [x] October 9 starting source hashes match that reviewed snapshot. Existing uncommitted work preserved.
- [x] October 9 build, 276 Swift tests plus performance test, Release analysis and three selected launch-flow UI checks passed; see `validation/2026-10-09-launch-review.md`. Test concurrency/assertion warnings fixed; runtime warning remains below.
- [ ] Resolve or document the setup-keyboard SwiftUI invalid-frame runtime warning with device/SDK evidence. Do not label it fixed based on successful navigation alone.
- [ ] Run actual Sonar analysis and inspect bugs, vulnerabilities and security hotspots; resolve or explicitly review findings and save the quality-gate result. Local heuristic checks are not Sonar. Project URL and secure authentication still needed.
- [ ] Freeze the reviewed source for the release candidate; preserve a commit and binary fingerprint so testing and uploaded code can be matched.

## 4. Physical acceptance — engineering + device testers

Record device, OS, build, steps and outcome for each. Simulated Apple adapters do not complete these checks.

- [ ] Minimum iOS 18 and a current supported OS: install, cold launch, upgrade without data loss and offline relaunch.
- [ ] Create home → floor/room → item → warranty/maintenance; verify 2D movement and 3D rotation on a real device, iPhone/iPad navigation and rotation.
- [ ] Airplane mode: create/edit shopping, pantry, meals and household appointments; relaunch and confirm persistence; reconnect without duplication.
- [ ] India locale/time zone: INR amount entry/totals, receipt review, date-only meals and appointment times; confirm dates survive travel/time-zone changes.
- [ ] CloudKit Production with two Apple accounts: owner invite, participant accept/edit, offline conflicts, revoked access and account change. Preserve local data on failures. Test private backup/restore separately from live sharing.
- [ ] Public configuration: ordinary account can read but cannot create/write `LHAppConfiguration`; device fetch and expired/offline fallback work. September 26 Console evidence exists; verify current production state. The documented revision expires October 20, so check the intended launch policy before then.
- [ ] Calendar/Reminders: allow, deny and revoke permissions; select destination; add/edit/complete; verify Apple-side results and retries without duplicates.
- [ ] Notifications: real delivery, tap routing, opt-out and completed/deleted records; test remote household updates separately.
- [ ] Camera/Photos deny/allow, receipt extraction and pantry scan; cancel without partial saves; unavailable AI retains manual workflows.
- [ ] Spoken Siri, VoiceOver, large text, Reduce Motion, dark mode and contrast; inspect actual screens rather than relying on UI automation alone.

## 5. Final binary and TestFlight — engineering

- [ ] After final policy/code changes, increment build above the latest uploaded number (66 is only the last recorded reference).
- [ ] Generate project, build/test final source, archive with distribution signing and validate. Inspect archive entitlements, production CloudKit/push settings, privacy manifest and version.
- [ ] Upload, verify processing, then assign intended existing TestFlight groups and verify tester availability/install. Upload success alone is insufficient.
- [ ] Smoke-test that exact installed candidate and retain archive/result evidence. Do not reuse old passing counts as final-candidate evidence after behavior changes.

## 6. App Store Connect and submission — owner + engineering

- [ ] Inspect current account agreements and app fields; current live state has not been verified by this checklist.
- [ ] Complete privacy declarations, age rating, content rights and export-compliance questions from actual behavior and publisher practices.
- [ ] Apply India-only availability, disable automatic future-territory expansion, and confirm pricing. Review Mac/Vision Pro availability separately if offered.
- [ ] Add approved description, keywords, categories, screenshots, support/privacy URLs and review contact.
- [ ] Provide reviewer steps for optional integrations; no LunaHearth login is required. Select the final processed build.
- [ ] Review the completed submission package with the publisher, submit for review, and track review feedback.
- [ ] After approval and release decision, verify the India storefront listing, installation and support links.

## Evidence and Apple references

- [October 4 code review](validation/2026-10-04-deep-release-review.md)
- [Prepared distribution packet](release/1.0-build66/DISTRIBUTION.md)
- [Public configuration production history](PUBLIC_APP_CONFIGURATION.md)
- Apple [review preparation](https://developer.apple.com/app-store/review/), [app privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy) and [submission process](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/), checked October 9.

There is no claim of zero vulnerabilities or Apple approval. This checklist separates verified code evidence from live-account, device and publisher requirements.
