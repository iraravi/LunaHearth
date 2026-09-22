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
