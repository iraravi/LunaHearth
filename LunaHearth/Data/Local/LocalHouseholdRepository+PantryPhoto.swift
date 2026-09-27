import Foundation

extension LocalHouseholdRepository {
    /// An observation is not a purchase. Never increment existing stock or complete shopping.
    @discardableResult
    func importPantryPhoto(_ rows: [PantryPhotoItem], householdID: UUID) throws -> Int {
        try FeatureAccess.require(.pantryPhoto)
        guard household?.id == householdID else { throw HouseholdValidation.invalidReference }
        var drafts: [InventoryDraft] = []
        var known = inventory.filter { !$0.isUsedUp }.map(\.name)
        for row in rows.prefix(50) where row.included {
            var draft = InventoryDraft()
            draft.name = row.name; draft.quantity = row.quantity
            draft.hasExpiryDate = row.hasExpiry; draft.expiryDate = row.expiry
            try InventoryRules.validate(draft)
            guard !known.contains(where: { IngredientMatching.same($0, draft.name) }) else { continue }
            known.append(draft.name); drafts.append(draft)
        }
        try commit {
            for draft in drafts {
                let item = InventoryItem(householdID: householdID, name: try HouseholdRules.requiredName(draft.name))
                item.quantityText = InventoryRules.optional(draft.quantity)
                item.expiryDay = draft.hasExpiryDate ? HouseholdDay(draft.expiryDate).key : nil
                context.insert(item)
            }
        }
        return drafts.count
    }
}
