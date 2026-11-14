# India App Store distribution preparation

Prepared October 3, 2026. This is a release preparation package, not a submitted or approved public release.

## Confirmed scope

- User chose **India only** on October 3. Availability must explicitly select India and leave all other territories, including automatic future-territory expansion, off.
- Current reference binary: LunaHearth **1.0 (66)**, bundle `com.neuralluna.lunahearth`. Both TestFlight groups were verified Testing on October 1.
- Public pricing is not confirmed. No price, subscription, paid agreement or tax decision has been made.
- Prepare for iPhone and iPad. Recommend manual release after review; this is a draft setting until applied and verified in App Store Connect.
- No household schema, identity, networking or app behavior changes are made by this preparation task. Tests and screenshots use fictional in-memory households.

## Prepared materials

| Material | Location | State |
|---|---|---|
| Store text and structured fields | metadata/listing-copy.txt, metadata/en-US.json | Draft; length checked |
| Reviewer walkthrough | metadata/review-notes.txt | Draft; no login required |
| Privacy/support website | website/privacy.html, website/support.html | Unpublished; contact and policy approval required |
| FAQ and product guide | website/help-and-faq.html, website/product-guide.html | Copied from current guides; release status updated |
| Current screenshots | screenshots/iphone-6.9, screenshots/ipad-13 | Capture/verification results in validation/DISTRIBUTION_CHECKS.md |
| Candidate identity | validation/candidate.json | Archive and executable fingerprint |
| Privacy questionnaire worksheet | metadata/privacy-review.md | Evidence and open answers, not submitted declarations |

## Must resolve before public submission

1. Confirm legal operator/copyright holder, public support/privacy contact, private Apple review contact and pricing. An account display name alone does not confirm the legal publisher details.
2. Finalize the privacy policy with actual support handling/retention, effective date and publisher facts. Host approved policy and support pages on stable public HTTPS URLs with working contact information. Verify the live URLs without authentication.
3. Update More → Privacy & data → Privacy policy to the approved text and public link. **Build 66 includes an explicit draft notice, so it is not the final public binary.** Increment the build after this code change, validate, upload, then select that final candidate in Distribution.
4. Complete the live App Store Connect privacy and age-rating questionnaires from implemented capabilities and actual publisher practices. Review rights/content ownership and any applicable account agreements. Do not infer these declarations from passing tests.
5. Complete the outstanding physical acceptance checks: two-account production CloudKit sharing and offline/conflict recovery, notification delivery, real Calendar/Reminders allow/deny behavior, spoken Siri, VoiceOver, and minimum supported iOS 18. See docs/RELEASE_READINESS.md. Prior TestFlight installation does not prove these checks passed.
6. Sign in to App Store Connect, inspect current fields, apply India-only availability, confirm pricing, add the reviewed listing and screenshots, turn reviewer sign-in requirement off, and choose manual release. Check iPhone/iPad-on-Mac and Vision Pro distribution separately; those platforms are not verified by iPhone/iPad simulator tests.
7. Review the complete final submission package with the publisher before submitting the public version. The present request is preparation; no Submit for Review or Release action has been performed.

## App Store Connect observation

October 3: the distribution URL redirected to sign-in. User sign-in was requested. Current metadata, availability, pricing and selected public build could not yet be verified. The September 14 blank-field audit is historical and must not be treated as current evidence.

## Sources checked October 3

- [Apple submission process](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app)
- [Apple review preparation: support and privacy links](https://developer.apple.com/app-store/review/)
- [App privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
- [Country availability](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-for-your-app-on-the-app-store)
