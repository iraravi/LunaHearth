import Foundation

protocol ReceiptTextExtracting: Sendable {
    func extract(text: String) async throws -> ReceiptScan
}

struct ReceiptItemEvidence: Sendable {
    let row: Int
    let name: String
    var printedPrice: String = ""
    var discountRows: [Int] = []
    var priceRow: Int? = nil
}

struct ReceiptValidationFailure: Error, Sendable {
    let reason: String
}

enum ReceiptExtractionRules {
    /// AI chooses products; validation requires literal OCR evidence, not invented names
    /// or money. Returning nil preserves the deterministic/manual fallback in full.
    static func validate(_ proposals: [ReceiptItemEvidence], text: String) -> [ReceiptLine]? {
        try? evaluate(proposals, text: text).get()
    }

    static func evaluate(_ proposals: [ReceiptItemEvidence], text: String) -> Result<[ReceiptLine], ReceiptValidationFailure> {
        guard !proposals.isEmpty, proposals.count <= 80 else { return .failure(.init(reason: "Expected 1–80 product proposals.")) }
        let rows = text.components(separatedBy: .newlines)
        let productRows = ItemCodeReceiptDetails.productSection(text).components(separatedBy: .newlines).count
        let fingerprint = ReceiptRules.hash(text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " "))
        var seen = Set<Int>()
        var lines: [ReceiptLine] = []
        var usedDiscounts = Set<Int>()
        var usedPrices = Set<Int>()
        for proposal in proposals.sorted(by: { $0.row < $1.row }) {
            let name = proposal.name.trimmingCharacters(in: .whitespacesAndNewlines)
            let priceRow = proposal.priceRow ?? proposal.row
            guard rows.indices.contains(proposal.row), rows.indices.contains(priceRow),
                  priceRow >= proposal.row, priceRow <= proposal.row + 3,
                  usedPrices.insert(priceRow).inserted else { return .failure(.init(reason: "Invalid or reused product price row.")) }
            let nameSource = rows[proposal.row...max(proposal.row, priceRow - 1)].joined(separator: " ")
            if priceRow != proposal.row {
                guard ReceiptMultilineDetails.isQuantityRow(rows[priceRow]),
                      rows[proposal.row..<priceRow].allSatisfy({ money(in: $0).isEmpty && !ReceiptRules.isNonProductRow($0) }) else {
                    return .failure(.init(reason: "Product row \(proposal.row): unsupported multiline price association."))
                }
            }
            guard rows.indices.contains(proposal.row), proposal.row < productRows,
                  seen.insert(proposal.row).inserted, (2...200).contains(name.count),
                  !name.contains(where: { $0.isNewline || $0.isASCII && $0.asciiValue.map { $0 < 32 } == true }),
                  name.contains(where: \.isLetter),
                  nameSource.range(of: name, options: .caseInsensitive) != nil,
                  !ReceiptRules.isNonProductRow(rows[proposal.row]),
                  rows[proposal.row].range(of: #"(?i)^\W*(?:sub\s*total|total|tax|amount|payment|change|visa|mastercard|cash|savings|discount|coupon|refund)\b"#, options: .regularExpression) == nil else { return .failure(.init(reason: "Product row \(proposal.row): invalid index, duplicate row, nonliteral name or excluded metadata.")) }
            guard proposal.discountRows.count <= 12 else { return .failure(.init(reason: "Product row \(proposal.row): too many discount links.")) }
            var amount: Int?
            if !proposal.printedPrice.isEmpty {
                guard let printed = try? ExpenseRules.minorUnits(proposal.printedPrice),
                      (priceRow == proposal.row ? money(in: rows[priceRow]) == [printed] : ReceiptMultilineDetails.lineAmount(rows[priceRow]) == printed), printed > 0 else { return .failure(.init(reason: "Product row \(proposal.row): price does not match the money on that OCR row.")) }
                amount = printed
            }
            for discountRow in proposal.discountRows {
                guard rows.indices.contains(discountRow), discountRow != proposal.row, discountRow != priceRow,
                      !proposals.contains(where: { $0.row == discountRow }),
                      usedDiscounts.insert(discountRow).inserted else { return .failure(.init(reason: "Product row \(proposal.row): discount row is invalid, reused or also a product.")) }
                let values = money(in: rows[discountRow])
                guard values.count == 1, let discount = values.first, discount < 0 else { return .failure(.init(reason: "Discount row \(discountRow): expected one negative price.")) }
                // A discount row that references an item code must reference this product's code.
                if let referenced = capture(#"/\s*(\d{4,})\b"#, rows[discountRow]) {
                    guard let sku = capture(#"^(?:[EA]\s+)?(\d{4,})\s+"#, rows[proposal.row]),
                          referenced == sku else { return .failure(.init(reason: "Discount row \(discountRow): SKU does not match the product.")) }
                }
                if let current = amount { amount = current + discount }
            }
            if let value = amount, value < 0 { return .failure(.init(reason: "Product row \(proposal.row): discounts exceed the price.")) }
            let amountText = amount.map(ExpenseRules.amountText) ?? ""
            // Preserve source-row identity used by receipt re-import protection.
            if let index = lines.firstIndex(where: { IngredientMatching.same($0.name, name) }) {
                if let existing = try? ExpenseRules.minorUnits(lines[index].amount), let amount {
                    lines[index].amount = ExpenseRules.amountText(existing + amount)
                } else { lines[index].amount = ""; lines[index].amountNeedsReview = true }
            } else {
                lines.append(ReceiptLine(id: ReceiptRules.hash("\(fingerprint)|\(proposal.row)"), name: name,
                    amount: amountText, amountNeedsReview: amount == nil))
            }
        }
        // AI amounts remain proposals and must reconcile independently of sales tax.
        if let subtotal = capture(#"(?im)^\s*SUB\s*TOTAL\s*[:$₹€£]?\s*(\d[\d,]*\.\d{2})\s*$"#, text),
           let expected = try? ExpenseRules.minorUnits(subtotal) {
            let amounts = lines.map { try? ExpenseRules.minorUnits($0.amount) }
            if amounts.contains(where: { $0 == nil }) || amounts.compactMap({ $0 }).reduce(0, +) != expected {
                for index in lines.indices { lines[index].amountNeedsReview = true }
            }
        }
        return .success(lines)
    }
    static func recover(_ proposals: [ReceiptItemEvidence], text: String) -> [ReceiptLine]? {
        let eligible = proposals.filter { proposal in
            guard proposals.filter({ $0.row == proposal.row }).count == 1,
                  proposals.filter({ ($0.priceRow ?? $0.row) == (proposal.priceRow ?? proposal.row) }).count == 1,
                  proposal.discountRows.allSatisfy({ discount in
                      proposals.filter { $0.discountRows.contains(discount) }.count == 1 &&
                      !proposals.contains { $0.row == discount || $0.priceRow == discount }
                  }) else { return false }
            return validate([proposal], text: text) != nil
        }
        guard !eligible.isEmpty, var lines = validate(eligible, text: text) else { return nil }
        // Partial results always require comparison for omitted products/discounts.
        for index in lines.indices { lines[index].amountNeedsReview = true }
        return lines
    }

    private static func capture(_ pattern: String, _ text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return String(text[range])
    }

    private static func money(in text: String) -> [Int] {
        let pattern = #"(?<![A-Za-z0-9])([-−]?[₹$€£]?\s*\d[\d,]*\.\d{2}[-−]?)(?![0-9])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            guard let range = Range(match.range(at: 1), in: text) else { return nil }
            let token = String(text[range])
            let negative = token.contains("-") || token.contains("−")
            let number = token.filter { $0.isNumber || $0 == "." || $0 == "," }
            guard let value = try? ExpenseRules.minorUnits(number) else { return nil }
            return negative ? -value : value
        }
    }

}
