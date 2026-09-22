import Foundation
import SwiftData

extension LocalHouseholdRepository {
    func duplicateShoppingItem(_ name: String, excluding id: UUID? = nil) -> GroceryItem? {
        let key = IngredientMatching.key(name)
        guard !key.isEmpty else { return nil }
        return groceries.first { $0.id != id && !$0.isCompleted && IngredientMatching.key($0.name) == key }
    }
    func matchingStore(_ name: String, branch: String = "") -> ShoppingStore? {
        let canonical = ShoppingStoreCatalog.canonicalName(name)
        let key = ShoppingStoreCatalog.key(ShoppingStore.label(name: canonical, branch: branch.trimmingCharacters(in: .whitespacesAndNewlines)))
        return stores.first { ShoppingStoreCatalog.key($0.displayName) == key }
    }
    func applyShoppingDetails(_ draft: EntryDraft, to item: GroceryItem) throws {
        item.quantityText = try ShoppingEntryRules.quantityText(draft.quantity, unit: draft.quantityUnit)
        item.quantityAmount = draft.quantityUnit == .custom ? nil : try ShoppingEntryRules.amount(draft.quantity, unit: draft.quantityUnit)
        item.quantityUnit = draft.quantityUnit == .custom ? nil : draft.quantityUnit.rawValue
        item.plannedDay = draft.neededLater ? HouseholdDay(draft.shoppingDate).key : nil
    }
    var shoppingStoreNames: [String] {
        ShoppingStoreCatalog.savedNames(stores.map(\.displayName) + groceries.compactMap(\.storeName))
    }
    func shoppingStoreName(for item: GroceryItem) -> String {
        if let id = item.storeID, let store = stores.first(where: { $0.id == id }) { return store.displayName }
        return ShoppingStoreCatalog.canonicalName(item.storeName ?? "", saved: shoppingStoreNames)
    }
    @discardableResult func addStore(name: String, branch: String = "") throws -> ShoppingStore {
        guard let home = household else { throw HouseholdValidation.invalidReference }
        let name = try HouseholdRules.requiredName(ShoppingStoreCatalog.canonicalName(name))
        let branch = branch.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        let label = try HouseholdRules.requiredName(ShoppingStore.label(name: name, branch: branch))
        var result: ShoppingStore?
        try commit { result = try resolveStore(label, householdID: home.id, name: name, branch: branch.isEmpty ? nil : branch) }
        guard let result else { throw HouseholdValidation.invalidReference }
        return result
    }
    /// Called inside the same transaction as the item write.
    func resolveStore(_ label: String, householdID: UUID, name: String? = nil, branch: String? = nil) throws -> ShoppingStore? {
        let existing = try context.fetch(FetchDescriptor<ShoppingStore>()).filter { $0.householdID == householdID }
        let canonical = ShoppingStoreCatalog.canonicalName(label, saved: existing.map(\.displayName))
        if canonical.isEmpty { return nil }
        _ = try HouseholdRules.requiredName(canonical)
        let id = ShoppingStore.stableID(householdID: householdID, label: canonical)
        if let store = existing.first(where: { $0.id == id || ShoppingStoreCatalog.key($0.displayName) == ShoppingStoreCatalog.key(canonical) }) { return store }
        let store = ShoppingStore(id: id, householdID: householdID, name: name ?? canonical, branch: branch)
        context.insert(store)
        return store
    }
    /// Additive upgrade: preserve original labels as a fallback for older records.
    func backfillShoppingStores(_ items: [GroceryItem], householdID: UUID) throws -> Bool {
        var changed = false
        for item in items where item.storeID == nil {
            let label = item.storeName ?? ""
            guard !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, label.count <= 200 else { continue }
            if let store = try resolveStore(label, householdID: householdID) {
                item.storeID = store.id; item.modifiedAt = .now; changed = true
            }
        }
        return changed
    }
}
