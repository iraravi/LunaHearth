import Foundation

protocol ReceiptNameDecodingService: Sendable {
    func decode(_ items: [ReceiptNameInput]) async throws -> ReceiptNameDecoding
}

struct ReceiptNameInput: Sendable, Encodable {
    let id: String
    let name: String
}

struct ReceiptNameProposal: Sendable {
    let id: String
    let original: String
    let name: String
}

struct ReceiptNameDecoding: Sendable {
    let proposals: [ReceiptNameProposal]
    let message: String
}

enum ReceiptNameRules {
    /// Treat generated text as untrusted, and never associate it with an invented row.
    static func proposal(index: Int, name: String, inputs: [ReceiptNameInput]) -> ReceiptNameProposal? {
        guard inputs.indices.contains(index) else { return nil }
        let original = inputs[index].name
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (2...100).contains(cleaned.count), cleaned.contains(where: \.isLetter),
              !cleaned.contains(where: { $0.isNewline || $0.asciiValue.map { $0 < 32 } == true }),
              !cleaned.contains("://"), original.contains(where: \.isLetter),
              cleaned.caseInsensitiveCompare(original) != .orderedSame else { return nil }
        return ReceiptNameProposal(id: inputs[index].id, original: original, name: cleaned)
    }

    static func canApply(_ proposal: ReceiptNameProposal, to line: ReceiptLine) -> Bool {
        line.id == proposal.id && line.name == proposal.original && line.included
    }
}
