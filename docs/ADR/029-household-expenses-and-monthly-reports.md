# ADR-029: Household expenses and monthly reports

Status: Accepted. User explicitly requested expense tracking under Home, receipt integration and a clean monthly spending/report dashboard. This records authorization to add the household financial tracking domain in AGENTS §18.

## Scope and experience

Home → Expenses joins manual expenses and reviewed receipt purchases in one place. The dashboard shows spending in the selected calendar month/currency, purchase count, refunds and net when applicable, six-month spending, category totals and searchable purchase/refund history. Month arrows browse history; currency selection never converts or combines unlike currencies. Category/search filters affect history only; export contains the complete selected month and currency. USD, INR, EUR, GBP, CAD and AUD use two minor units. No rates, bank connections, credentials, financial advice, budget inference or external service is introduced.

Manual entry requires store/payee, positive total, currency, date and category. Refund is an explicit type with a positive recorded amount and negative report contribution. Total means the final paid amount after tax/discounts. Users can edit or confirm deletion; changing an expense never rewrites inventory or shopping. Expense records are household data, visible to members through existing optional sharing, stated in the entry flow.

Receipt review can record an expense in the same atomic transaction as shopping/inventory updates. Only explicitly labeled total lines propose an amount; subtotal, savings and payment amounts are not totals. The amount, merchant, currency and date require review. Currency starts from supported device-region preference and date starts as today; neither is silently deduced from ambiguous receipt formatting. Excluding grocery lines does not reduce the full-receipt expense total. Zero grocery lines is valid for an expense-only receipt, while disabling expense recording preserves the prior shopping/pantry-only flow. Receipt photos/raw text remain transient, as in ADR-028. Refund entry is manual; receipt scanning proposes purchases.

## Model, sync and migration

New normalized SwiftData entity HouseholdExpense has locally stable UUID, householdID, merchant, civil day YYYY-MM-DD, positive integer amountMinorUnits, ISO currencyCode, categoryRawValue, isRefund, optional notes/receiptKey, createdAt and modifiedAt. Optional receipts use deterministic expense UUIDs derived from household and normalized OCR fingerprint. No floating-point money is persisted. Existing records receive no fabricated expense history.

Expense participates in backup encode/decode/validation, household-scoped reloads, global UUID collision protection, custom-zone payload allowlists, merge/conflict handling, tombstones and local reset. Deletion propagates with the established sync baseline mechanism. Automatic SwiftData CloudKit mirroring stays disabled. No new CloudKit record type is needed: explicit LHHouseholdEntity payload mapping carries the new kind. Older app builds reject unknown expense kinds safely; upgrade all sharing devices before creating expenses. The local schema change adds a model without deleting or converting current data.

Exact normalized receipt fingerprints skip already-recorded expense totals, including when additional previously excluded grocery lines are imported. Existing expense totals are never overwritten silently on repeat import. Different OCR text or deleted expense history can defeat repeat detection; review is still essential. Failed validation or read-only/recovery state saves neither expense nor grocery/inventory changes. Core entry, reporting and export work offline. CSV export occurs only after a user action and includes formula-prefix escaping for free text.

## Validation boundaries

Tests cover exact decimal conversion/limits, currency isolation, month/year boundaries, refunds, expense create/edit/delete and backup restore, receipt atomicity/replay, malformed totals, expense-only receipts, CSV escaping, read-only rejection and fake-server shared updates/tombstones. Simulator UI covers manual entry, totals/month navigation and integrated receipt confirmation; screenshot checks cover phone/tablet presentation. These do not verify actual retailer receipt accuracy, real camera permissions or live two-account CloudKit delivery.

## Reusing shopping stores — build 25

Expense and receipt store/payee fields now read the existing household shopping-store names, including saved branches and legacy shopping labels. Matching saved stores appear as compact choices before/during typing; Browse opens the established shopping store picker. Selecting a saved store fills its canonical label. Expense writes also canonicalize matching spelling, without creating a new ShoppingStore for an arbitrary payee such as rent. Explicit store creation remains available in the existing picker. Expense merchant text remains a historical snapshot rather than a live foreign-key rename relationship. No schema, permissions or cloud changes; existing private household store synchronization supplies the suggestions.
