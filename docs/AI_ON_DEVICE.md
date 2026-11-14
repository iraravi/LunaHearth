# On-Device Intelligence Design

## 1. Principle

Intelligence reduces typing and organization work. It is not the database, scheduler, permission system, or source of truth.

## 2. Apple technologies

Primary:
- Vision for OCR/barcodes/image text extraction
- Foundation Models framework when available

Current Apple references:
- https://developer.apple.com/apple-intelligence/
- https://developer.apple.com/documentation/foundationmodels
- https://developer.apple.com/wwdc26/guides/apple-intelligence/

Apple’s current Foundation Models APIs support on-device Apple models and multimodal/image-oriented workflows in newer OS releases. The app’s deployment target remains broader, so capability gating is mandatory.

## 3. Service abstraction

Do not make SwiftUI depend directly on `LanguageModelSession`.

```swift
protocol HouseholdIntelligenceService: Sendable {
    func parse(text: String) async throws -> ParsedHouseholdInput
}
```

Expand using typed requests/responses.

## 4. Capabilities

### Quick Add
Input:
“Saturday Costco, buy milk and eggs, change upstairs filter.”

Candidate output:
- event/shopping trip Saturday
- grocery milk
- grocery eggs
- maintenance/task change upstairs filter

Because one sentence may imply multiple records, production result should become a list of proposed operations.

### Event flyer
Vision OCR → model → EventDraft + TaskDraft (“bring snacks”).

### Appliance label
Vision OCR/barcode → AssetIdentityDraft.

### Receipt
Vision OCR → PurchaseDraft with merchant/date/amount; optionally link selected asset.

### Household query (later)
“When did we last replace the refrigerator filter?”

Prefer deterministic local query first. The model may phrase the answer but should not guess missing records.

## 5. Structured generation

Use Foundation Models structured generation/schema capabilities when supported rather than parsing prose JSON manually.

Still validate:
- dates
- duration
- money
- IDs
- recurrence
- enum values

Model-provided UUID/member/asset references must be resolved from an explicit candidate set, never invented.

## 6. Confirmation policy

### Can save with one-tap confirmation
- new task
- new grocery item
- draft event

### Require review for sensitive/ambiguous fields
- warranty expiration
- purchase amount
- serial number
- recurring maintenance interval
- document classification that affects retention

### Never autonomous
- delete data
- share data
- invite family
- change permissions
- purchase/subscription action
- export private documents

## 7. Context minimization

Bad:
“Here is the entire household database. Tell me what to do.”

Good:
“Extract event date/time/title from this OCR text.”

For “what should I do today,” construct deterministic candidate items first, then optionally let model rank/explain a small set.

## 8. Fallbacks

Foundation Models unavailable:
- explicit structured form
- NaturalLanguage/DataDetector/rule parsing where appropriate
- Vision OCR still used when supported

The feature must remain useful.

## 9. Error handling

User-facing categories:
- intelligence unavailable
- couldn’t understand
- ambiguous date
- unsupported image/document

Do not expose model framework internals unless diagnostics enabled.

## 10. Evaluation

Before shipping AI extraction create local evaluation fixtures:
- school flyers
- warranty cards
- appliance labels
- receipts
- ambiguous natural-language tasks

Measure field accuracy, not “sounds good.”

Evaluation data must be synthetic/licensed or explicitly consented test data; do not commit real family documents to the repo.

## Foundation status and Private Cloud Compute — September 2026

Shopping ideas now uses the on-device SystemLanguageModel with guided structured output on supported iOS 26+ devices. The older general-purpose parsing adapter still only trims input; other AI workflows remain future work. Manual shopping entry remains available.

Apple now exposes `PrivateCloudComputeLanguageModel` on iOS 27 and later, with a managed entitlement, device/region availability and daily request limits. This is a server inference service, not CloudKit storage. LunaHearth does not enable it or send content to it. A future PCC feature needs its own approved privacy ADR and entitlement. Evaluate on-device `SystemLanguageModel` first, always retaining manual entry and review before save.

Reference: https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute

## Shopping ideas implementation

Lists → Shopping → Shopping ideas accepts an optional plan (400 characters maximum). After the user taps Suggest items, the service checks on-device availability and creates a fresh session explicitly bound to SystemLanguageModel.default. It uses no tools, Private Cloud Compute or third-party network model. Input is limited to the request, up to 20 optionally included checked-item names and up to 40 currently listed names, each capped at 80 characters. No member names, Apple identities, stores, addresses, notes or documents are included.

Guided generation proposes up to eight names and optional explicitly requested quantities. Domain validation bounds field lengths, deduplicates names and filters current items. The user can edit, exclude, choose store/buyer and explicitly Add selected items. A single local transaction rechecks the household and buyer, skips newly added duplicates and commits the selected items atomically. Enabled CloudKit sync treats these confirmed records as normal user data. Nothing is saved by generation or cancellation.

Unavailable or failed generation uses checked-item history, or starter ideas when no history exists. The UI explicitly labels these as not AI-generated and not an interpretation of the request. It never implies pantry awareness, store availability, nutrition/allergy suitability or predicted purchase frequency. An empty model result has a manual-entry/retry state. Session cancellation discards results.

Tests use synthetic data and the deterministic fallback, never live credentials/model inference. Device-specific model quality/availability requires a physical Apple Intelligence check. No on-device model quality claim is made based on simulator tests.

## Assigned-shopping brief

Today → For you offers a read-only, user-triggered brief of that member's open shopping. Exact totals and Now/Later grouping are deterministic; optional Foundation Models prose receives at most 40 bounded item/quantity/store/timing values with no member identity. Unsupported or unavailable models use the offline summary. No cloud AI calls, automatic shopping changes, or inferred purchases are involved. See ADR-016.

## Home pantry setup (ADR-017)

OnDevicePantrySuggestionService tailors at most 24 ingredient names for a selected cooking style. Built-in South Indian, Indian and Everyday ideas preserve the workflow without Apple Intelligence. Users explicitly select what is already at home and confirm Add; there is no automatic ownership inference. Generated names cannot supply quantity, pack details, dates or stores. Missing expiry stays unknown. The app sends no household data to image-generation or cloud AI services.

## Ingredient comparison (ADR-018)

Inventory entry offers an explicit on-device similarity check against up to 60 bounded active ingredient names. Structured candidate indices are range-checked; possible matches require review. Curated regional aliases and conservative spelling checks work without AI. AI never merges/deletes entries or infers whether two names represent one physical pack. The UI reports unavailable models and limits; live model quality requires device evaluation.

## Visual pantry categories (ADR-019)

An optional on-device action categorizes up to 40 unfamiliar names for presentation only. Allowed category values and candidate indices are validated. Hints are labeled, resettable and not persisted or synced. Known names and colorful icons work offline. No stock, expiry or storage conditions are inferred.

Shopping Add/Edit now reuses IngredientComparisonService for optional duplicate-name review, with the same on-device-only limits as inventory. Pending household shopping names only are supplied; completed items and the edited record are excluded. Confirmed aliases and likely typos are checked offline, and separate purchases require an explicit override. Apple Reminders-only entries are excluded from this household comparison.

## Today daily brief (ADR-021)

A user-triggered TodayBriefService summarizes eight aggregate attention counts.
No household labels, identity, notes or documents are sent to the model. A saved-list
summary works without Foundation Models; generated output is read-only and labeled.
Exact counts/actions are deterministic, and scope/day/count changes discard the
brief. No cloud AI or new network access is introduced.

## Pantry idea result states (build 18)
Pantry Ideas labels starter suggestions separately from the actual saved-ingredient count. Active existing ingredient aliases are excluded; suggestions do not represent owned stock and do not persist until selected and confirmed. The on-device adapter now distinguishes disabled Apple Intelligence, model not ready, unsupported/unavailable device, generation failure, successful generation, and no new generated ideas. Failed or unavailable generation explicitly says the custom request was not applied to the starter list. Empty generated results no longer silently revert to starters. Request length is bounded in the UI as well as the service. Changing style cancels/discards prior work, and switching households dismisses the scoped form. No model inference or household content leaves the device.

Build 19 brings the new pantry AI result into view automatically, including within a shorter iPad sheet. This avoids a successful fallback appearing to do nothing because its explanation is below the fold.

Pantry generation now proposes up to 100 names for kitchen-template review. Bundled regional templates also provide 100+ names offline, explicitly labeled starter suggestions. The shared validator accepts at most 150 reviewed names. Search, category/all selection and a final review confirmation precede any save. Prompt context limits and on-device-only execution remain unchanged. See ADR 027.

## Receipt photos — ADR-028

Scan receipt in Shopping or Pantry uses Apple Vision OCR on selected photos or document-camera pages. It works without Foundation Models and never calls a network model. Bounded priced-line parsing proposes names and explicit piece quantities for editable review; it does not infer ownership, amounts remaining, expiry, payment totals or purchase prices. Confirmation updates local shopping and inventory atomically, then uses the existing optional private/shared sync. Raw images and OCR text are transient and are not included in backup. See ADR-028 for repeat-import limitations and older-client compatibility.

## Receipt name decoding — build 26

Receipt review offers **Decode names with AI** using the on-device Foundation Models language model on eligible iOS 26 devices. Only parsed item labels (12 per request, at most 150) enter the model; photos, full receipt text, payment details, household records and amounts do not. No network LLM is used. This is abbreviation expansion, not a Costco SKU lookup service.

Names appear as individual proposals beside the original label. **Use suggested name** updates only the draft name and re-evaluates existing shopping/inventory matches. Normal receipt confirmation remains required before persistence. Quantities, dates and expense totals remain user-reviewed. Generated indexes and names are validated; edited/excluded rows cannot receive stale proposals. Rescanning, leaving or cancelling invalidates pending results. Suggestions are temporary and are not synced; accepted names use the existing receipt import and optional private/shared CloudKit path.

Unavailable, disabled, downloading, failure, partial-result and no-suggestion states preserve manual editing. Numeric-only codes are rejected as name sources, and the prompt instructs the model to omit uncertain expansions; this cannot guarantee semantic accuracy, so review is required.

Connected demo meal cards are curated pantry-matched examples, explicitly labelled as such. They are not generative output. The 5 PM tomorrow-preview is manual and does not claim background AI execution or scheduled notification delivery.

## Production meal ideas — build 31
Lists/Home → Meal ideas now reads real active pantry names, generates optional on-device structured ideas, and offers labelled pantry-ranked built-in suggestions when the model is unavailable. Results are temporary; Review & plan saves a normal household meal only after confirmation. An optional device-local 5 PM notification opens this screen; it does not generate in the background. See ADR 032 for input limits, expiry filtering and privacy boundaries. The connected demo remains isolated.

Build 32 adds explicit cooking style and up to 400 characters of optional meal preferences to the on-device request. Both are user-selected; identity is never inferred. Built-in ideas filter by cuisine, and fallback copy explains that free-text notes were not applied. Changing either input invalidates prior suggestions. Style is remembered on this device; notes are transient.

Build 33 extends structured meal suggestions with up to eight bounded preparation steps. Reviewed ingredients/steps/servings save to the planned meal. Stock consumption is always explicit deterministic decimal review, never model output. Selected built-in ideas have editable preparation steps; other starter ideas clearly show that no steps are saved. User context still does not guarantee dietary/allergy suitability.

Build 37 adds editable cooking steps to every built-in meal starter, so offline proposals include instructions. Previously saved meals are not retroactively rewritten; an explicit editor action lets users add missing recipe steps. Prep reminders are separate optional household tasks, not generated recipe instructions.

### Weekly meals (build 38)
Weekly planning reuses on-device meal ideas with an explicit review/swap/select/save stage. Fallback is labelled, dishes may repeat, and quantities remain user-entered. No AI-driven stock changes. See ADR 035.

### Family week — build 44
Plan our week reuses the existing private on-device meal service and labelled fallback. Deterministic appointment interval checks rank quicker dinners on busy evenings and propose optional prep task times; no appointment titles or member details enter the model. Meals and tasks are reviewed and atomically validated before saving. Personal Apple calendars are excluded, and no background generation or new notification opt-in is implied. See ADR 038.

Build 45 expands Family week generation to breakfast, lunch and dinner, all selected initially. Users may turn off any meal type before generation. Existing candidate generation and editable review are reused; candidates may repeat and users should swap choices to suit each meal. Busy-evening ranking and optional evening prep reminders apply only to dinner. No new AI inputs, permissions or schema.

## Pantry photos — build 50 (ADR-043)
Pantry → Add from kitchen photo uses on-device image input on eligible iOS 27 devices, with explicitly labelled whole-product-label Vision OCR fallback on older/unavailable models. Editable suggestions start unselected. Amounts and expiry are user-entered only. Raw photos are transient; only confirmed new InventoryItem records persist through the existing local-first sync. Existing pantry aliases are skipped, never restocked by a photo. Receipt import remains a separate purchase/expense workflow.

## AI status — build 51
More → AI Status reads the current public SystemLanguageModel availability and, on iOS 27, its vision capability. It shows device family, iOS version, a technical hardware identifier, app model selection, readiness guidance, and the available pantry scan path. It does not guess a private model revision or parameter count from hardware/iOS version. Status refreshes on entry, return to the foreground and explicit Refresh. Capability is distinguished from the actual result of an individual scan, which still reports its own fallback. Pantry photo inference now also checks the vision capability before invoking image AI.

Status checks are local, do not run prompts, request permissions, enable Apple Intelligence, log identities or modify household records. No schema or sync changes. Exact model revision is explicitly unavailable through the public API used by this app. iOS 18–25 show the older-OS fallback; ready/off/not-ready/ineligible/unknown states are handled separately. Deterministic tests cover image eligibility and fallback selection; UI checks cover More navigation and refresh with large text.

Build 51 validation: six focused domain/pantry persistence tests passed, including real Vision OCR fallback. AI Status navigation and refresh passed in normal and accessibility text on both iPhone and iPad simulators (`/tmp/Luna51Phone.xcresult`, `/tmp/Luna51Pad.xcresult`). Signed Release build passed and was installed on Ravi's iPhone; physical iPad installation remains blocked by its locked state. Status reports capability, not a completed inference quality test. No TestFlight upload or household reset.

## Ingredient search — build 52
Pantry search now searches item names rather than storage-location text. Regional aliases are expanded deterministically for discovery, with word-prefix matching and specific forms (e.g. powder) preserved. Pantry Ideas uses the same search rule. This does not alter identity/deduplication, stored names, categories or photo inference. Plain rice cannot match a cumin query; a product explicitly named cumin rice can still match its visible name. The reported issue was search results; the user's specific stored record has not been inspected, so storage-text matching is a potential cause rather than a confirmed diagnosis.

While searching, the pantry hero illustration and discovery tools collapse to a matching-item count so results remain visible above the keyboard. Build 52 validation: 10 focused ingredient/visual-rule tests passed, plus the cumin/Jeera versus Rice storage-text regression on both iPhone and iPad simulators. Final search screenshots were inspected on both sizes. Signed Release build succeeded and build 52 installed on Ravi's iPhone. Physical iPad installation was blocked because it was locked. No household data reset or TestFlight upload.

## September 16 food-safety boundary (supersedes generated step support)
ADR 044 removes preparation steps from new generative meal output and from its output schema. The domain factory returns no generated steps. Existing/manual/built-in steps remain unchanged with a visible review notice. Meal, weekly plan, receipt and pantry-photo review now explain that AI/OCR can be wrong and cannot verify allergens or food safety. No capability is advertised as a safety check; saved dates/amounts remain unverified records.

## Meal planning only (ADR 045)
Built-in recipes and all recipe-step display/edit controls are removed. Meal ideas remain names and ingredients; older stored steps are preserved but hidden, including during editing. Day/week planning and explicit pantry-use tracking remain. This is a scope reduction, not a food-safety certification or substitute for accurate privacy/legal disclosures.

## Capability-aware controls (September 2026)

The root presentation checks `AppleAIStatusService` at launch and whenever the app
becomes active. Only `AIAvailability.ready` exposes AI-only actions; disabled,
preparing, unsupported, older-OS, and unknown states hide them. There are no retail
device-name checks. Filters retain their normal controls without the “& AI” label.
Receipt name decoding, optional duplicate-name AI comparison, category generation,
and free-text pantry/meal tailoring follow this policy.

Manual entry, Vision receipt/label reading, deterministic duplicate matching,
automatic categories, kitchen templates, built-in shopping/meal ideas, and meal
planning reminders remain available. More → AI Status remains accessible.
Services still check actual model availability at invocation and preserve fallback
behavior if readiness changes. This changes presentation only: no household
schema, persistence, permissions, network access, or privacy behavior changes.

Debug UI fixtures can explicitly request ready or unavailable presentation using
`--ui-testing-ai-ready` / `--ui-testing-ai-unavailable` together with
`--ui-testing`. They never override real model execution or ship in Release.

Validation: simulator build passed; 244 Swift Testing tests and the grocery search
performance XCTest passed. Both available-AI and unavailable-AI shopping/pantry UI
flows passed, including a repeat on the final source. Physical iPhone 15 validation
and TestFlight distribution were not performed for this change.

### Public operational switches — ADR 049
The public configuration master AI switch and individual AI switches are checked before model invocation. Real device capability checks remain mandatory. No prompts, household data or inference are sent to the public database; it supplies only publisher-owned flags and plain status/help text. In-flight work is not guaranteed to cancel when a new setting arrives. See `PUBLIC_APP_CONFIGURATION.md`.

### Shopping suggestions and recorded pantry stock — September 26, 2026
Shopping ideas now deterministically exclude ingredient-identity matches in recorded pantry stock, as well as open shopping items. Used-up, low-stock and past-expiry packs remain eligible for restocking. The same check runs for built-in suggestions, model output, after asynchronous generation and immediately before saving. Pantry names are used locally for filtering; this change adds no model prompt data or network access. Name-only stock is not a quantity guarantee; users can manually add extra items. Distinct ingredient forms and varieties retain existing identity semantics.

Regression coverage: pantry Rice is excluded from fallback and save, Chicken remains suggested, and low-stock/used-up/past-expiry Rice remains eligible. Build/test log: /tmp/luna-shopping-pantry.log. Exact user-reported ingredient wording is still needed to diagnose variety mismatches separately.

### Dish requests and shopping history — September 27, 2026
A nonblank Shopping Ideas plan now excludes checked-item history from model context. Instructions prioritize defining main ingredients, respect exclusions/substitutions, and avoid replacing requested ingredients with unrelated staples. Pantry/open-list filtering still applies after generation and at save. These prompt instructions improve guidance, not a guarantee of model accuracy.

For a typed plan, unavailable/failed AI returns no ingredient proposals and explains that the request was not generated; it no longer substitutes past purchases or generic basics. Blank-plan browsing retains explicitly labelled history/starter ideas. No recipe steps, new network access, persistence or permission changes. Tests cover the chicken briyani spelling, unrelated lentil history, blank-plan fallback, and pantry exclusion without losing an absent main ingredient. Physical model output for the reported case has not been observed.


### Reliability and private diagnostics — September 28, 2026
All nine model adapters classify typed Apple generation failures and record only the last feature, result category and timestamp per AI feature in local UserDefaults. More → AI Status displays and clears these results. No prompts, photos, labels, generated content or raw error descriptions are recorded. No CloudKit mapping, household backup field, network request or permission was added. Both brief adapters share the AI briefs diagnostic slot. Cancelled requests do not overwrite diagnostics. A successful generation is explicitly not an accuracy check.

Category classification uses batches of 10 (up to 40 inputs), and ingredient comparison uses batches of 12 (up to 60 inputs), preserving indices into the original input. Results are returned only after the full batch sequence succeeds. Meal and pantry prompts deduplicate names and enforce character budgets; assigned-shopping briefs also bound total item text; character limits do not guarantee a particular token count. Meal generation guides constrain ingredient count and estimated minutes; deterministic review rejects blank, control-character and URL labels and deduplicates ingredient aliases without merging distinct forms. Pantry request edits and meal/assigned-shopping context changes discard stale results. Today and assigned-shopping AI buttons now respect capability and publisher switches while retaining deterministic summaries.

See `validation/2026-09-28-ai-audit.md` for scope, evidence and remaining physical-device validation. This does not add recipe instructions or certify generated ingredient correctness.

## Receipt expense review — 30 October 2026

Receipt totals are deterministic suggestions from explicitly labeled totals, including grand/net totals, whole amounts, common Indian grouping, decimal commas and labels followed by an amount on the next line. Conflicting totals or ambiguous numeric punctuation require manual entry. Explicit currency markers can suggest a supported currency; an unqualified dollar sign does not identify a country. Users review the expanded amount/currency/date fields and the final save confirmation. Item amounts are never substituted for the full tax-inclusive receipt total.

Receipt review starts with inventory additions off. Each new item has a visible Add to pantry / inventory switch; the final confirmation offers saving selected stock or saving without inventory. Existing-purchase links preserve their previous stock decision. Expense, purchase, shopping and inventory records continue through the existing atomic local transaction; no schema, permission or network changes. Food consumed elsewhere and non-stock expenses need not enter inventory.

Receipt scan results now present a transient visual summary with the recognized store, editable total, item count and decorative ingredient artwork. Inventory can be selected in bulk or per card; bulk operations skip excluded, already-imported and linked purchases. Changes remain proposals until final confirmation. Entrance and selection motion respect Reduce Motion, cards adapt to Dynamic Type, and the original OCR text remains available for comparison. No new image retention or network behavior.

## November 2026 reviewed receipt matching

Receipt reconciliation now suggests known qualifier/cut variants such as PREMIUM MUTTON LEG for a generic Mutton shopping request, offline. This is a review-only candidate rule, separate from ingredient identity used for pantry merging and cooking. Non-exact links require explicit selection; different species, specific cuts and preparations are not broadly merged. Original shopping assignment/name/ID are preserved and receipt names are no longer overwritten by shopping selection. Recent bought-item candidates use the same rule and still require link-versus-new review to prevent duplicate stock. No generative model or new network processing is required.

## Personal and family daily brief — November 2026

Today now presents saved plans, due/overdue tasks and shopping needed now for each household member, with the selected device member first as You. Unassigned work appears under Shared home. Choose who you are reuses the existing local member preference, not authentication. Selecting yourself does not hide the family's shopping from the brief totals; personal shopping filters elsewhere remain unchanged. Completed shopping/tasks and future tasks are excluded using existing rules. Each category previews two labels with a remaining count.

Affected entities are HouseholdMember, FamilyEvent, HouseholdTask and GroceryItem, read locally only. Named details render deterministically and update from the repository without AI, connectivity or extra permissions. The optional AI summary still receives only TodayBriefFacts aggregate counts; names, task titles and calendar content are not added to its prompt. No schema, CloudKit or ownership changes. Empty member sections describe only saved records, not a claim that the person is free.

Validation: XcodeGen generation and iPhone 18 Pro iOS 27.2 simulator build passed; six TodayAttentionTests (including the family assignment regression) and the Today large-text/Reduce Motion navigation UI test passed. Log: /tmp/namillam-family-brief.log. No public release or TestFlight upload.

## Reviewed AI receipt-to-shopping matching — November 2026

Receipt rows offer Find matches with AI when device capability and the existing aiDuplicates operational flag allow it. The receipt-specific mode of OnDeviceIngredientComparisonService checks up to 60 eligible shopping names in batches of 12, with labels bounded to 200 characters. Inputs contain only the receipt item label and shopping names: no household member identities, receipt photos, expense amounts or full receipt text. All inference stays on device; no new network service, permission, dependency or schema is introduced.

The model may suggest a branded product or cut for a generic shopping request, but is instructed to preserve explicit product constraints and avoid substitutions. This is guidance, not an accuracy guarantee. Each suggestion is labelled AI and requires explicit confirmation; there is no automatic selection. Receipt and shopping names plus grocery ID form a transient review snapshot. Saving rechecks the snapshot, pending-item eligibility and single use inside the existing local receipt transaction. Editing the receipt name invalidates approval, and changed shopping names fail validation. Async responses are discarded if context changes. Completed/history items and pantry restock identity are not broadened by AI. Existing assignment/name remain intact; receipt naming remains available for the new pack.

Offline deterministic candidates and manual review remain available if the model is missing or fails. Names are not persisted in AI diagnostics. No receipt image storage is added: persistent image retention and storage controls remain separate work.

## Automatic structured receipt extraction — November 9, 2026

Receipt photo selection, camera scans and sample-image scans now use Vision OCR followed automatically by OnDeviceReceiptExtractionService. Apple Foundation Models is the primary product extraction path on capable devices when the existing aiReceiptNames/AI operational controls permit it. It receives numbered OCR text rows from this receipt only, not household records or images, and returns a typed @Generable product list: source row, literal printed name, printed positive price and linked discount source rows. These are review proposals, never database writes.

ReceiptExtractionRules validates source indexes, literal names and price evidence, rejects reused coupon rows and mismatched Costco SKU references, calculates net amounts using integer minor units, and reconciles against a readable subtotal. Unreadable values stay blank with a review warning. Repeated product amounts are grouped without inventing package quantities. Naming expansion and shopping/pantry matching remain separate, explicitly reviewed actions.

No cloud AI, network service, additional permission or persistence schema is introduced. Receipt text stays on-device and is not logged in AI diagnostics. This broadens the model input from product-name snippets to the current OCR receipt text. Input is limited to 8,000 characters/120 rows and output to 80 products; oversized receipts use the full deterministic fallback rather than silently truncating. Unavailability, operational pause, generation failure, invalid structured evidence or empty output falls back to ReceiptRules with an explicit Standard scan used message. Cancellation remains controlled by ReceiptScanSession, whose existing watchdog also covers AI work; a watchdog timeout cancels the scan and allows retry/manual entry rather than promising a successful AI result.

Validation: simulator build passed and 353 unit tests across 67 suites passed. New tests cover structured evidence, hallucinated names/prices, source bounds, duplicate coupon use, SKU conflicts, unreadable prices and subtotal mismatch. These tests validate integration/guardrails, not generative accuracy on a physical Apple Intelligence device. Device receipt testing remains necessary before public release. Not yet uploaded to TestFlight.

### Receipt purchase-header correction — November 9, 2026

The receipt review header no longer silently treats today's date as the printed purchase date. A single valid printed date is proposed; ambiguous numeric ordering requires review unless a US postal address establishes month/day ordering. Missing dates display Check date and open Purchase details before the save review. Costco evidence elsewhere in OCR can identify a generic WHOLESALE header; a generic header alone remains blank. Conflicting TOTAL and AMOUNT fields are rejected unless the printed payment amount is independently corroborated by subtotal plus tax. This does not fabricate or repair OCR digits. All blank expense-item amounts now show review warnings, including deterministic fallback results.

These are local, transient review changes to ReceiptScan/ExpenseDraft presentation and receipt validation. No persistence schema, CloudKit, permissions or network changes. Automatic on-device AI product extraction remains in place; literal labels and unknown prices still need review. Regression fixtures cover the reported 170.63/770.63 conflict, generic merchant headers, absent/ambiguous/conflicting dates and invalid calendar dates. OCR and physical-device generative accuracy are separate from these text-fixture checks.

### Internal developer receipt lab

Debug and the dedicated Internal build configuration expose More → AI Status → Receipt debug. The RECEIPT_DEBUG compile condition excludes this screen, transient generated-output field and capture code from public Release builds. The lab runs the production receipt pipeline without saving records and displays numbered OCR, structured model fields, validation rejection reasons and final proposals. Private receipt text stays in memory; clear/leave removes it. Explicit Share debug text can export it through the system share sheet; no automatic upload or persistent receipt logging is added. Developer access is controlled by distributing the Internal archive only to intended internal testers, not by an in-app identity check. See docs/validation/2026-11-09-receipt-debug/README.md for distribution and privacy details.

### Receipt recovery and multiline evidence — November 10, 2026

Structured receipt proposals now include priceRow separately from the name row. Up to three adjacent name/quantity lines are supported when the price row explicitly states count Each @ unit-price/Each and count × unit price equals the printed line total. Names must remain literal OCR evidence; unrelated total lines cannot be used as product prices. Purchase/price rows and discounts cannot be reused.

Generation uses fresh on-device sessions with at most one correction attempt for rejected evidence or unresolved amounts. The correction identifies the validation issue and requests all repeated purchases separately; generated arithmetic is not trusted. Internal debug reports retain both attempt outputs and reasons. After two invalid responses, independently valid non-overlapping proposals may be retained as a clearly labelled partial result; invalid/conflicting proposals are omitted for user review. Source-readable amounts remain visible with review flags on subtotal mismatch rather than being erased globally. The existing scan watchdog/cancellation still bounds the whole operation. No network AI or record writes are added.

The offline fallback supports explicit multiline Each rows with conservatively matched adjacent named discounts, filters calculation/promotional rows out of product names, and accepts Unicode OCR tax markers and accented Costco product labels. It does not claim to repair all damaged names or dates. Affected entities remain transient ReceiptScan/ReceiptLine/ReceiptItemEvidence; no schema, CloudKit, permission or dependency changes.

Validation: 363 unit tests in 70 suites passed on the iPhone simulator, including multiline India Bazaar names/prices/discounts, line-total versus unit-price checks, invalid coupon partial recovery, Unicode suffixes and accented labels. This validates deterministic behavior, not model accuracy on Ravi's physical device. Build 83 is intended for internal testing with the diagnostic screen.

### Source-owned amounts — follow-up to build 83 device report

This supersedes the whole-receipt model row-link/retry pipeline above. OnDeviceReceiptExtractionService now starts with source-parsed products and money, then asks Foundation Models only to clean literal labels in batches of four (at most twelve labels per scan; larger baskets retain all original rows). AI returns no row IDs, prices or discount references and cannot alter amounts or product count. A label is accepted only if it equals the original or the exact leading-code-stripped original; it cannot remove size/brand words or substitute another product. No new networking, storage or schema changes. The model receives only candidate labels, not full receipt text/payment/member details. Existing explicit name-decoding suggestions remain a separate review action.

Exact same-SKU ALB/4LB pack-label variants combine using the numeric spelling already present on that receipt, not a generated correction. A first-glyph-damaged product SKU may use the immediately following coupon's matching numeric suffix as a monetary proposal, always marked for review. Non-adjacent or unrelated codes are not linked. This does not establish a permanent product alias or infer a purchase date. Internal diagnostics show AI label batches and rejected label proposals; original OCR and source-derived money remain visible independently.

### Weight / unit-price receipt tables — November 10, 2026

The offline parser now retains SKU-labelled products between an explicit Unit Price / Total Price header and subtotal. Product names and immediately following amount rows can be separate. A slash-suffixed unit price is never treated as the purchased line total; missing totals remain blank. Orphan amounts are not attached across intervening rows or products. Table results remain marked for review because OCR may omit whole products or damage labels. The supplied India Metro OCR recovers nine visible product candidates; it cannot recover the two product names missing from OCR. This changes transient ReceiptScan/ReceiptLine proposals only, with no record writes, schema, permissions, networking or dependencies. Physical-image OCR quality remains a separate limitation from parsing the supplied text.

## Receipt itemization gate — November 10, 2026

Receipt scanning is expense-first. The review always proposes store, date, total and currency for the user to confirm. Scanned item rows are proposed only when `ReceiptReconciliation` verifies them against the receipt's own printed numbers:

- every item has a readable amount that is not flagged for review;
- the items sum exactly (integer minor units) to the printed subtotal, and, when readable, subtotal + tax equals the total; or, for a receipt with no subtotal and no tax label, the items sum exactly to the total.

Otherwise the item list is hidden (not shown with warnings) and the user can save the expense and add pantry items manually. A missing list is preferred to a wrong price. Same-line prices (`Milk 4.00`) are kept as proposed amounts on the production scan path (`ReceiptRules.scan(text:sameLinePrices: true)`) because the gate rejects any set that does not reconcile. AI never contributes amounts. The internal Receipt debug screen reports the check result, item sum and printed subtotal/tax/total.

Unit tests cover the deterministic check against supplied OCR text only; they do not measure real-device OCR accuracy or how often real receipts reconcile.

### Expense-only retention and conflicting totals

Receipt-total evidence now distinguishes missing/unreadable values from contradictory readable values. Conflicting subtotal/tax/total evidence cannot enable itemization through another matching amount. Receipts still require user confirmation; a matching arithmetic sum is not proof of product identity.

The expense-first fallback can retain an image without any product rows. Images remain explicitly opt-in, compressed and local-only, and are reopened or removed from the expense using the existing receipt-derived storage ID. No placeholder shopping items, PurchaseEntry records or inventory changes are created for the attachment. No schema migration, CloudKit, permission or network changes. See `docs/validation/2026-11-10-receipt-reliability/README.md` for scope and validation limits.

## Store-free, multi-country receipt reading — November 11, 2026

Product decision: receipt reading contains no store-specific code. Layouts are recognized from the rows themselves; countries differ only in data.

- `ReceiptVocabulary`: subtotal, total, tax, discount and payment words for English, Indian bills (Net Amount, CGST/SGST/IGST, cess), German, French, Spanish, Italian, Dutch and Nordic receipts. Add a language by adding words.
- `ItemCodeReceiptDetails` (formerly Costco-only): turns on when product rows start with an item code or discount rows reference one (`CODE /ITEMCODE 8.00-`), whatever the store.
- `ReceiptColumns`: `NAME QTY [UNIT] RATE AMOUNT` columns (Indian Qty/Rate/Amount bills, weighed goods, `2 @ 3.99`) are accepted only when quantity × rate reproduces the line amount; a unit price is never the amount charged.
- Count × unit-price rows under a product (`2 Each @ $2.99/Each $5.98`, `2 x 1,29 2,58`) in any currency; discount rows in any supported language.
- Amounts: `1,234.56`, `1.234,56`, Indian `1,23,456.00`, decimal commas, currency before or after the number.
- `ReceiptReconciliation`: items may match the subtotal (tax added) or the total (tax-inclusive GST/VAT receipts, untaxed receipts).
- Store-name suggestion uses the offline store catalog plus the household's saved store names as data; no store is named in code.
- Expense currencies widened to 25 two-decimal currencies. Whole-unit currencies (JPY, KRW) and three-decimal ones (KWD, BHD) need a minor-unit migration first.

Validation: 407 unit tests pass, including synthetic India GST, German, UK, US and multilingual-label fixtures. Fixtures prove the general rules only; they do not measure real-device OCR or real receipt coverage.
