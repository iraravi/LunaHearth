# Open into planning validation

Today now uses one measured panel layout: attention and Schedule appear side by side at 850 points or wider, and stack below that threshold or at accessibility text sizes. Existing selection and sheet state remain in the same view tree. A short smooth transition follows layout changes; system Reduce Motion disables it. Stable section identifiers support scroll-position continuity. No new persistence, permissions, network access or hinge detection.

- XcodeGen and simulator build passed.
- 271 Swift tests in 51 suites plus the existing performance XCTest passed: `/tmp/luna-planning.log`.
- Final measured-panel implementation built successfully: `/tmp/luna-planning-ipad-retry.log`.
- iPad rotation UI test passed: `/tmp/luna-planning-clean.log`.
- Duo rotation UI test passed: `/tmp/luna-planning-duo-clean.log`.
- Both UI tests select Restock, rotate, verify selection, open Quick Add, rotate back, verify the form remains open, cancel, and verify selection again.
- Reviewed the iPad rendered layout: `/tmp/luna-planning-ipad.png`.
- Initial stack implementation encountered a snapshot timeout; replaced with explicitly measured panel widths. Later interaction assertions completed but screenshot-attached runs stalled at teardown. Removing screenshot attachments and explicitly terminating the fixture app produced clean passes on both simulators.
- `git diff --check` passed.

Physical folding, animation smoothness and VoiceOver focus continuity remain device checks. Rotation exercises window geometry, not a hinge signal. These changes are not included in the already distributed TestFlight build 65.
