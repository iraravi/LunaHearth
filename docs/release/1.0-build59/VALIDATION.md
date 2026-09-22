# Build 59 — App-wide ivory design

September 16, 2026. Presentation-only update; no domain, storage, schema or sync changes. Existing installations upgraded in place without deleting data.

## Validation

- XcodeGen regenerated the project; simulator and signed Release builds succeeded.
- 240 unit tests across 44 suites passed.
- iPhone UI tests passed: main-screen screenshots, More navigation, real pantry meal flow, and dark/large-text shopping forms. Main screenshots were rerun after final style adjustments.
- iPad UI tests passed: main-screen screenshots, large-text calendar, expenses, More, shopping and inventory.
- Visually inspected captured phone main screens, meals and More; iPad Home and shopping at normal and accessibility text sizes; dark large-text phone form.
- Shared light-theme sage, clay, slate, plum and muted text color contrast against ivory exceeds 5.6:1. This is a palette check, not a complete accessibility audit.
- Test runners emit an auxiliary simctl lookup warning because system xcode-select points at CommandLineTools; xcodebuild runs with explicit DEVELOPER_DIR and all listed tests passed.

## Installation

Signed 1.0 (59) installed successfully on Ravi's iPad and Ravi's iPhone using devicectl. iPhone launched successfully. iPad launch was blocked by its lock screen; installation succeeded and the user can unlock and open LunaHearth. No physical-device visual or VoiceOver audit claimed.

## Evidence

- /tmp/luna-ivory-phone.log and Run-LunaHearth-2026.09.16_18-51-23--0500.xcresult
- /tmp/luna-ivory-ipad.log and Run-LunaHearth-2026.09.16_18-53-39--0500.xcresult
- /tmp/luna59-final-simulator.log and Run-LunaHearth-2026.09.16_18-58-28--0500.xcresult
- /tmp/luna59-device.log
- /tmp/luna59-ipad-install.log and /tmp/luna59-iphone-install.log
- Screenshots and artwork provenance: docs/visual-review/ivory-app/
- Design decision: docs/ADR/047-app-wide-ivory-design.md
