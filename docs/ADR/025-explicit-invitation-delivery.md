# ADR-025: Explicit invitation delivery

September 13, 2026. Users reported no email after filling out the named invitation
form, and confusion when Family's management action navigated to technical settings.

## Decision

Preparation saves the named profile and private CKShare recipient, but is not
message delivery. Replace the success checkmark with an explicit not-sent state.
Continue to send opens Apple's composer immediately after successful preparation.
When Mail is configured, MessageUI prefills the provided recipient, household
subject and share link. The user reviews and presses Send. Otherwise present the
system activity sheet for Messages or another app. A secondary action permits
other apps when Mail is available. Cancelling preserves the URL for retry.

MessageUI completion is not delivery or acceptance: sent means handed to Mail,
a copied link still needs sending, and other activity completion asks the user
to verify in that app. No state claims a recipient received or accepted anything.
The recipient email remains ephemeral form/composer state, never a profile field.
Only an explicit UI action presents a composer; no silent email, external server,
new login, broad contacts access or background sending. Existing CloudKit recipient
permissions and acceptance remain authoritative. Paused sync blocks preparation.

Family remains the hub. For active sharing, Invitations & access presents Apple's
sharing controller directly, without a detour through the iCloud settings page.
Local homes can enable sharing here after the existing explicit upload consent.
Recovery/paused homes still link to connection repair. Names and private household
records use the existing offline and retry paths; no schema change or deletion.

## Validation scope

Normal unit tests require no live credentials. A debug-only in-memory fixture
exercises the prepared-state share sheet and cancellation, never sends a message.
Manual Mail sending, actual email arrival and recipient acceptance remain physical
account checks. Closing this UI doesn't revoke a prepared pending share; it can be
retried using the stable share URL and profile identity.

References:
- https://developer.apple.com/documentation/cloudkit/ckshare/url
- https://developer.apple.com/documentation/uikit/uicloudsharingcontroller
- https://developer.apple.com/documentation/messageui/mfmailcomposeviewcontroller
