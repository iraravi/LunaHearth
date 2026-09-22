# ADR-015: Guided shopping entry

Status: Accepted — user requested inline stores, duplicate feedback, units, later
dates and a smaller action, September 12, 2026.

## Behavior and privacy

Store suggestions appear below the store field without opening Browse. Saved
household names are prioritized, followed by bundled chain matches. Exact normalized
matches show “Already saved” and reuse the existing record. The dedicated store
form reports duplicates and changes Save store to Use existing. Matching is
predictable spelling/alias normalization; no AI or business-directory API.

Pending shopping items with the same normalized name trigger an inline warning,
including their store. Saving requires the explicit Keep a separate entry choice.
The repository rechecks on save; edits exclude their own UUID and completed items
do not block new purchases. This is a local-list check, not a global lock across
offline devices. Simultaneous additions may still arrive through synchronization.

Amounts support pieces, kg, g, lb, oz, L, ml, packs, bottles, cartons and dozen.
Other preserves custom descriptions. Numeric amounts must be positive, at most
1,000,000, with up to three decimal places; comma/dot decimal input is normalized.
No automatic conversion between units or inferred amount is performed.

Later shows an explicit date picker, initially tomorrow for new entries. The user
can choose a calendar date; this is a shopping plan, not an automatic notification.
Now clears the planned date on save. Past dates remain visible rather than silently
changing priority or moving dates. Reviewed AI batches can use the same user-selected
date; model-generated quantity descriptions remain unchanged until edited.

No new permissions, external services or disclosure scope. New values remain in
the existing optional private CloudKit household sync and backup payloads.

## Additive model changes

GroceryItem adds optional quantityAmount (normalized decimal text), quantityUnit
(stable enum string), and plannedDay (Gregorian YYYY-MM-DD). quantityText remains a
formatted legacy fallback, so older apps still display the amount. New reads prefer
structured amount/unit for editing. Old free-text quantities remain Other and are
never reinterpreted silently. All new Codable fields are optional. No destructive
migration or CloudKit record-type/key change is needed.

plannedDay is a civil date; presentation converts to local noon in the viewer's
calendar zone and validates round-trip components. It never travels as midnight UTC.
All shared clients should update; older clients can discard unknown optional fields
when editing. Physical upgrades and live multi-account testing remain release checks.

### Store visibility and compact action follow-up (2026-09-13)

Saved household stores now have their own visible suggestion strip before typing, separate from bundled chain suggestions. Matching names update as the user types in both the dedicated shopping editor and the general Quick Add grocery form. Selecting an inline suggestion fills the store field and persists/reuses that store immediately, matching the existing Browse behavior even if the item is then cancelled. A custom typed name is still saved with the item. The interface distinguishes the 32 bundled chain suggestions from the user's own saved stores; this is an offline catalog, not live store search. Add-item actions use a plain compact capsule with a 44-point minimum hit target, avoiding the extra padding imposed by a bordered-prominent button style.

While the store field is focused, a matching-store text shortcut is also available in the keyboard toolbar; selecting it fills and saves the store and ends editing. This avoids requiring a tap on a suggestion that may be below the visible form area.

Validation: all 91 unit tests passed in `/tmp/LunaStoreRefine20260913.xcresult`. The inline/date/duplicate flow and large-text dark flow passed in `/tmp/LunaStoreRefineFinal20260913.xcresult`; the final saved-store, 44-point action and keyboard-autocomplete regression (including general Quick Add) passed in `/tmp/LunaStoreKeyboard20260913.xcresult`. Earlier UI runs caught a suggestion obscured by the bottom action area; the keyboard shortcut resolves that path. Saved-store and autocomplete screenshots were inspected. Custom stores on a physical user device were not inspected.
