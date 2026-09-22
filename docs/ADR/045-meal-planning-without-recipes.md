# ADR 045: Meal planning without recipes

Accepted September 16, 2026 following the user's request to simplify Meals and remove cooking-instruction features. Supersedes the built-in/manual instruction UI retained in ADR 044.

Meals now offer names, ingredient lists, quantities, scheduling, personal reminders, shopping review and explicit pantry-use tracking. Built-in suggestions contain no recipe steps. New AI output already has no step field; neither daily nor weekly suggestions populate recipe steps. The recipe editor and saved step display are removed. Navigation says Meal details / Ingredients & shopping. Preparation reminders use neutral examples rather than cooking/defrosting advice.

Existing preparationSteps stay in local persistence, backups and CloudKit mapping for compatibility, but are not rendered or editable through the app. Editing another field preserves those legacy records. This is not a destructive migration. User-entered notes and reminder text remain personal records, not app-authored recipes. No new networking, permissions or dependencies.

The shorter visible notice explains that ingredient suggestions can be wrong and the app does not provide cooking instructions or verify allergens/food safety. This reduces product scope; it does not waive liability or establish legal compliance. Accurate privacy disclosures and other release obligations remain.

Tests: built-in suggestions must have no steps; generative factory emits none; editing a legacy meal preserves hidden data; existing meal-to-shopping-to-pantry UI flow checks absence of recipe controls. No saved data is erased as part of this change.

Validation outcome: simulator build and 239 unit tests passed; the full meal planning → shopping → pantry-use UI test passed, including checks that recipe controls are absent (`/tmp/luna-simple-meals.log`). Device installation is not part of this update; installed build 55 still has the earlier UI until rebuilt and installed.
