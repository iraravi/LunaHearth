import Foundation

/// Recognize explicit count × unit price rows printed under a product name, in any currency:
/// "2 Each @ $2.99/Each $5.98", "2 @ 2.99 5.98", "2 x 1,29 2,58". Never treat the calculation
/// as a product, and accept it only when count × unit price equals the printed line total.
enum ReceiptMultilineDetails {
    static func isQuantityRow(_ row: String) -> Bool { parts(row) != nil }
    static func lineAmount(_ row: String) -> Int? {
        guard let p = parts(row), let count = Int(p[0]), count > 0, count <= 999,
              let unit = try? ExpenseRules.minorUnits(p[1]),
              let total = try? ExpenseRules.minorUnits(p[2]), count * unit == total else { return nil }
        return total
    }
    private static func parts(_ row: String) -> [String]? {
        let money = #"(?:"# + ExpenseRules.currencyPattern + #")?\s*(\d+[.,]\d{2})"#
        return captures(#"(?i)^\s*(\d{1,3})\s*(?:each|ea|pcs?|nos?|x|×|st|stk)?\s*(?:@|x|×)\s*"# + money
            + #"\s*(?:/\s*(?:each|ea|pc|pcs|unit|st|stk))?\s*[A-Z]?\s*"# + money + #"\s*[A-Z]?\s*$"#, row)
    }
    static func apply(text: String, lines: inout [ReceiptLine]) {
        let rows = text.components(separatedBy: .newlines)
        let fingerprint = ReceiptRules.hash(text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " "))
        for index in rows.indices where index > 0 {
            guard let gross = lineAmount(rows[index]), let p = parts(rows[index]) else { continue }
            var start = index - 1
            func isName(_ value: String) -> Bool {
                let value = value.trimmingCharacters(in: .whitespaces)
                return value.contains(where: \.isLetter) && !ReceiptRules.isNonProductRow(value) &&
                    value.range(of: #"(?i)(\d+[.,]\d{2}|\b(?:total|tax|discount|sale|cashier|customer|terminal|open|member)\b)"#, options: .regularExpression) == nil &&
                    value.count <= 120
            }
            guard isName(rows[start]) else { continue }
            // A short continuation like BAZAAR 200G belongs to the preceding product line.
            if start > 0, rows[start].split(separator: " ").count <= 2, isName(rows[start - 1]) { start -= 1 }
            let name = rows[start..<index].map { $0.trimmingCharacters(in: .whitespaces) }.joined(separator: " ")
            guard name.count <= 200 else { continue }
            var net = gross
            var needsReview = false
            if index + 1 < rows.count, ReceiptVocabulary.contains(ReceiptVocabulary.discount, in: rows[index + 1]) {
                let discountLine = rows[index + 1]
                let deduction = #"(?:[-−]\s*(?:"# + ExpenseRules.currencyPattern + #")?\s*(\d+[.,]\d{2})|(\d+[.,]\d{2})\s*[-−])\s*$"#
                if let amount = captures(deduction, discountLine)?.first.flatMap({ try? ExpenseRules.minorUnits($0) }), amount <= gross {
                    let tokens = name.lowercased().split(whereSeparator: { !$0.isLetter }).filter { $0.count >= 4 }
                    if tokens.filter({ discountLine.lowercased().contains($0) }).count >= 2 { net -= amount }
                    else { needsReview = true }
                } else { needsReview = true }
            }
            let id = ReceiptRules.hash("\(fingerprint)|\(start)")
            guard !lines.contains(where: { $0.id == id }) else { continue }
            lines.append(ReceiptLine(id: id, name: name, quantity: "\(p[0]) pieces", amount: ExpenseRules.amountText(net), amountNeedsReview: needsReview))
        }
    }
    private static func captures(_ pattern: String, _ text: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) else { return nil }
        return (1..<match.numberOfRanges).compactMap { Range(match.range(at: $0), in: text).map { String(text[$0]) } }
    }
}
