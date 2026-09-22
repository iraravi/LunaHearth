# Version 1.0 (58) — refined welcome and setup

September 16, 2026. Scope: welcome walkthrough, home creation, setup guide and More hero photograph. Existing household data, progress, iCloud sharing and AI behavior remain unchanged. Generated artwork is bundled; there is no runtime network generation. Design, assets and exact prompts: `docs/visual-review/premium-welcome/ART_DIRECTION.md`.

## Validation

- Simulator build passed. Five setup-progress domain tests passed (`/tmp/luna-premium-ipad.log`).
- iPhone setup with large text/dark appearance, home creation → offline shopping, walkthrough completion/relaunch and replay passed (`/tmp/luna-premium-phone.log`).
- iPad welcome/relaunch and replay passed (`/tmp/luna-premium-ipad.log`).
- Screenshot review exposed a transient overlapping text animation and narrow Continue button at accessibility sizes. Text now changes immediately; accessibility controls use a separate full-width action row.
- Final accessibility dark-mode walkthrough passed on iPhone (`/tmp/luna-premium-accessibility-final.log`) and iPad (`/tmp/luna-premium-accessibility-pad-final.log`). Final normal walkthrough also passed on iPhone (`/tmp/luna-premium-final2-phone.log`).
- Screenshots inspected: regular phone welcome, regular iPad welcome, final accessibility phone receipt. Captures in `docs/visual-review/premium-welcome/`.
- Palette contrast on canvas: light primary 13.32:1; light secondary 5.60:1; light accent 6.15:1; dark secondary 9.22:1. Physical-device VoiceOver and Reduce Motion manual checks are not claimed.

## Delivery

Signed Release build passed (`/tmp/luna58-device-release.log`); built Info.plist confirms version 58. Installed directly on Ravi’s iPad and Ravi’s iPhone with devicectl. No uninstall, reset or household-data deletion. Open More → How it works to replay; prior reviewed/skip preference remains preserved. Physical-device launch/visual review was not performed for this build. No TestFlight or App Store upload.
