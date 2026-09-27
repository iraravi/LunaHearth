import Foundation

extension LocalHouseholdRepository {
    /// Presence is not a quantity guarantee. Explicit restock states remain eligible.
    var stockedShoppingSuggestionNames: [String] {
        let today = HouseholdDay(Date()).key
        return inventory.filter {
            !$0.isUsedUp && $0.isLowStock != true && ($0.expiryDay.map { $0 >= today } ?? true)
        }.map(\.name)
    }

    /// One reviewed batch commits atomically, after rechecking current household and list.
    func addShoppingSuggestions(_ items: [ShoppingSuggestion], householdID: UUID, store: String, buyer: UUID?, neededLater: Bool = false, plannedDate: Date? = nil) throws -> Int {
        try FeatureAccess.require(.shoppingIdeas)
        if buyer != nil { try FeatureAccess.require(.shoppingAssignments) }
        guard household?.id == householdID else { throw HouseholdValidation.invalidReference }
        if let buyer, !members.contains(where: { $0.id == buyer }) { throw HouseholdValidation.invalidReference }
        let store = ShoppingStoreCatalog.canonicalName(store, saved: shoppingStoreNames)
        if !store.isEmpty { _ = try HouseholdRules.requiredName(store) }
        guard items.count <= 8 else { throw HouseholdValidation.longName }
        for item in items {
            _ = try HouseholdRules.requiredName(item.name)
            guard item.quantity.count <= 100 else { throw HouseholdValidation.longName }
        }
        let reviewed = ShoppingSuggestionRules.reviewed(items, excluding: groceries.filter { !$0.isCompleted }.map(\.name) + stockedShoppingSuggestionNames)
        try commit {
            let destination = reviewed.isEmpty ? nil : try resolveStore(store, householdID: householdID)
            for item in reviewed {
                let grocery = GroceryItem(householdID: householdID, name: item.name, quantityText: item.quantity, storeName: destination?.displayName, storeID: destination?.id, neededLater: neededLater, assignedMemberID: buyer)
                grocery.plannedDay = neededLater ? plannedDate.map { HouseholdDay($0).key } : nil
                context.insert(grocery)
            }
        }
        return reviewed.count
    }
}
