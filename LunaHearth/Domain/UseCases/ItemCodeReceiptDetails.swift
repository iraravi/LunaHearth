import Foundation

/// Item-code layout, used by warehouse clubs and many POS systems worldwide: one
/// "CODE NAME PRICE" row per purchased unit, and discount rows that reference the item code
/// ("CODE /ITEMCODE 8.00-"). Detected from the rows themselves, never from a store name.
/// Enrich only exact, priced code rows; never infer package contents from an item code.
enum ItemCodeReceiptDetails {
    /// True when discount rows reference item codes, or several products start with one.
    static func usesItemCodes(_ text: String) -> Bool {
        let rows = String(text.prefix(40_000)).components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        // "CODE /ITEMCODE amount-": a deduction that names the item it applies to, even if its
        // amount is unreadable.
        if rows.contains(where: { $0.range(of: #"(?:^|\s)/\s*\d{4,}\s+\S+"#, options: .regularExpression) != nil }) { return true }
        // A product row that starts with an item code ("E 1485984 FAIRLIFECHOC 39.99").
        return rows.contains(where: isCodedProductRow)
    }

    /// "CODE NAME PRICE": the row must end with a price-like token (digits split by a separator,
    /// even a damaged one) so street addresses, PIN codes and barcodes alone never qualify.
    static func isCodedProductRow(_ row: String) -> Bool {
        row.trimmingCharacters(in: .whitespaces)
            .range(of: #"^(?:[EA]\s+)?\d{4,}\s+\p{L}.*?\s\S*\d[^\d\s]+\d\S*(?:\s+[A-Za-z])?$"#, options: .regularExpression) != nil
    }

    /// Item-code products precede the subtotal. Keep the complete OCR separately for
    /// expense extraction; damaged footer labels must never become stock candidates.
    /// Only a summary row after the first product counts: headers such as "TAX INVOICE" or a
    /// store named "TOTAL …" come before the items and must not cut them off.
    static func productSection(_ text: String) -> String {
        guard usesItemCodes(text) else { return text }
        let rows = text.components(separatedBy: "\n")
        guard let first = rows.firstIndex(where: isCodedProductRow),
              let boundary = rows[(first + 1)...].firstIndex(where: {
                  $0.range(of: #"(?i)^\s*(?:SUB\s*TOTAL|TAX|\W*TOTAL)\b"#, options: .regularExpression) != nil
              }) else { return text }
        return rows[..<boundary].joined(separator: "\n")
    }

    private static func packLabel(_ name: String) -> String {
        name.replacingOccurrences(of: #"^A(?=LB\b)"#, with: "4", options: .regularExpression)
    }

    static func apply(text: String, lines: inout [ReceiptLine]) {
        guard usesItemCodes(text) else { return }
        struct Item {
            var name: String
            var count: Int
            var total: Int
            var valid = true
            var aliases: Set<String> = []
            var needsReview = false
        }
        var items: [String: Item] = [:]
        var discounts: [String: Int] = [:]
        // Item codes whose deduction row is present but unreadable: never guess its amount.
        var unreadableDiscounts = Set<String>()
        func captures(_ pattern: String, _ line: String) -> [String]? {
            guard let regex = try? NSRegularExpression(pattern: pattern),
                  let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) else { return nil }
            return (1..<match.numberOfRanges).compactMap { Range(match.range(at: $0), in: line).map { String(line[$0]) } }
        }
        let sourceRows = productSection(String(text.prefix(40_000))).components(separatedBy: .newlines)
        for (rowIndex, raw) in sourceRows.enumerated() {
            let row = raw.trimmingCharacters(in: .whitespaces)
            if let part = captures(#"^(?:[EA]\s+)?[0-9A-Z]{4,}\s+/\s*(\d{4,})\s+(\d{1,6}\.\d{2})[-−]\s*[\p{L}]?\s*$"#, row),
               let amount = try? ExpenseRules.minorUnits(part[1]) {
                discounts[part[0], default: 0] += amount
            } else if let part = captures(#"^(?:[EA]\s+)?[0-9A-Z]{4,}\s+/\s*(\d{4,})\s+\S+"#, row) {
                unreadableDiscounts.insert(part[0])
            } else if let part = captures(#"^(?:[EA]\s+)?(\d{4,})\s+([\p{L}0-9][\p{L}0-9 &.'/-]*?)\s+(\d{1,6}\.\d{2})\s*[A-Za-z]?$"#, row),
                      let amount = try? ExpenseRules.minorUnits(part[2]) {
                let key = part[0], name = part[1]
                if var item = items[key] {
                    item.valid = item.valid && (item.name == name || packLabel(item.name) == packLabel(name))
                    item.aliases.insert(name)
                    if name.first?.isNumber == true { item.name = name }
                    item.count += 1; item.total += amount; items[key] = item
                } else { items[key] = Item(name: name, count: 1, total: amount, aliases: [name]) }
            } else if let part = captures(#"^(?:[EA]\s+)?([A-Z][0-9]{3,})\s+([\p{L}][\p{L}0-9 &.'/-]*?)\s+(\d{1,6}\.\d{2})\s*[A-Za-z]?$"#, row),
                      rowIndex + 1 < sourceRows.count,
                      let coupon = captures(#"^(?:[EA]\s+)?[0-9A-Z]{4,}\s+/\s*(\d{4,})\s+(\d+\.\d{2})[-−]\s*[\p{L}]?\s*$"#, sourceRows[rowIndex + 1].trimmingCharacters(in: .whitespaces)),
                      part[0].count == coupon[0].count, part[0].dropFirst() == coupon[0].dropFirst(),
                      items[coupon[0]] == nil,
                      let amount = try? ExpenseRules.minorUnits(part[2]),
                      let discount = try? ExpenseRules.minorUnits(coupon[1]), discount < amount {
                // A damaged first SKU glyph is only a review proposal, supported by
                // the immediately following coupon's numeric reference. Never persist an alias.
                items[coupon[0]] = Item(name: part[1], count: 1, total: amount,
                    aliases: [part[1], part[0] + " " + part[1]], needsReview: true)
            }
        }
        // Keep readable SKU/name rows when the price is unreadable. They must be
        // reviewed rather than silently disappearing from the basket. Never recover
        // coupon rows or infer a price from malformed numeric OCR.
        for raw in productSection(String(text.prefix(40_000))).components(separatedBy: .newlines) {
            guard let part = captures(#"^(?:[EA]\s+)?(\d{4,})\s+([A-Za-z][A-Za-z &.'/\-]+?)\s+[^\sA-Za-z0-9]*\d[^\s]*[^0-9A-Za-z.,\s][^\s]*\s*[A-Za-zА]?$"#, raw.trimmingCharacters(in: .whitespaces)) else { continue }
            let name = part[1].trimmingCharacters(in: .whitespaces)
            guard !lines.contains(where: { IngredientMatching.same($0.name, name) }) else { continue }
            lines.append(ReceiptLine(id: ReceiptRules.hash("\(text)|unpriced|\(part[0])"), name: name, amountNeedsReview: true))
        }
        var consumed = Set<String>()
        var redundant = Set<Int>()
        for index in lines.indices {
            let matches = items.filter { $0.value.aliases.contains(lines[index].name) }
            guard matches.count == 1, let (sku, item) = matches.first, item.valid else { continue }
            let net = item.total - discounts[sku, default: 0]
            guard net > 0 else { continue }
            guard consumed.insert(sku).inserted else { redundant.insert(index); continue }
            lines[index].name = item.name
            lines[index].amountNeedsReview = item.needsReview || unreadableDiscounts.contains(sku)
            lines[index].quantity = item.count == 1 ? "1 piece" : "\(item.count) pieces"
            lines[index].amount = ExpenseRules.amountText(net)
        }
        lines = lines.enumerated().filter { !redundant.contains($0.offset) }.map(\.element)
        // Whether these amounts may be shown is decided for every receipt by
        // ReceiptReconciliation (subtotal, or total for tax-inclusive receipts).
    }
}
