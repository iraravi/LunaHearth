# ADR-021: Today attention dashboard

Status: Implemented; simulator validation passed and signed build 7 installed on Ravi’s iPhone.

## Presentation and affected entities

Today brings GroceryItem and InventoryItem attention forward, followed by the daily
brief, FamilyEvent schedule, HouseholdTask reminders, maintenance/warranty alerts
and MealPlanEntry meals. A new bundled transparent illustration, mist/sage canvas,
white cards and a subdued lavender brief replace the repeated Quick Add and metric
cards. Quick Add remains in the navigation toolbar. Phone layouts use three compact
priority selectors; wide windows display the three priority panels side by side.
Scalable text, scrollable content and labeled native actions remain available.

Buy shows incomplete shopping needed now. An explicitly selected household member
filters only shopping; without a valid selection it shows household shopping.
The existing For you screen manages that device-local selection and assignment
alerts. Valid dated Later entries become due on their civil day, overdue entries
sort first, and undated/invalid Later entries are not silently treated as due.
Shopping completion opens the existing explicit purchase destination sheet,
including existing-pack duplicate protection.

Use soon shows recorded pantry dates through seven civil days, with past-expiry
packs explicitly labeled "Past expiry · Check item". It never recommends consuming
expired food or infers freshness. Used-up packs and missing/invalid dates are
excluded. Each row opens its exact pack editor. Restock shows one low-stock
suggestion per normalized active ingredient; it never totals incompatible pack
amounts. Add to shopping calls the existing local restock transaction, checks all
pending household shopping for duplicates, and then displays On shopping list.
The remaining amount is not copied as a reorder quantity. Stock flags are not
cleared just because an item was added to shopping.

## Data, sharing and permissions

No model schema, CloudKit mapper, sharing ownership, account or permission change.
The dashboard reads the active household's existing local repository and updates
when incoming changes reload that repository. It does not wait for a network call.
Restock reuses existing private/shared synchronization; all actions remain guarded
by repository recovery/read-only rules. Read-only browsing is explained in the
attention panel. No new notifications are scheduled by Today.

Live Ravi/Kira delivery needs two available devices using separate iCloud accounts
and an accepted shared home. Simulator/fake-server tests do not establish live
CloudKit or APNs behavior. No live sharing verification is claimed here.

## Optional daily brief

TodayBriefService accepts eight aggregate counts only: needed/overdue shopping,
recorded pantry dates/past-expiry count, distinct low-stock ingredients, today's
events, due reminders and home-care alerts. No names, IDs, notes, quantities,
locations, household/member identity or documents enter model context. The user
explicitly taps Summarize. Foundation Models is gated to available iOS 26+ devices;
a deterministic saved-list overview remains useful offline or when AI fails.

Generated prose is labeled, bounded and read-only; independent counts may overlap,
and are never summed into a misleading total. AI cannot make purchases, change
stock or dates, classify safety, or write any records. Exact source cards remain
available. Scope/day changes cancel and discard the brief; count changes invalidate
it. There is no cloud AI, external endpoint, telemetry or new runtime dependency.

## Validation

120 unit tests and the Today UI flows passed; see `../visual-review/today-design.md` for artwork and
screenshots. Unit coverage includes civil-day/year/DST boundaries, overdue ordering,
invalid/undated Later entries, used-up exclusion, alias grouping, exact fallback
counts, person filtering and local restock duplicate protection.
