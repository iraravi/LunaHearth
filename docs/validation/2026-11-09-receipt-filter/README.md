# Receipt non-product row filtering

Shared receipt parsing now rejects structured payment authorization fields, card/payment method rows, service/delivery fees, tips, deposits, item counts, reward summaries, contact URLs/email addresses, promotional footer text and standalone weight/unit-price calculations before proposing inventory items.

Affected domain: receipt review proposals only. Existing purchases, expenses, pantry records and schema are unchanged. Original OCR text is retained for review and expense extraction. Processing remains entirely offline; no permissions, services or AI dependencies added.

Patterns are anchored to receipt field syntax where practical, so products such as Service tray, Shipping tape, Tip Top Bread and Card game remain valid. Parsing does not stop at the first total: real products can occur later in mixed OCR layouts. Existing repeated-item and Costco discount handling remains unchanged.

Validation: 23 parameterized non-product row cases plus a legitimate-product/mixed-order regression. Full unit suite and simulator build results recorded below when complete. These tests use sanitized text; they do not establish accuracy for every photographed receipt or OCR corruption.

Verified November 9, 2026:
- `xcodegen generate`: passed.
- iPhone 18 Pro Max simulator (iOS 27.0) build: passed.
- Full LunaHearthTests unit target: 341 tests across 65 suites passed, including all 23 new parameterized cases and the mixed-order/product-name test.
- `git diff --check`: passed.
- No upload or live-release change performed. A new build is required to distribute this fix.
