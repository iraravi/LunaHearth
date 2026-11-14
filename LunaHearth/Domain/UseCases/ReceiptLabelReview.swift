import Foundation

/// A model cannot rename a product to another product or remove its distinguishing words.
enum ReceiptLabelReview {
    static func validated(_ proposal: String, original: String) -> String? {
        let trimmed = proposal.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleaned = original.replacingOccurrences(of: #"^(?:[EA]\s+)?\d{4,}\s+"#, with: "", options: .regularExpression)
        guard !trimmed.isEmpty, trimmed.count <= 200,
              trimmed.caseInsensitiveCompare(original) == .orderedSame || trimmed.caseInsensitiveCompare(cleaned) == .orderedSame else { return nil }
        return trimmed
    }
}
