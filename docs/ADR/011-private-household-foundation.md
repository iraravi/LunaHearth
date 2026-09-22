# ADR-011: Private household foundation and optional Apple connections

Status: Accepted by explicit user direction, September 12, 2026. Supersedes ADR-009 and ADR-010 for the primary Lists, Today and Quick Add workflows; automatic delivery from ADR-008 remains retired.

## Decision and affected entities

LunaHearth is a personal or family command center. HouseholdTask and GroceryItem join FamilyEvent, MealPlanEntry, Room, HomeAsset, Warranty and MaintenancePlan in the local SwiftData household. All primary entry points save locally first. Today reads local tasks and groceries. These records enter the existing normalized, private CloudKit manual backup. CloudKit is optional transport, never the only working copy.

Personal/family setup controls initial local profiles and the default home name. It does not change ownership or create accounts/invitations. Both choices produce the same household model and allow adding members later. No schema change or destructive migration is needed. Empty optional member rows must be removed or completed before saving, consistent with existing validation.

Previous local records and Apple lists are preserved. No silent import, export, merge or deletion takes place. App launch disables old automatic reminder-delivery settings while preserving historical links. Optional Connections workspaces can still browse/create/complete items directly in a reviewed Apple list; they explicitly label that separate destination. Primary Quick Add never depends on Apple permission or writes to EventKit. Two-way mirroring and automatic export are not enabled.

## Setup and visual design

A residential hero image, rounded feature tiles and a short setup form take inspiration from Apple Home's visual hierarchy. The artwork is original. Setup offers personal/family, a home name, optional display name, first room, and family profiles. It shows local storage, optional private backup and actual AI/sharing availability without a permission wall. More → Welcome to LunaHearth revisits the introduction without modifying an existing household.

## Privacy and capability review

No new network service, entitlement or permission is introduced. The bundled generated illustration contains no household data and is loaded locally. Existing private backup remains explicit and manual. Live CKShare collaboration, pending-change transport, tombstones and conflict resolution remain future work under CLOUDKIT_SYNC.md. Documents/receipt import and AI extraction remain unimplemented; setup does not advertise these as available.

Apple's iOS 27 Foundation Models API offers Private Cloud Compute through a managed entitlement, supported hardware/region and daily limits. This is separate from CloudKit storage. No PCC request or entitlement is added. Any future activation requires eligibility approval, feature evaluation, explicit privacy review and a new ADR. On-device assistance should be implemented first behind the domain service with manual fallback and confirmation of proposals.

## Validation

Run local persistence/backup, retired delivery and UI tests. Cover personal setup, local shopping creation/completion without Apple access, local task creation, non-destructive welcome review, optional Apple-list editing, unavailable iCloud, large text, dark mode, and the full room/item/warranty/maintenance flow. No live account is required by the suite.
