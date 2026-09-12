# Xcode Setup and Capabilities

## Required tools

- macOS
- current Xcode capable of building the chosen iOS SDK
- Apple Developer account for device/iCloud capability testing
- XcodeGen (`brew install xcodegen`) as repository project generator

No runtime Swift package is required for the MVP scaffold.

## Generate project

```bash
xcodegen generate
open LunaHearth.xcodeproj
```

## Signing

In Xcode:
- choose NeuralLuna/your developer team
- automatic signing is fine initially
- verify bundle ID availability

Current working bundle ID:
`com.neuralluna.lunahearth`

## iCloud capability

Planned container:
`iCloud.com.neuralluna.lunahearth`

Enable:
- iCloud
- CloudKit

Do **not** assume the container exists just because the entitlement file names it. Create/register it in the Apple Developer account and select it in Xcode.

## Capabilities NOT to enable yet

- Push Notifications — not required for local notifications
- Background Modes — do not enable until a justified sync use case is designed
- HealthKit
- HomeKit — the “Home” feature is LunaHearth data, not Apple Home automation in MVP
- Location
- Sign in with Apple
- Associated Domains
- App Groups — wait until Widget target needs shared storage and design it explicitly

## Permission strings

The scaffold includes purpose strings for Calendar, Reminders, Camera, and Photos. Presence of a purpose string does not authorize access; request permission only inside the relevant feature.

Prefer PhotosPicker/document picker when possible to reduce broad permission scope.

## CloudKit development vs production

Develop schema in CloudKit development environment. Before App Store release:
- verify record types/fields/indexes
- deploy schema to production
- test production-mode migration path
- never rely on development auto-created fields once release process starts

## RoomPlan

Requires supported hardware/features. Test on a physical compatible device. Simulator is not a substitute for scanning behavior.

## Foundation Models

Compile with a current SDK. Runtime availability depends on OS/device/model availability. Always gate the feature and preserve fallback UX.
