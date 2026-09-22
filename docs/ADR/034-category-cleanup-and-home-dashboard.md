# ADR 034 — Category cleanup and clearer Home navigation

User requested independent cleanup of pantry/shopping/meals and a visual Home dashboard that distinguishes stocked food from purchases. User also requested live Already in shopping labels from meal ingredients.

Home is a visual NavigationStack dashboard with Pantry (what you have), Shopping (what to buy) and Meals (what to cook), followed by Rooms & belongings and spending/care tiles. Rooms retain a separate adaptive split view; quick room and floor-plan routes remain on Home. No root tab, model or ownership changes.

Meal ingredient availability uses the existing alias matcher and current active pantry/pending shopping records. In pantry, Already in shopping, combined pantry/shopping and Need to buy are explicit text/icon states. Completed shopping entries are not treated as pending. After adding, the view observes local records and replaces redundant add actions with a shopping link. Review sheets exclude already-listed items and recheck at save. Suggestion cards also disclose already-listed ingredients.

More → Danger Zone offers pantry, shopping, meals, expenses and tasks independently. Opening is read-only; actual cleanup requires a scoped preview and typed CLEAR, then a destructive button. The repository checks the same household and exact ID set (including linked prep tasks) before an atomic local deletion. New records appearing during review require another review. Existing read-only/recovery rules apply. No cleanup is run against real user data during development.

Pantry cleanup removes inventory packs only; shopping removes all pending/completed household grocery rows; meals remove saved meal plans and their linked preparation tasks; expenses remove expense/refund records; tasks remove household tasks and their delivery links. Referenced purchase history remains intact with historical snapshots. Meal and task cleanup cancels device prep alerts when active reconciliation sees deletion. Apple Reminders records and Apple Reminders-only lists are not erased. Home/family/rooms, saved stores, unrelated categories, reminder settings and backup snapshots remain.

Deletion flows through existing private/shared CloudKit tombstones when enabled/connected. This is not an immediate server purge or deletion of separate backup snapshots. Sharing participants with write access can use existing write semantics; read-only participants cannot. No additional network or storage schema.

Build 35 corrects the Meals card touch region: plain-style links now explicitly include the entire card rectangle, including empty space. The same bound is applied to Rooms & belongings. A coordinate-tap UI regression reproduces the original failure on iPad and verifies opening Meal ideas from blank card space. No domain, persistence, permission or privacy change.
