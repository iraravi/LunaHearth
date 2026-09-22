# ADR 044: Meal suggestions are not generated cooking instructions

Status: accepted for implementation, September 16, 2026. User requested strict guardrails for AI food/receipt output and explicit error notices.

## Decision
New on-device generative meal results contain meal names, ingredient suggestions and approximate planning minutes only. The generated schema has no preparation-step field. A deterministic domain factory validates the proposal and creates it with an empty step list. The prompt also forbids preparation, storage, temperature, preservation, foraging, dietary and safety claims. Prompt instructions alone are not a safety guarantee.

Cooking instructions can still exist in manually entered meals, built-in starter ideas and older saved meals. This change does not delete or rewrite household data. Those instructions are not certified or independently safety-reviewed. A persistent notice appears in meal ideas, weekly drafting, meal editing and the saved cooking screen, including before ingredient/step content. No dismissal or checkbox is treated as verification of safety. Empty AI recipes direct users to a trusted recipe.

Receipt and photo review show specific misidentification/reading warnings. Pantry suggestions state that category/name/date matches do not establish food safety or allergens. Weekly shopping copy refers to saved records rather than claiming pantry amounts and dates are already checked. Restocking no longer calls a new pack “fresh”.

## Limits
AI names and ingredients remain untrusted text and can still be wrong, including dietary/allergen mistakes. Schema validation does not prove semantic food safety and cannot stop every malicious or incorrect phrase in a text field. Approximate minutes are planning estimates, never doneness instructions. Existing offline recipe templates need independent food-safety editorial review before claims of verified recipes can be made. Ingredient matches and civil-day expiry filtering are inventory conveniences, not food-safety decisions.

No remote AI, network connection, permission, schema migration or user-data deletion is introduced. Local/offline starter workflows remain available. Release screenshots/archive made before this change must not be represented as containing these notices. Do not ship without reviewing final UI and remaining release/legal gates.

## Validation
Unit regression requires generative factory results to have no preparation steps and rejects malformed proposals. Existing meal and receipt UI workflows exercise review/save paths. Validation outcomes are recorded in the release audit.

## Wording sources
Checked September 16, 2026:
- FDA: appearance/smell cannot establish food safety; follow package directions: https://www.fda.gov/consumers/consumer-updates/are-you-storing-food-safely
- FoodSafety.gov: clean, separate, cook and chill: https://www.foodsafety.gov/keep-food-safe/4-steps-to-food-safety

Warnings reduce misleading expectations; they neither establish legal compliance nor waive consumer rights or eliminate liability. Publisher/counsel review remains required.
