import Foundation

/// Whether a scanned item list may be shown as a proposal.
/// Items are shown only when their printed amounts add up, to the cent, to the receipt's own
/// printed totals. Anything else hides the list: a missing item is safer than a wrong price.
enum ReceiptItemization: Equatable, Sendable {
    case verified
    case unverified(ReceiptItemizationGap)
}

enum ReceiptItemizationGap: Equatable, Sendable {
    /// No product rows were found.
    case noItems
    /// At least one item has no readable amount or was flagged for review.
    case uncertainAmounts
    /// The receipt has no readable subtotal/total to check against, or it is ambiguous.
    case noPrintedTotals
    /// Items, subtotal, tax and total disagree.
    case mismatch
}

struct ReceiptPrintedTotals: Equatable, Sendable {
    var subtotal: Int?
    var tax: Int?
    var total: Int?
    /// True when a tax-like label was seen, even if its amount was unreadable or ambiguous.
    var taxLabelSeen = false
    /// Receipt-level discounts printed between the subtotal and the total (e.g. a store-card
    /// percentage), in minor units. They reduce the taxable amount, never an item.
    var discounts = 0
    /// Readable but contradictory values cannot be treated as absent and bypassed.
    var hasConflictingAmounts = false
}

enum ReceiptReconciliation {
    static func check(lines: [ReceiptLine], text: String) -> ReceiptItemization {
        guard !lines.isEmpty else { return .unverified(.noItems) }
        var sum = 0
        for line in lines {
            guard !line.amountNeedsReview, let minor = try? ExpenseRules.minorUnits(line.amount) else {
                return .unverified(.uncertainAmounts)
            }
            sum += minor
        }
        let printed = totals(text)
        guard !printed.hasConflictingAmounts else { return .unverified(.noPrintedTotals) }
        if let subtotal = printed.subtotal, sum == subtotal {
            // When the header totals are readable they must agree too; an unreadable total
            // (e.g. a lost decimal point) does not invalidate a matching subtotal.
            if let total = printed.total {
                guard let tax = printed.tax ?? (printed.taxLabelSeen ? nil : 0) else { return .unverified(.noPrintedTotals) }
                guard subtotal - printed.discounts + tax == total else { return .unverified(.mismatch) }
            }
            return .verified
        }
        // Tax-inclusive receipts (most GST and VAT bills) and untaxed receipts: item prices
        // already include tax, so they add up to the amount charged. The printed tax rows are
        // then a breakdown, not an addition.
        if let total = printed.total, sum == total { return .verified }
        // A readable subtotal or total that the items do not reproduce is a mismatch.
        return printed.subtotal != nil || printed.total != nil ? .unverified(.mismatch) : .unverified(.noPrintedTotals)
    }

    static func totals(_ text: String) -> ReceiptPrintedTotals {
        let rows = String(text.prefix(40_000)).components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: #"^[*★]+\s*"#, with: "", options: .regularExpression) }
            .filter { !$0.isEmpty }
        let subtotalLabel = ReceiptVocabulary.label(ReceiptVocabulary.subtotal)
        // Allow a short region prefix such as "TEXAS TAX"; reject rate tables like "TAX 8.25%".
        let taxLabel = #"(?i)^(?:\p{L}+\s+){0,2}(?:"# + ReceiptVocabulary.alternation(ReceiptVocabulary.tax) + #")(?![\p{L}])\s*[:=]?\s*"#
        // A tax-marker legend prefix ("T = TX TAX ...") names the items taxed, not the label.
        let taxRows = rows.map { $0.replacingOccurrences(of: #"^[A-Z]{1,2}\s*=\s*"#, with: "", options: .regularExpression) }
        var printed = ReceiptPrintedTotals()
        let subtotals = amounts(rows, label: subtotalLabel)
        printed.subtotal = subtotals.count == 1 ? subtotals.first : nil
        printed.hasConflictingAmounts = subtotals.count > 1
        printed.taxLabelSeen = taxRows.contains { row in
            row.range(of: taxLabel, options: .regularExpression) != nil
        }
        let plainTaxes = amounts(taxRows.filter { !$0.contains("%") && ratedTax($0) == nil }, label: taxLabel)
        let plainTax = plainTaxes.count == 1 ? plainTaxes.first : nil
        printed.hasConflictingAmounts = printed.hasConflictingAmounts || plainTaxes.count > 1
        let rated = taxRows.compactMap(ratedTax)
        if rated.isEmpty {
            printed.tax = plainTax
        } else if rated.allSatisfy({ $0 != nil }) {
            // "TAX 8.25000 on $29.39 $2.42": the amount must equal rate × base to the cent.
            let sum = rated.compactMap { $0 }.reduce(0, +)
            printed.tax = plainTax == nil || plainTax == sum ? sum : nil
            if let plainTax, plainTax != sum {
                printed.hasConflictingAmounts = true
            }
        }
        let totalEvidence = ExpenseRules.receiptTotalEvidence(text)
        printed.total = totalEvidence.amount.flatMap { try? ExpenseRules.minorUnits($0) }
        printed.hasConflictingAmounts = printed.hasConflictingAmounts || totalEvidence == .conflicting
        if printed.subtotal != nil,
           let subtotalRow = rows.firstIndex(where: { $0.range(of: subtotalLabel, options: .regularExpression) != nil }),
           let totalRow = rows[(subtotalRow + 1)...].firstIndex(where: {
               $0.range(of: ReceiptVocabulary.label(ReceiptVocabulary.strongTotal + ReceiptVocabulary.total), options: .regularExpression) != nil
           }) {
            printed.discounts = taxRows[(subtotalRow + 1)..<totalRow]
                .filter { $0.range(of: taxLabel, options: .regularExpression) == nil }
                .compactMap(receiptDiscount).reduce(0, +)
        }
        return printed
    }

    /// A rated tax row with its taxable base. Returns nil when the row is not this layout,
    /// `.some(nil)` when the printed amount does not equal rate × base.
    private static func ratedTax(_ row: String) -> Int?? {
        let pattern = #"(?i)^(?:[a-z]+\s+){0,2}(?:sales\s+)?(?:tax|gst|vat|hst|pst)\s+(\d{1,2}(?:\.\d{1,5})?)\s*%?\s+on\s+[₹$€£]?\s*(\d[\d,]*\.\d{2})\s+[₹$€£]?\s*(\d[\d,]*\.\d{2})\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: row, range: NSRange(row.startIndex..., in: row)) else { return nil }
        let parts = (1...3).compactMap { Range(match.range(at: $0), in: row).map { String(row[$0]) } }
        guard parts.count == 3, let rate = Decimal(string: parts[0], locale: Locale(identifier: "en_US_POSIX")),
              let base = minor(parts[1]), let amount = minor(parts[2]) else { return .some(nil) }
        let expected = Decimal(base) * rate / 100
        let difference = expected - Decimal(amount)
        return .some(difference > -1 && difference < 1 ? amount : nil)
    }

    /// One amount explicitly marked as a deduction ("-$1.00", "$0.33 -"), or labelled as a
    /// percentage discount. Positive charges such as bag fees are never subtracted.
    private static func receiptDiscount(_ row: String) -> Int? {
        let pattern = #"(?<![\w.,])([-−]\s*)?[₹$€£]?\s*([-−]\s*)?(\d[\d.,]*[.,]\d{2})(?!\d)(\s*[-−])?"#
        guard row.contains(where: \.isLetter), let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = regex.matches(in: row, range: NSRange(row.startIndex..., in: row))
        guard matches.count == 1, let match = matches.first,
              let valueRange = Range(match.range(at: 3), in: row), let value = minor(String(row[valueRange])) else { return nil }
        let marked = [1, 2, 4].contains { match.range(at: $0).location != NSNotFound }
        let labelled = ReceiptVocabulary.contains(ReceiptVocabulary.discount, in: row)
            || row.range(of: #"(?i)\d\s*%\s*off\b|\bcard\s+\d{1,2}(?:\.\d+)?\s*%"#, options: .regularExpression) != nil
        return marked || labelled ? value : nil
    }

    private static func minor(_ value: String) -> Int? {
        if value.range(of: #"^0+[.,]00$"#, options: .regularExpression) != nil { return 0 }
        return ExpenseRules.normalizedReceiptAmount(value).flatMap { try? ExpenseRules.minorUnits($0) }
    }

    /// Retain all readable values so contradictory evidence is not lost as nil.
    private static func amounts(_ rows: [String], label: String) -> Set<Int> {
        let found = rows.compactMap { row -> Int? in
            guard let range = row.range(of: label, options: .regularExpression) else { return nil }
            let value = String(row[range.upperBound...]).trimmingCharacters(in: .whitespaces)
            if value.range(of: #"^(?:[₹$€£]\s*)?0[.,]00$"#, options: .regularExpression) != nil { return 0 }
            return ExpenseRules.normalizedReceiptAmount(value).flatMap { try? ExpenseRules.minorUnits($0) }
        }
        return Set(found)
    }
}
