# 2.0.2 (92) — App Store submission

Public App Store build (Release configuration; no RECEIPT_DEBUG / internal receipt debug screen — verified absent in the archived binary). Same app changes as internal builds 87–91.

App Store Connect (November 19, 2026):
- Created version 2.0.2 from the live 2.0.1 (79) listing and attached build 92.
- Updated promotional text, description, What's New, keywords and App Review notes (text in docs/release/nam-illam-app-store/en-US.json).
- Screenshots replaced for 2.0.2 only (live 2.0.1 unchanged): iPhone (6.3" set 1206×2622 from 6.9" captures) — 6 new screens + 4 illustrated scenes; iPhone Duo — 6 new 1398×2034 screens + 4 scenes; iPad 13" — 6 new 2064×2752 screens. All with 9:41 status bar and fictional demo household. Files: docs/release/nam-illam-app-store/screenshots-2.0.2/.
- Release: automatically after approval, to all users immediately, keep existing rating.
- Availability unchanged: India, United States, Canada.
- Submitted for review at about 11:03 AM; status "Waiting for Review". Apple says review can take up to 48 hours.

Known open items: website privacy/legal pages still marked draft; support@neuralluna.com delivery not tested; Apple Watch screenshots need a watchOS app (planned for a later release).

Validation before submission: 440 unit tests passed; receipt UI tests and App Store screenshot UI tests passed on iPhone 18 Pro Max, iPad Pro 13" and iPhone Duo simulators.
