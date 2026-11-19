import Foundation

/// Item-level savings printed directly under the item they belong to, before the subtotal:
/// loyalty and member savings, coupons and percentage discounts ("PRO XTRA SAVINGS -1.00",
/// "Circle 5% -$0.25", "CARD SAVINGS 1.00-"). A layout pattern, never a per-store rule.
///
/// Conservative by design: a discount is applied only when exactly one listed item sits above
/// it and its amount is readable and no larger than that item. Anything else leaves amounts
/// untouched for `ReceiptReconciliation` to verify or hide.
enum ReceiptItemDiscounts {
    static func apply(text: String, lines: inout [ReceiptLine]) {
        let rows = ItemCodeReceiptDetails.productSection(String(text.prefix(40_000)))
            .components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        let subtotal = rows.firstIndex { $0.range(of: ReceiptVocabulary.label(ReceiptVocabulary.subtotal + ReceiptVocabulary.total), options: .regularExpression) != nil } ?? rows.count
        for index in rows.indices where index < subtotal {
            guard let discount = discountAmount(rows[index]), let target = itemRow(above: index, in: rows) else { continue }
            let row = normalized(target)
            let matches = lines.indices.filter { !lines[$0].amount.isEmpty && row.contains(normalized(lines[$0].name)) && !normalized(lines[$0].name).isEmpty }
            guard matches.count == 1, let line = matches.first,
                  let amount = try? ExpenseRules.minorUnits(lines[line].amount), discount <= amount else { continue }
            lines[line].amount = ExpenseRules.amountText(amount - discount)
        }
    }

    /// A row with letters and exactly one amount, printed as negative (leading or trailing minus).
    /// Rows that reference an item code ("/1234567 2.00-") belong to `ItemCodeReceiptDetails`.
    static func discountAmount(_ row: String) -> Int? {
        guard row.contains(where: \.isLetter), row.range(of: #"/\s*\d{4,}"#, options: .regularExpression) == nil,
              row.range(of: ReceiptRules.excludedRow, options: .regularExpression) == nil || ReceiptVocabulary.contains(ReceiptVocabulary.discount, in: row) else { return nil }
        let pattern = #"(?<![\d.,])([-−]\s*[₹$€£]?\s*\d{1,6}[.,]\d{2}|[₹$€£]?\s*\d{1,6}[.,]\d{2}\s*[-−])(?![\d])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let money = row.range(of: #"\d[.,]\d{2}\b"#, options: .regularExpression)
        let negatives = regex.matches(in: row, range: NSRange(row.startIndex..., in: row))
        guard negatives.count == 1, let range = Range(negatives[0].range(at: 1), in: row), money != nil,
              row.components(separatedBy: CharacterSet(charactersIn: "0123456789").inverted).filter({ $0.count >= 1 }).count <= 4 else { return nil }
        let digits = row[range].filter { $0.isNumber || $0 == "." || $0 == "," }
        return try? ExpenseRules.minorUnits(String(digits))
    }

    /// The nearest product row above: quantity rows ("4 @ 2.49 9.96") have no product words and are skipped.
    private static func itemRow(above index: Int, in rows: [String]) -> String? {
        var cursor = index - 1
        while cursor >= 0, index - cursor <= 3 {
            let row = rows[cursor]
            let words = row.split(separator: " ").filter { $0.filter(\.isLetter).count >= 3 }
            if discountAmount(row) != nil { return nil } // two discounts in a row: leave for review
            if !words.isEmpty, !ReceiptRules.isNonProductRow(row) { return row }
            cursor -= 1
        }
        return nil
    }

    private static func normalized(_ text: String) -> String {
        text.lowercased().filter { $0.isLetter || $0.isNumber || $0 == " " }
            .split(separator: " ").joined(separator: " ")
    }
}
