# ADR-018: Ingredient identity and duplicate review

Status: Implemented; physical model quality remains unverified.

## Decision and affected entities

GroceryItem and InventoryItem names share an offline ingredient matcher. Ingredient identity is distinct from pack identity. No schema, ownership, CloudKit transport, or automatic data migration changes are introduced. Existing packs are not automatically merged, renamed, or deleted.

Matching normalizes Unicode case/width/diacritics, punctuation and whitespace, then uses a curated alias dictionary for common ingredients and Indian regional names. Cumin, cumin seed(s), jeera and jeeragam match. Cumin powder stays separate from seeds; varieties, brands and forms are not generically stripped. Known singular/plural forms are explicit rather than an unsafe universal suffix rule. Unknown words remain distinct. A bounded edit-distance-one comparison flags likely typos for review only, with a minimum five-character name and matching token count.

Pantry and shopping suggestions deduplicate aliases both against existing items and within the proposed list. Confirmed pantry additions recheck the local inventory before committing. Pending shopping validation uses the same key; existing explicit shopping duplicate overrides remain available. Manual inventory entry blocks known duplicate ingredients at the repository boundary unless the user confirms a separate pack. The editor also warns about likely typos and optional AI matches. Name changes clear previous confirmation and AI results.

Real purchases still create separate packs, preserving provenance, quantity and dates; the same shopping purchase remains idempotent using its existing deterministic ID. Review similar items groups active packs by known ingredient identity. Users compare quantity, pack, store, location and expiry and explicitly confirm removal of one extra entry. It uses the existing repository deletion/tombstone path; shopping history and other packs are preserved. There is no summation of quantities with potentially incompatible units.

## AI and privacy

IngredientComparisonService separates domain contracts from the Foundation Models adapter. Check similar names with AI is user-triggered and on-device only, guarded by OS/device/model availability. It receives just the proposed name and up to 60 active candidate names, each capped at 200 characters. No IDs, people, stores, dates, notes or quantities are provided. Typed output is bounded to 60 integer indices, validated against the supplied candidate array and deduplicated before local IDs are resolved. Labels are treated as untrusted data. Results are possible matches for review, not evidence that two physical packs are identical. An empty response is not a guarantee of no duplicates.

Failure/unavailability leaves offline checks operational and clearly labeled. Editing a name cancels/discards stale comparison results. No network AI, telemetry, additional permissions or runtime dependencies are added. Existing private/shared CloudKit choices apply only after confirmed writes.

## Validation

Tests cover normalization and aliases, regional names, distinct forms/varieties, typo-only warnings, candidate-index validation, suggestion deduplication, repository rejection and separate-pack override, and non-cascading removal. UI validation covers the Cumin/Cumin seeds warning, disabled Save, unavailable-model fallback, explicit separate pack and confirmed duplicate removal. Device model semantic quality is not inferred from simulator tests.

## Shopping parity — 2026-09-13

Shopping Add/Edit and general household Quick Add groceries now show known-alias and likely-typo warnings, an explicit Keep existing action, a separate-purchase override, and the same user-triggered on-device comparison as inventory. The Add/Save control stays disabled for unresolved matches. Proposed-name/kind/household changes reset previous confirmation and comparison results. Completed purchases and the item being edited are excluded. Apple Reminders-only entry does not compare against household shopping. Repository alias checks still protect saves against changes after initial UI review.

Shopping → Review similar items groups existing pending aliases. Store, buyer, quantity and timing remain visible; deletion requires confirmation and uses the existing household repository path. Different purchases remain separate until explicitly removed. Inventory/provenance is not removed with an extra shopping entry. No schema or transport changes. Candidate comparison receives at most 60 names; AI never merges, deletes, changes quantities or assumes whether purchases for different buyers are redundant. Model-unavailable status preserves offline checks.
