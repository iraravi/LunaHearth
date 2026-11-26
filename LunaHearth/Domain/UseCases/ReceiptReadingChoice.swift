import Foundation

/// Which OCR reading of a receipt photo produced a text.
enum ReceiptReadingSource: String, Sendable, CaseIterable {
    /// Apple's layout-aware document reader (iOS 26+): keeps each table row's name and price together.
    case layout
    /// Line-by-line text recognition with spelling correction off, so codes and prices stay literal.
    case plain
    /// Line-by-line recognition with spelling correction on: the pre-3.0 reading, kept as a last resort
    /// because it sometimes reads faded product words better.
    case corrected

    var label: String {
        switch self {
        case .layout: "layout reader"
        case .plain: "plain reader"
        case .corrected: "spelling-corrected reader"
        }
    }
}

struct ReceiptReading: Sendable, Equatable {
    var source: ReceiptReadingSource
    var text: String
}

/// Picks the reading to show. The receipt's own printed totals decide, never the reader:
/// a reading whose items add up to the cent wins; otherwise one with a one-tap fix; otherwise the
/// one closest to the printed subtotal. Ties keep the earlier (preferred) reader.
enum ReceiptReadingChoice {
    struct Score: Sendable, Equatable {
        var verified: Bool
        var fixable: Bool
        /// Cents between the item sum and the printed subtotal or total; nil when not comparable.
        var gap: Int?
        var items: Int
    }

    static func score(_ text: String) -> Score {
        let lines = ReceiptRules.scan(text: text, sameLinePrices: true).lines
        let verified = ReceiptReconciliation.check(lines: lines, text: text) == .verified
        let fixable = !verified && !ReceiptGapHints.hints(lines: lines, text: text).isEmpty
        let gap = ReceiptReconciliation.difference(lines: lines, text: text).map { abs($0.items - $0.printed) }
        return Score(verified: verified, fixable: fixable, gap: gap, items: lines.count)
    }

    static func best(_ readings: [ReceiptReading]) -> (reading: ReceiptReading, score: Score)? {
        let scored = readings.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { ($0, score($0.text)) }
        guard !scored.isEmpty else { return nil }
        if let hit = scored.first(where: { $0.1.verified }) { return (hit.0, hit.1) }
        if let hit = scored.first(where: { $0.1.fixable }) { return (hit.0, hit.1) }
        let ranked = scored.enumerated().min { a, b in
            let left = (a.element.1.items == 0 ? 1 : 0, a.element.1.gap ?? Int.max, a.offset)
            let right = (b.element.1.items == 0 ? 1 : 0, b.element.1.gap ?? Int.max, b.offset)
            return left < right
        }!.element
        return (ranked.0, ranked.1)
    }
}

/// Evidence check for items read by the on-device model from the photo. The model may only
/// propose; its list is used only when it adds up to the printed totals read by OCR AND every
/// amount is backed by numbers printed on the receipt, so an invented price cannot get through.
enum ReceiptModelReadingCheck {
    static func accepts(_ lines: [ReceiptLine], text: String, evidence: [String]) -> Bool {
        guard (1...100).contains(lines.count),
              ReceiptReconciliation.check(lines: lines, text: text) == .verified else { return false }
        let printed = printedAmounts(evidence + [text])
        return lines.allSatisfy { line in
            guard let minor = try? ExpenseRules.minorUnits(line.amount) else { return false }
            return supported(minor, by: printed)
        }
    }

    /// An amount is backed when it is printed, or is one printed amount plus or minus another
    /// (a repeated item, an item after its coupon), or a small multiple of one (2 × 4.97).
    static func supported(_ amount: Int, by printed: Set<Int>) -> Bool {
        guard amount > 0 else { return false }
        if printed.contains(amount) { return true }
        if (2...9).contains(where: { amount % $0 == 0 && printed.contains(amount / $0) }) { return true }
        let values = Array(printed.prefix(400))
        for a in values {
            if printed.contains(amount - a) || printed.contains(a - amount) { return true }
        }
        return false
    }

    static func printedAmounts(_ texts: [String]) -> Set<Int> {
        var result = Set<Int>()
        let pattern = try! NSRegularExpression(pattern: #"(?<![\d])(\d{1,6})[.,](\d{2})(?![\d])"#)
        for text in texts {
            let bounded = String(text.prefix(40_000))
            let range = NSRange(bounded.startIndex..., in: bounded)
            for match in pattern.matches(in: bounded, range: range) {
                guard let whole = Range(match.range(at: 1), in: bounded), let cents = Range(match.range(at: 2), in: bounded),
                      let w = Int(bounded[whole]), let c = Int(bounded[cents]) else { continue }
                result.insert(w * 100 + c)
            }
        }
        return result
    }
}
