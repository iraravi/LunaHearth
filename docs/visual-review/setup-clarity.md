# First-time setup instruction clarification — September 26, 2026

User feedback: instructions are unclear; preserve the current app design and navigation.

The welcome screen explains what a home contains and distinguishes creating a new home, joining via an invitation, and restoring a saved iCloud backup. The primary action now says “Create a new home.” Naming is presented as the sole required creation step, not step one of a seven-step requirement. The name field explains its purpose, examples, and what happens after creation. The post-creation checklist explicitly labels subsequent activities optional.

Presentation only. No domain entities, persistence, CloudKit, permissions, or sharing semantics change. Creation remains local and offline. Existing accessibility identifiers are preserved; the home name field has an explicit label and hint. Existing fonts, photography, colors and Dynamic Type behavior remain.

Validation: build and unit tests recorded in /tmp/luna-setup-clarity.log. Physical-device and visual accessibility review not yet performed. Not uploaded to TestFlight.

Validation completed: simulator build succeeded, 252 Swift Testing tests in 48 suites passed, and the existing performance XCTest passed. Final copy-only adjustment rebuilt successfully in /tmp/luna-setup-final-build.log. No UI automation or visual device review was claimed.

Local fresh-start action: More → Privacy & data → Clear household data → Delete local homes & start over. Requires typed DELETE. Removes local household records and active selection; refuses reset when any sync configuration exists. Shared cloud deletion retains the existing CloudKit-owner guard; no admin/delegated-delete authorization exists yet and no selectable family profile grants it. Local reset does not delete Apple Calendar/Reminders or private cloud backups. Cleanup tests cover an empty local store after reset and rejection of connected-home reset. Build and targeted cleanup tests passed in /tmp/luna-reset.log.

At the user's request, the LunaHearth app alone was uninstalled/reinstalled on the iPhone Duo simulator to reset its app sandbox. Physical devices and cloud data were not reset.
