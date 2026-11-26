# Receipt test set

Each `.txt` file is one real receipt that the app once misread. `ReceiptCorpusTests` runs every
file through the same reader the app uses, so a fix for a new receipt can't break an old one.

## Adding a receipt

1. In an Internal build, scan the receipt, open **Receipt debug** and tap **Share debug text**.
2. Copy the rows under `NUMBERED OCR TEXT`, without the `[n]` numbers.
3. Remove personal details: names, member numbers, card digits, payment IDs, phone numbers.
   Keep store, item, discount and total rows exactly as read, misreads included.
4. Put the expected result at the top:

   ```
   #! verified
   #! item HOLIDAY BOWL | 6.99
   ```

   `verified` means the items must add up to the printed totals. One `item` row per expected
   line: a part of its name and its net amount. Leave `verified` out for a receipt that is
   honestly unreadable; the item rows then describe what it should still list.
5. Save as `store-what-went-wrong.txt` and run `-only-testing:LunaHearthTests/ReceiptCorpusTests`.
