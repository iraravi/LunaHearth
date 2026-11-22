import Foundation

/// Fixes one misread digit using the receipt's own numbers. A camera can read 1.99 as 1.98;
/// when the printed subtotal, tax and total agree with each other, they show exactly how much
/// the items are off. If exactly one printed item price becomes right by changing exactly one
/// digit, that price is corrected and marked so the user can see it. Anything else (two
/// candidates, totals that disagree, a gap no single digit explains) changes nothing.
enum ReceiptDigitCorrection {
    static func correct(_ lines: [ReceiptLine], text: String) -> [ReceiptLine]? {
        guard ReceiptReconciliation.check(lines: lines, text: text) == .unverified(.mismatch) else { return nil }
        let printed = ReceiptReconciliation.totals(text)
        // The gap must be proven by two printed numbers that agree with each other.
        guard !printed.hasConflictingAmounts, let subtotal = printed.subtotal, let total = printed.total,
              let tax = printed.tax ?? (printed.taxLabelSeen ? nil : 0),
              subtotal - printed.discounts + tax == total else { return nil }
        let amounts = lines.compactMap { try? ExpenseRules.minorUnits($0.amount) }
        guard amounts.count == lines.count else { return nil }
        let gap = subtotal - amounts.reduce(0, +)
        guard gap != 0 else { return nil }
        let printedValues = printedAmounts(text)
        let candidates = amounts.indices.filter { index in
            let fixed = amounts[index] + gap
            return fixed > 0 && printedValues.contains(amounts[index]) && oneDigitApart(amounts[index], fixed)
        }
        guard candidates.count == 1, let index = candidates.first else { return nil }
        var corrected = lines
        corrected[index].correctedFrom = corrected[index].amount
        corrected[index].amount = ExpenseRules.amountText(amounts[index] + gap)
        return ReceiptReconciliation.check(lines: corrected, text: text) == .verified ? corrected : nil
    }

    /// True when the two amounts print with the same number of digits and differ in exactly one,
    /// and that digit is a pair cameras commonly confuse on receipt print (3↔8, 5↔6, 1↔7, ...).
    /// A gap that needs any other change is more likely a missing item than a misread digit.
    static func oneDigitApart(_ a: Int, _ b: Int) -> Bool {
        let x = Array(ExpenseRules.amountText(a)), y = Array(ExpenseRules.amountText(b))
        guard x.count == y.count else { return false }
        let changed = zip(x, y).filter { $0 != $1 }
        guard changed.count == 1, let pair = changed.first else { return false }
        return confusable.contains([pair.0, pair.1]) || confusable.contains([pair.1, pair.0])
    }

    private static let confusable: Set<[Character]> = [
        ["0", "6"], ["0", "8"], ["0", "9"], ["1", "7"], ["1", "4"], ["2", "7"],
        ["3", "8"], ["3", "5"], ["5", "6"], ["5", "8"], ["6", "8"], ["8", "9"],
    ]

    /// Every money-looking value printed on the receipt, so only a printed price is ever changed.
    private static func printedAmounts(_ text: String) -> Set<Int> {
        guard let regex = try? NSRegularExpression(pattern: #"(?<![\d.,])\d{1,6}[.,]\d{2}(?!\d)"#) else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return Set(regex.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).flatMap { try? ExpenseRules.minorUnits(text[$0].replacingOccurrences(of: ",", with: ".")) }
        })
    }
}
