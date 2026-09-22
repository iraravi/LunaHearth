import Foundation

struct TodayPantryItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let expiryDay: String?
    let isUsedUp: Bool
    let isLowStock: Bool
}

enum TodayAttentionRules {
    static func isOverdue(_ item: AssignedShoppingItem, today: String) -> Bool {
        item.later && item.day.map { ShoppingEntryRules.date(for: $0) != nil && $0 < today } == true
    }

    static func shopping(_ items: [AssignedShoppingItem], today: String) -> [AssignedShoppingItem] {
        items.filter { !$0.later || $0.day.map { ShoppingEntryRules.date(for: $0) != nil && $0 <= today } == true }
            .sorted {
                let first = isOverdue($0, today: today), second = isOverdue($1, today: today)
                if first != second { return first }
                if first, $0.day != $1.day { return ($0.day ?? "") < ($1.day ?? "") }
                return $0.name == $1.name ? $0.id.uuidString < $1.id.uuidString : $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
    }

    static func dates(_ items: [TodayPantryItem], today: String) -> [TodayPantryItem] {
        items.filter { !$0.isUsedUp && [.past, .today, .soon].contains(InventoryRules.expiryState($0.expiryDay, today: today)) }
            .sorted {
                if $0.expiryDay != $1.expiryDay { return ($0.expiryDay ?? "") < ($1.expiryDay ?? "") }
                return $0.id.uuidString < $1.id.uuidString
            }
    }

    /// One restock suggestion per ingredient, never an inferred combined pack quantity.
    static func restock(_ items: [TodayPantryItem]) -> [TodayPantryItem] {
        var seen = Set<String>()
        return items.filter { !$0.isUsedUp && $0.isLowStock }
            .sorted { $0.name == $1.name ? $0.id.uuidString < $1.id.uuidString : $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .filter { seen.insert(IngredientMatching.key($0.name)).inserted }
    }
}

/// Only aggregate counts enter the optional model. No identity, labels or private notes.
struct TodayBriefFacts: Equatable, Sendable, Codable {
    let shoppingNeededNow: Int
    let shoppingOverdue: Int
    let pantryDatesToCheck: Int
    let pantryPastExpiry: Int
    let lowStockIngredients: Int
    let eventsToday: Int
    let remindersDue: Int
    let homeCareAlerts: Int

    var fallback: String {
        var parts: [String] = []
        if shoppingNeededNow > 0 { parts.append("\(shoppingNeededNow) shopping \(shoppingNeededNow == 1 ? "item" : "items") needed now") }
        if pantryDatesToCheck > 0 { parts.append("\(pantryDatesToCheck) pantry \(pantryDatesToCheck == 1 ? "date" : "dates") to check") }
        if lowStockIngredients > 0 { parts.append("\(lowStockIngredients) low-stock \(lowStockIngredients == 1 ? "ingredient" : "ingredients")") }
        if eventsToday > 0 { parts.append("\(eventsToday) \(eventsToday == 1 ? "event" : "events") today") }
        if remindersDue > 0 { parts.append("\(remindersDue) \(remindersDue == 1 ? "reminder" : "reminders") due") }
        if homeCareAlerts > 0 { parts.append("\(homeCareAlerts) home care \(homeCareAlerts == 1 ? "alert" : "alerts")") }
        return parts.isEmpty ? "Nothing needs attention in your saved lists today." : parts.joined(separator: " · ") + "."
    }
}

struct TodayBrief: Sendable {
    let text: String
    let usedModel: Bool
}

protocol TodayBriefService: Sendable {
    func summarize(_ facts: TodayBriefFacts) async throws -> TodayBrief
}
