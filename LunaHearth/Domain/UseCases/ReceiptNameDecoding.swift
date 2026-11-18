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
    var fromSavedItem = false
    var fromAI = false

    /// Where the suggestion came from, shown beside the name printed on the bill.
    var sourceLabel: String { fromSavedItem ? "Your saved item" : fromAI ? "AI says" : "Decoded" }
}

struct ReceiptNameDecoding: Sendable {
    let proposals: [ReceiptNameProposal]
    let message: String
}

enum ReceiptNameRules {
    /// Review-only equivalence for compact printed labels. Never drops brand, flavor,
    /// size or dietary words, and never promotes a numeric SKU to a product name.
    static func compactMatch(_ receipt: String, _ saved: String) -> Bool {
        func key(_ name: String) -> String {
            let abbreviations = ["chocolate": "choc", "organic": "org", "greek": "grk", "yogurt": "yog"]
            return IngredientMatching.normalized(name).split(separator: " ").map {
                abbreviations[String($0)] ?? String($0)
            }.joined()
        }
        let a = key(receipt), b = key(saved)
        return a.count >= 5 && a.contains(where: \.isLetter) && a == b
    }

    /// A saved name is useful evidence, but ambiguous choices still need manual selection.
    static func savedProposal(for line: ReceiptLine, names: [String]) -> ReceiptNameProposal? {
        let matches = Set(names.filter { compactMatch(line.name, $0) })
        guard matches.count == 1, let name = matches.first,
              var result = proposal(index: 0, name: name, inputs: [ReceiptNameInput(id: line.id, name: line.name)]) else { return nil }
        result.fromSavedItem = true
        return result
    }

    /// Offline decode of printed abbreviations, shown for review like any other suggestion.
    static func abbreviationProposal(for line: ReceiptLine) -> ReceiptNameProposal? {
        guard let name = ReceiptAbbreviations.expand(line.name) else { return nil }
        return proposal(index: 0, name: name, inputs: [ReceiptNameInput(id: line.id, name: line.name)])
    }

    /// Treat generated text as untrusted, and never associate it with an invented row.
    static func proposal(index: Int, name: String, inputs: [ReceiptNameInput]) -> ReceiptNameProposal? {
        guard inputs.indices.contains(index) else { return nil }
        let original = inputs[index].name
        let cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (2...100).contains(cleaned.count), cleaned.contains(where: \.isLetter),
              !cleaned.contains(where: { $0.isNewline || $0.asciiValue.map { $0 < 32 } == true }),
              !cleaned.contains("://"), original.contains(where: \.isLetter),
              cleaned.caseInsensitiveCompare(original) != .orderedSame else { return nil }
        // Reject a shortened suffix masquerading as an expansion: FAIRLIFECHOC
        // must not become just Chocolate, which changes the product's identity.
        func compact(_ value: String) -> String {
            value.lowercased().replacingOccurrences(of: "chocolate", with: "choc")
                .filter { $0.isLetter || $0.isNumber }
        }
        let source = compact(original), suggestion = compact(cleaned)
        guard !(source.hasSuffix(suggestion) && source.count - suggestion.count >= 3) else { return nil }
        return ReceiptNameProposal(id: inputs[index].id, original: original, name: cleaned)
    }

    static func canApply(_ proposal: ReceiptNameProposal, to line: ReceiptLine) -> Bool {
        line.id == proposal.id && line.name == proposal.original && line.included
    }
}
