# Receipt reading architecture

Receipts from thousands of stores are read without any per-store code. Store knowledge is **data**; layouts are **general patterns**; every result is **checked against the printed totals** before items are shown.

```
OCR text (Vision, on device)
   │
   ├─ Store name ── ShoppingStoreCatalog (data: chains + printed spellings)
   │                → learned store fingerprints (ReceiptCorrectionMemory, on this phone)
   │                → header heuristics (website match, junk-line filter)
   │
   ├─ Items ────── ReceiptRules.scan (one shared pipeline)
   │                 1. row filters: totals, tax, payment, card, hours never become items
   │                 2. layout readers, each a general pattern:
   │                    ReceiptColumns          NAME QTY RATE AMOUNT tables (Indian GST bills)
   │                    ReceiptMultilineDetails item row, then "4 @ 2.49 9.96" quantity row
   │                    ReceiptTableDetails     column layouts
   │                    ItemCodeReceiptDetails  code-first rows and "/code" deductions (warehouse clubs)
   │                    ReceiptItemDiscounts    savings/coupon row directly under one item
   │                 3. shared cleanup: leading product codes and tax letters never stay in names
   │
   ├─ Check ────── ReceiptReconciliation: items must reproduce subtotal (+ tax − discounts = total).
   │                Tax lines: plain, "rate on base amount", or "rate% amount" (accepted only when
   │                rate × subtotal matches to the cent). Unverified receipts show store/date/total
   │                only and ask the person to check items — nothing wrong is saved silently.
   │
   └─ Names ────── offline abbreviations → remembered corrections → on-device AI suggestions,
                    always shown beside the printed label for review.
```

## Adding support

| Need | Change | Never |
|---|---|---|
| A chain's name is not recognised | Add it (and how it is printed) to `ShoppingStoreCatalog.stores` | A store-specific parser |
| A new layout pattern | Extend or add one general reader; add a pattern test named after the pattern | `if store == …` branches |
| A real receipt fails | Save its text (personal details removed) as a test, fix the general rule it exposes | Tune numbers to one receipt |
| A new word for total/tax/discount | `ReceiptVocabulary` | Hard-coded strings in readers |

## Tests

- `ReceiptLayoutPatternTests`: US and Indian layout patterns reconstructed from public descriptions (fictional stores, no personal data). Replace with real receipts as they arrive.
- Real-receipt tests: Costco, H-E-B, India Bazaar, Target and others in `LunaHearthTests/Receipt*Tests.swift`.
