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
    /// A suggestion for explicit review, not interchangeable pantry identity.
    /// Only permit known qualifiers and cuts around a generic meat request.
    static func possibleMatch(receipt: String, requested: String) -> Bool {
        if IngredientMatching.same(receipt, requested) || ReceiptNameRules.compactMatch(receipt, requested) { return true }
        let qualifiers: Set<String> = ["premium", "fresh", "organic", "frozen"]
        func words(_ name: String) -> [String] {
            IngredientMatching.normalized(name).split(separator: " ").map(String.init).filter { !qualifiers.contains($0) }
        }
        let a = words(receipt), b = words(requested)
        guard !a.isEmpty, !b.isEmpty else { return false }
        if a == b { return true }
        let meats: Set<String> = ["mutton", "chicken", "beef", "pork", "lamb", "goat", "turkey"]
        let cuts: Set<String> = ["leg", "legs", "breast", "thigh", "thighs", "shoulder", "chops", "chop", "boneless", "bone", "in", "whole", "minced", "ground", "cubes", "diced"]
        func generic(_ broad: [String], _ specific: [String]) -> Bool {
            guard broad.count == 1, let meat = broad.first, meats.contains(meat), specific.contains(meat) else { return false }
            return specific.allSatisfy { $0 == meat || cuts.contains($0) }
        }
        return generic(a, b) || generic(b, a)
    }

    static func candidates(name: String, day: String, purchases: [ReceiptPurchaseCandidate]) -> [ReceiptPurchaseCandidate] {
        guard let date = ShoppingEntryRules.date(for: day) else { return [] }
        let calendar = Calendar(identifier: .gregorian)
        return purchases.filter {
            guard ReceiptPurchaseMatching.possibleMatch(receipt: name, requested: $0.name), let bought = ShoppingEntryRules.date(for: $0.day),
                  let distance = calendar.dateComponents([.day], from: bought, to: date).day else { return false }
            return abs(distance) <= 7
        }.sorted { ($0.day, $0.id.uuidString) > ($1.day, $1.id.uuidString) }
    }
}

/// Transient confirmation bound to the exact labels reviewed, never persisted as model authority.
struct ReceiptShoppingApproval: Sendable, Equatable {
    let groceryID: UUID
    let receiptName: String
    let shoppingName: String
    func validates(id: UUID, receipt: String, shopping: String) -> Bool {
        groceryID == id && receiptName == receipt && shoppingName == shopping
    }
}

protocol ReceiptShoppingComparisonService: Sendable {
    func compareReceipt(name: String, candidates: [String]) async throws -> IngredientComparison
}
