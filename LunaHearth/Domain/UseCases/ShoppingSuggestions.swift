import Foundation

struct ShoppingSuggestion: Identifiable, Sendable, Equatable {
    let id: UUID
    var name: String
    var quantity: String
    init(name: String, quantity: String = "") { id = UUID(); self.name = name; self.quantity = quantity }
}

struct ShoppingSuggestionRequest: Sendable {
    let prompt: String
    let recentItems: [String]
    let pendingItems: [String]
    var pantryItems: [String] = []
}

struct ShoppingSuggestionResult: Sendable {
    let items: [ShoppingSuggestion]
    let usedModel: Bool
    let explanation: String
}

protocol ShoppingSuggestionService: Sendable {
    func suggest(_ request: ShoppingSuggestionRequest) async throws -> ShoppingSuggestionResult
}

/// Suggestions never write records. Normalize and validate model output just like user input.
enum ShoppingSuggestionRules {
    static func key(_ name: String) -> String {
        IngredientMatching.key(name)
    }
    static func reviewed(_ items: [ShoppingSuggestion], excluding pending: [String]) -> [ShoppingSuggestion] {
        var seen = Set(pending.map(key))
        return items.prefix(20).compactMap { item in
            let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.count <= 200, item.quantity.count <= 100, seen.insert(key(name)).inserted else { return nil }
            return ShoppingSuggestion(name: name, quantity: item.quantity.trimmingCharacters(in: .whitespacesAndNewlines))
        }.prefix(8).map { $0 }
    }
    static func fallback(_ request: ShoppingSuggestionRequest, reason: String) -> ShoppingSuggestionResult {
        let history = reviewed(request.recentItems.map { ShoppingSuggestion(name: $0) }, excluding: request.pendingItems + request.pantryItems)
        let basics = reviewed(["Milk", "Eggs", "Bread", "Rice", "Fruit", "Vegetables"].map { ShoppingSuggestion(name: $0) }, excluding: request.pendingItems + request.pantryItems)
        return ShoppingSuggestionResult(items: history.isEmpty ? basics : history, usedModel: false,
            explanation: reason + (history.isEmpty ? " Here are starter ideas to review; they are not AI-generated or based on your request." : " These are previously checked items to review; they are not AI-generated."))
    }
}
