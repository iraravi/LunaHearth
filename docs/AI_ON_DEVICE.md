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
