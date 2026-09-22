# More navigation cleanup

More has four primary destinations: Family, Apple connections, Preferences, and Privacy & data. The existing adaptive two-column layout and large-text stacking remain.

Privacy & data contains live iCloud sync/recovery, snapshot backups, and the existing confirmed household data-clearing flow. Preferences contains warranty alerts and the optional app tour. The unfinished Documents placeholder is removed. Connections is no longer repeated inside the privacy page.

This is a navigation-only change: no household entities, schema, stored records, sync behavior or permission requests change. It remains usable offline; Apple integration destinations retain their existing unavailable/error handling. Removing entries does not delete user data.

Validation: focused More navigation and large-text UI checks on iPhone and iPad simulators; see the task result for outcomes. Existing backup/sync/data-clearing/tour UI tests now use the nested routes. The separate proposal to remove the Lists root tab is not part of this change.

Final validation passed: `/tmp/LunaMoreCompactFinal.xcresult` contains both navigation and accessibility-large-text tests passing on iPhone 18 Pro and iPad Pro simulators (four cases). Normal-size screenshots were inspected and saved in `docs/visual-review/More-Clean-iPhone.png` and `More-Clean-iPad.png`. No business logic changed, so no new domain tests were added.

## Build 48 follow-up
The user confirmed the Lists root tab should disappear; see ADR-041. Apple Connections, Preferences and Privacy & Data now share a tinted background, compact symbol header and rounded content cards. iPad content width is bounded and text remains vertically flexible for Dynamic Type. Permission requests, disconnect actions, sync and data-clearing behavior are unchanged. The device-settings link now uses device-neutral wording.

Build 48 validation: `Luna48Navigation.xcresult` passed all six selected cases across iPhone/iPad (four tabs, Home reminders/meals, More navigation and large text). After refining heading contrast and hiding decorative headers at accessibility sizes, `Luna48FinalSettings.xcresult` passed all four selected More navigation/large-text cases. Screenshots were inspected for the new Preferences, Privacy and Connections layouts. These tests check navigation/rendering, not live Apple account synchronization.
