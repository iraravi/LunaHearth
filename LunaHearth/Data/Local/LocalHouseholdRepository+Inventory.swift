import Foundation
import SwiftData

extension LocalHouseholdRepository {
    @discardableResult func saveInventory(_ draft: InventoryDraft, editing id: UUID? = nil, allowSeparatePack: Bool = false) throws -> UUID {
        try InventoryRules.validate(draft)
        guard let home = household?.id else { throw HouseholdValidation.invalidReference }
        let existing = id.flatMap { id in inventory.first { $0.id == id } }
        guard id == nil || existing != nil else { throw HouseholdValidation.invalidReference }
        guard allowSeparatePack || !inventory.contains(where: { $0.id != id && !$0.isUsedUp && IngredientMatching.same($0.name, draft.name) }) else { throw InventoryError.duplicateIngredient }
        let item = existing ?? InventoryItem(householdID: home, name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines))
        try commit {
            let store = try resolveStore(draft.storeName, householdID: home)
            item.name = try HouseholdRules.requiredName(draft.name)
            item.quantityText = draft.measuredUnit.flatMap { unit in PantryAmount.number(draft.measuredAmount).map { PantryAmount(amount: $0, unit: unit).text } } ?? InventoryRules.optional(draft.quantity);
            if draft.measuredUnit != nil { item.isUsedUp = PantryAmount.number(draft.measuredAmount) == 0 }; item.packDetails = InventoryRules.optional(draft.packDetails)
            item.storeID = store?.id; item.storeName = store?.displayName
            item.location = InventoryRules.optional(draft.location)
            item.packedDay = draft.hasPackedDate ? HouseholdDay(draft.packedDate).key : nil
            item.expiryDay = draft.hasExpiryDate ? HouseholdDay(draft.expiryDate).key : nil
            item.purchasedDay = draft.hasPurchasedDate ? HouseholdDay(draft.purchasedDate).key : nil
            item.isLowStock = draft.isLowStock
            item.modifiedAt = .now
            if existing == nil { context.insert(item) }
        }
        return item.id
    }
    /// Shopping and inventory commit together. A deterministic UUID prevents duplicate receipt
    /// imports or the same purchase being added independently on two offline devices.
    func recordPurchase(_ grocery: GroceryItem, addToInventory: Bool, keeping existingID: UUID? = nil, allowSeparatePack: Bool = false) throws {
        if addToInventory { try FeatureAccess.require(.shoppingToPantry) }
        guard let home = household?.id, grocery.householdID == home, groceries.contains(where: { $0.id == grocery.id }) else { throw HouseholdValidation.invalidReference }
        let alreadyStocked = grocery.purchaseDisposition == "inventory"
        let matches = inventory.filter { InventoryRules.canRestock(isUsedUp: $0.isUsedUp, expiryDay: $0.expiryDay) && IngredientMatching.same($0.name, grocery.name) }
        if addToInventory && !alreadyStocked {
            if let existingID {
                guard matches.contains(where: { $0.id == existingID }) else { throw HouseholdValidation.invalidReference }
            } else if !allowSeparatePack && !matches.isEmpty {
                throw InventoryError.duplicateIngredient
            }
        }
        try commit {
            if addToInventory {
                if !alreadyStocked, let existingID, let item = matches.first(where: { $0.id == existingID }) {
                    // Only compatible measured amounts or matching package counts can be added.
                    if let amount = RestockQuantity.combined(existing: item.quantityText, purchased: grocery.quantityText) { item.quantityText = amount }
                    item.isLowStock = false
                    item.modifiedAt = .now
                }
                let id = InventoryRules.purchaseID(householdID: home, groceryID: grocery.id)
                if !alreadyStocked && existingID == nil && !inventory.contains(where: { $0.id == id }) {
                    let item = InventoryItem(id: id, householdID: home, name: grocery.name)
                    item.quantityText = grocery.quantityText; item.storeID = grocery.storeID; item.storeName = grocery.storeName
                    item.sourceGroceryID = grocery.id; item.purchasedDay = HouseholdDay(.now).key
                    context.insert(item)
                }
                grocery.purchaseDisposition = "inventory"
            } else {
                // Never delete an existing inventory pack when a shopping record is reopened.
                // Stocking is a receipt of a completed side effect. Preserve it even if the
                // shopping row is reopened and finished elsewhere, so retries cannot restock twice.
                if !alreadyStocked { grocery.purchaseDisposition = "elsewhere" }
            }
            if !alreadyStocked {
                let historyID = ReceiptRules.groceryID(home: home, key: "shopping-purchase|" + grocery.id.uuidString)
                let stockID = addToInventory ? (existingID ?? InventoryRules.purchaseID(householdID: home, groceryID: grocery.id)) : nil
                appendPurchase(id: historyID, purchaseID: historyID, grocery: grocery, inventoryID: stockID, expenseID: nil,
                    day: HouseholdDay(.now).key, action: addToInventory ? (existingID == nil ? "added" : "restocked") : "elsewhere")
            }
            grocery.isCompleted = true; grocery.modifiedAt = .now
        }
    }
    func addPantryIdeas(_ names: [String], householdID: UUID) throws {
        try FeatureAccess.require(.pantryTemplates)
        guard household?.id == householdID else { throw HouseholdValidation.invalidReference }
        let reviewed = PantrySuggestionRules.reviewed(names, existing: inventory.filter { !$0.isUsedUp }.map(\.name))
        try commit { for name in reviewed { context.insert(InventoryItem(householdID: householdID, name: name)) } }
    }
    func setInventoryUsedUp(_ item: InventoryItem, usedUp: Bool) throws {
        guard inventory.contains(where: { $0.id == item.id }) else { throw HouseholdValidation.invalidReference }
        try commit { item.isUsedUp = usedUp; item.modifiedAt = .now }
    }
    func deleteInventory(_ item: InventoryItem) throws {
        guard inventory.contains(where: { $0.id == item.id }) else { throw HouseholdValidation.invalidReference }
        try commit { context.delete(item) }
    }
    func restockInventory(_ item: InventoryItem) throws {
        guard inventory.contains(where: { $0.id == item.id }) else { throw HouseholdValidation.invalidReference }
        guard duplicateShoppingItem(item.name) == nil else { throw InventoryError.alreadyShopping }
        var draft = EntryDraft(kind: .grocery, title: item.name)
        draft.storeName = item.storeName ?? ""
        // Quantity is intentionally left open: the remaining pack is not a reorder amount.
        try add(draft)
    }
}

extension InventoryDraft {
    @MainActor init(_ item: InventoryItem) {
        isLowStock = item.isLowStock == true
        if let measured = PantryAmount.parse(item.quantityText) { measuredUnit = measured.unit; measuredAmount = NSDecimalNumber(decimal: measured.amount).stringValue }
        name = item.name; quantity = item.quantityText ?? ""; packDetails = item.packDetails ?? ""
        storeName = item.storeName ?? ""; location = item.location ?? ""
        if let day = item.packedDay, let date = ShoppingEntryRules.date(for: day) { hasPackedDate = true; packedDate = date }
        if let day = item.expiryDay, let date = ShoppingEntryRules.date(for: day) { hasExpiryDate = true; expiryDate = date }
        if let day = item.purchasedDay, let date = ShoppingEntryRules.date(for: day) { hasPurchasedDate = true; purchasedDate = date }
    }
}
