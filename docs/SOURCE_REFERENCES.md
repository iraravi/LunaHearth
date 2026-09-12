# Source References

Checked: **2026-09-11**

These are authoritative references agents should consult before implementing SDK-sensitive behavior. Do not rely solely on remembered API names when current Xcode documentation is available.

## Apple

### CloudKit sharing
- CKShare: https://developer.apple.com/documentation/cloudkit/ckshare
- Sharing CloudKit data with other iCloud users: https://developer.apple.com/documentation/cloudkit/sharing-cloudkit-data-with-other-icloud-users
- UICloudSharingController: https://developer.apple.com/documentation/uikit/uicloudsharingcontroller

### RoomPlan
- Documentation: https://developer.apple.com/documentation/roomplan
- Overview: https://developer.apple.com/augmented-reality/roomplan/

### Apple Intelligence / Foundation Models
- Apple Intelligence for developers: https://developer.apple.com/apple-intelligence/
- Foundation Models: https://developer.apple.com/documentation/foundationmodels
- WWDC26 Apple Intelligence guide: https://developer.apple.com/wwdc26/guides/apple-intelligence/
- WWDC26 iOS guide: https://developer.apple.com/wwdc26/guides/ios/

### System integration
- EventKit: https://developer.apple.com/documentation/eventkit
- WidgetKit interactive widgets: https://developer.apple.com/documentation/widgetkit/adding-interactivity-to-widgets-and-live-activities
- App Intents: https://developer.apple.com/documentation/appintents
- Vision: https://developer.apple.com/documentation/vision

## Important implementation note: SwiftData + shared CloudKit

Apple DTS discussion in 2026 cautioned against casually combining SwiftData's underlying CloudKit mirroring stack with a separate Core Data/CloudKit sharing stack, and suggested considering direct CloudKit APIs when shared data is simple. The repository therefore intentionally uses SwiftData locally and explicit CloudKit sharing/sync as a separate adapter.

Reference:
https://developer.apple.com/forums/thread/825496

This is an engineering reference, not a permanent guarantee. Re-check current Apple documentation before implementing Phase 5.

## OpenAI Codex workflow

- Codex project instructions / AGENTS.md guidance: https://help.openai.com/en/articles/11369540
- Codex use cases, including iOS and simulator/XcodeBuildMCP examples: https://developers.openai.com/codex/use-cases

Codex tooling is development tooling only. LunaHearth itself does not depend on OpenAI services at runtime.
