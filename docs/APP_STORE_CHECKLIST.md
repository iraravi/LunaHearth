# App Store Release Checklist

## Product
- [ ] Name/trademark clearance completed
- [ ] Original UI/copy/assets
- [ ] No competitor branding in metadata
- [ ] Minimum OS and device support accurate

## Privacy
- [ ] Public privacy-policy URL
- [ ] App Privacy questionnaire matches code
- [ ] No undisclosed SDK data collection
- [ ] iCloud wording distinguishes local vs synced mode
- [ ] Document/OCR behavior documented
- [ ] Delete/export behavior documented

## Permissions
- [ ] Calendar purpose string matches actual access
- [ ] Reminders purpose string matches actual access
- [ ] Camera requested only in scan flow
- [ ] Photos uses limited/system picker where possible
- [ ] Notification permission requested after value is clear

## Children/family
- [ ] App positioned as parent/household management unless Kids Category intentionally pursued
- [ ] No child login/account in MVP
- [ ] No public child profiles

## Payments
- [ ] StoreKit for digital premium features
- [ ] subscription terms and restore flow
- [ ] do not market fee as payment for iCloud storage

## CloudKit
- [ ] production schema deployed
- [ ] owner/participant test completed
- [ ] share revocation test completed
- [ ] iCloud unavailable behavior tested

## Quality
- [ ] crash-free critical flows
- [ ] offline test
- [ ] accessibility audit
- [ ] localization-ready strings
- [ ] support URL/contact
- [ ] reviewer notes explain optional iCloud and any hardware-dependent RoomPlan feature
