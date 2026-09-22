# ADR 026: Native Apple invitations and account-linked home profiles

Status: Accepted for the requested native-sharing fix, 2026-09-13.

## Problem
The user confirmed Apple's Mail/Messages share flow works while custom email lookup rejects the recipient before creating a profile. Apple-managed invitation delivery must not depend on an app-side lookup returning a user record ID in advance.

## Decision
Family opens UICloudSharingController directly. After verified writable cloud sync/import, each device ensures a single HouseholdMember for its current account, using the existing household-scoped deterministic ID. The existing owner profile and existing named account-linked profiles are reused. Owners without a profile start as Home owner; participants start as Family member. No Apple contact name or email is used for the display name. The owner renames profiles in Family after they appear. The shared record ID remains stable, preserving assignments.

The profile is created locally and uploaded through the existing merge/write path. A failed first upload after successful joining retains the local profile for retry. Removed profiles with existing sync baselines are not silently resurrected. Read-only or recovery homes do not create profiles. There are no schema changes or new permissions. Raw account IDs and email addresses are not added to member records.

One Apple Account represents one person per home; multiple devices on that account reuse the profile. People without devices can still have explicitly created local/shared profiles; these are not automatically matched by name to incoming participants. A profile is not proof of invitation delivery or access: Apple manages access and acceptance status.

## Validation
Use service fakes to test native invitation without email discovery, automatic join/profile upload, owner rename sync, assignment stability, two devices sharing an account, and participant rename restrictions. Live Mail delivery and acceptance remain device verification steps, separate from automated tests.
