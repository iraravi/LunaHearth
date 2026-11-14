# Duo Home workspace review — 30 October 2026

Home now uses two scrollable panes at widths of 650 points or more, unless accessibility text is selected. Left: pantry, shopping, reminders, receipts, meals, expenses, purchases, care and setup. Right: household/floor, saved-room cutaway, rotation, room creation, floor plan and room details. It uses the supplied reference image for composition, with the existing Nam Illam palette and real household data.

Validation:
- XcodeGen generation and simulator build passed.
- Both HomeWorkspaceLayout unit tests passed (width boundary, accessibility fallback, invalid geometry).
- Light and dark open-Duo UI walkthroughs passed: empty state, room creation, editor across orientation changes, 3D drag rotation, receipt access and pantry navigation.
- The first two Duo UI attempts failed because Device Hub was in Closed mode. Changing orientation does not open Duo. Selecting Open in Device Hub resolved that setup error; both tests then passed.
- Open-Duo XCTest screenshot attachments were black despite successful interactions. They are not visual evidence. Inspected Device Hub live instead: light empty dashboard, dark empty dashboard, dark room editor, dark saved-room dashboard. Independently closed and reopened the simulator with the room editor open, then saved successfully.
- Compact iPhone Home room/item/warranty/maintenance walkthrough passed. Additional large-text inventory regression is recorded in release STATUS.

Evidence: /tmp/namillam-duo-build.log; /tmp/namillam-duo-workspace.xcresult (initial closed-mode failure plus passing unit tests); /tmp/namillam-duo-open-workspace.xcresult (two passing UI tests); /tmp/namillam-home-compact-regression.xcresult.

No schema, permissions, networking, cloud or business-logic changes. Test-created preview home was isolated in the app's UI-testing in-memory store. Existing simulator household data was not modified. Physical Duo posture transitions, VoiceOver and real-device performance are not established by these checks. Not yet distributed to TestFlight.
