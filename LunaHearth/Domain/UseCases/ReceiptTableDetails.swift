import Foundation

/// Recover SKU-labelled products in weight/unit-price/line-total tables.
/// A slash-suffixed unit price is never promoted to a purchase amount.
enum ReceiptTableDetails {
    static func apply(text: String, lines: inout [ReceiptLine]) {
        let rows = text.components(separatedBy: .newlines)
        guard let header = rows.firstIndex(where: {
            $0.range(of: #"(?i)\b(?:unit\s*price|rate|price|mrp|preis|prix|precio|prezzo)\b"#, options: .regularExpression) != nil
                && $0.range(of: #"(?i)\b(?:total\s*price|amount|amt|value|total|betrag|montant|importe|importo)\b"#, options: .regularExpression) != nil
        }) else { return }
        let end = rows.indices.first(where: { $0 > header && rows[$0].range(of: #"(?i)^\s*(?:subtotal|sub total|grand total)\b"#, options: .regularExpression) != nil }) ?? rows.count
        guard end > header + 1 else { return }
        let namePattern = #"(?i)(?:(?:FS|IS|ES|0S)\s+)?[\p{L}][^$\n]*?-\s*(?:[S5]M)?\d{3,}[\p{L}]?"#
        let fingerprint = ReceiptRules.hash(text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " "))
        let starts = ((header + 1)..<end).filter { rows[$0].range(of: namePattern, options: .regularExpression) != nil }
        guard !starts.isEmpty else { return }
        for (offset, index) in starts.enumerated() {
            guard let nameRange = rows[index].range(of: namePattern, options: .regularExpression) else { continue }
            let sourceName = String(rows[index][nameRange])
            let name = sourceName.replacingOccurrences(of: #"(?i)^(?:FS|IS|ES|0S)\s+"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"-\s*(?:[S5]M)?\d{3,}[\p{L}]?$"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)
            let next = offset + 1 < starts.count ? starts[offset + 1] : end
            // Only the same row or immediately following calculation can own the price.
            // Never borrow a later orphan amount from an unreadable product.
            let sameRow = String(rows[index][nameRange.upperBound...])
            let evidence = hasMarkedAmount(sameRow) ? sameRow : (index + 1 < next ? rows[index + 1] : "")
            let amount = trailingTotal(evidence)
            let id = ReceiptRules.hash("\(fingerprint)|\(index)")
            lines.removeAll { $0.id == id || $0.name.contains(sourceName) }
            lines.append(ReceiptLine(id: id, name: name, amount: amount.map(ExpenseRules.amountText) ?? "", amountNeedsReview: true))
        }
    }

    /// Only a currency-marked amount counts as a table total; an unmarked number may be a
    /// weight or unit price.
    private static let markedAmount = #"(?:[₹$€£]|Rs\.?|INR|USD|EUR|GBP)\s*\d+[.,]\d{2}\s*$|\d+[.,]\d{2}\s*(?:€|EUR|zł|kr)\s*$"#
    private static func hasMarkedAmount(_ text: String) -> Bool {
        text.range(of: markedAmount, options: .regularExpression) != nil
    }
    private static func trailingTotal(_ text: String) -> Int? {
        guard let range = text.range(of: markedAmount, options: .regularExpression) else { return nil }
        return ExpenseRules.normalizedReceiptAmount(String(text[range])).flatMap { try? ExpenseRules.minorUnits($0) }
    }
}
