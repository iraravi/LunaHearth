# 2.0.2 (91) — Receipts learn from corrections

Changes since 90:
1. Store name detection: a printed website picks the matching header words (India Bazaar), and show-through fragments, hours, phones and priced lines are never used as the store name.
2. Learning from corrections (on this phone only): the store name saved with a receipt is remembered against the store's phone, website and street address; item names renamed before saving are suggested ("You named it") the next time the same printed label appears.
3. India Bazaar (Frisco) receipt added as a permanent test.

Validation: 440 unit tests passed; receipt UI tests passed (review and import, bill name beside decoded name, mutton matching).
