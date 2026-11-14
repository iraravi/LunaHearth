import Foundation

/// One item proposed by an image-capable model. Untrusted until validated.
struct ReceiptImageProposal: Sendable, Equatable {
    var name: String
    var lineTotal: String
}

/// Turns image-model proposals into review lines for the internal receipt lab.
/// The model never decides whether a list is shown: `ReceiptReconciliation` checks the
/// proposals against subtotal/tax/total read from OCR, not from the model.
enum ReceiptImageProposalRules {
    static func lines(_ proposals: [ReceiptImageProposal], text: String) -> [ReceiptLine] {
        let fingerprint = ReceiptRules.hash(text)
        return proposals.prefix(100).enumerated().compactMap { index, proposal in
            let name = proposal.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard (2...200).contains(name.count), name.rangeOfCharacter(from: .letters) != nil else { return nil }
            let amount = ExpenseRules.normalizedReceiptAmount(proposal.lineTotal) ?? ""
            return ReceiptLine(id: ReceiptRules.hash("\(fingerprint)|image|\(index)"), name: name,
                               amount: amount, amountNeedsReview: amount.isEmpty)
        }
    }

    /// Whether an amount is printed anywhere in the OCR text. Net amounts after a discount
    /// are legitimately absent, so this is reported, not enforced.
    static func isPrinted(_ amount: String, in text: String) -> Bool {
        guard !amount.isEmpty else { return false }
        let pattern = #"(?<![\d.,])"# + NSRegularExpression.escapedPattern(for: amount) + #"(?![\d])"#
        return text.range(of: pattern, options: .regularExpression) != nil
    }
}
