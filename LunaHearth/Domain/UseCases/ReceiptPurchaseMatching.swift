import Foundation

struct ReceiptPurchaseCandidate: Identifiable, Sendable, Equatable {
    let id: UUID
    let name: String
    let quantity: String
    let merchant: String
    let day: String
    let alreadyLinked: Bool
}

/// Matching is a review aid, never permission to add or subtract stock.
/// Include unknown/different stores so a missing merchant cannot hide a possible double entry.
enum ReceiptPurchaseMatching {
    static func candidates(name: String, day: String, purchases: [ReceiptPurchaseCandidate]) -> [ReceiptPurchaseCandidate] {
        guard let date = ShoppingEntryRules.date(for: day) else { return [] }
        let calendar = Calendar(identifier: .gregorian)
        return purchases.filter {
            guard IngredientMatching.same(name, $0.name), let bought = ShoppingEntryRules.date(for: $0.day),
                  let distance = calendar.dateComponents([.day], from: bought, to: date).day else { return false }
            return abs(distance) <= 7
        }.sorted { ($0.day, $0.id.uuidString) > ($1.day, $1.id.uuidString) }
    }
}
