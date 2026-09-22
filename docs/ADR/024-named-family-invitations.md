# ADR-024: Admin-named family invitations

Accepted product direction, September 13, 2026: the home owner chooses the name
used in the app, such as Kira, while inviting the person's iCloud account. Joining
selects that profile automatically; no recipient-side profile creation is needed.

## Implementation and privacy

More → iCloud & sharing → Invite family asks for the owner's display name, the
recipient's display name and their iCloud email. Apple resolves that explicit
address through CKContainer.shareParticipant(forEmailAddress:). Unresolved accounts
are rejected with a visible retry message; we do not guess a profile from names.
The email stays in form state, is sent only to Apple, and is not in a member payload.
No contact discovery, public database, login, or new third-party transport.

A household-scoped SHA-256-derived UUID binds the resolved container user record
name to a HouseholdMember. Raw Apple account identifiers are not profile data.
This narrowly extends the DATA_MODEL guidance: an opaque scoped identifier links
a profile, while CKShare remains the sole access-control authority. Profiles and
roles never grant cloud access. No ownership semantics change.

Names are committed locally and uploaded before adding the recipient to the
private share. ShareLink lets the owner send the prepared link. Existing accepted
participants can use this same flow to receive an admin-named profile on next sync.
Repeated invites update that account's display name with stable assignment IDs.
Equal display names are not identity matches. Existing manually created adult or
child profiles are preserved independently; no destructive name-based merge.
An existing owner profile is reused. Renames propagate through ordinary sync.

The receiving account selects its matching local member after initial import and
subsequent sync, replacing the device chooser with its linked profile. Refreshing
an unchanged link preserves notification preferences and delivered-item baselines.
Notifications still require explicit permission and opt-in. Offline local names
survive failed preparation; retry reuses them. A failed/cancelled send can leave an
intended profile present but does not imply acceptance. Revocation preserves local
records through the existing recovery handling. Two-device link acceptance and
Apple account identity mapping still require physical verification.

## Storage and compatibility

No SwiftData or CloudKit schema change; existing HouseholdMember payloads and
backup rules apply. A pending profile is an ordinary assignable household member,
not evidence the person has accepted or can access the home. Generic Apple sharing
remains available under Manage shared access, but does not guess admin names.

## Validation

Tests cover named first import, task assignment, automatic device selection,
notification preference preservation, rename and reinvite idempotence, distinct
accounts with equal names, and an offline upload followed by successful retry.

Build 11 verification: simulator build and 130 unit tests passed. The iPhone named
invite UI test passed, including validation and a visible retry error. The initial
iPad test used the wrong tab-bar selector; the corrected test reached the form but
stalled in simulator keyboard/accessibility automation and was stopped. iPad
visual/keyboard verification remains open. The final keyboard-dismissal adjustment
compiled in the signed device build. Build 11 installed on both physical devices;
iPhone launch succeeded, iPad launch was blocked by its lock screen. Production
CloudKit entitlement verified; direct provisioning uses development APNs. Live
recipient lookup/profile matching and notification delivery are not yet confirmed.
