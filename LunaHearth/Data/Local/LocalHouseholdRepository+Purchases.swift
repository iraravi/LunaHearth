import Foundation
import SwiftData

extension LocalHouseholdRepository {
    /// Called only inside the purchase transaction. History is a snapshot, not a live item name.
    func appendPurchase(id: UUID, purchaseID: UUID, grocery: GroceryItem, inventoryID: UUID?, expenseID: UUID?,
                        day: String, action: String, amount: Int? = nil, currency: String? = nil) {
        if let entry = purchases.first(where: { $0.id == id }) {
            if entry.inventoryID == nil, let inventoryID {
                entry.inventoryID = inventoryID; entry.stockAction = action; entry.modifiedAt = .now
            }
            return
        }
        let entry = PurchaseEntry(id: id, householdID: grocery.householdID, purchaseID: purchaseID,
            name: grocery.name, quantity: grocery.quantityText ?? "", merchant: grocery.storeName ?? "",
            day: day, stockAction: action)
        entry.groceryID = grocery.id; entry.inventoryID = inventoryID; entry.expenseID = expenseID
        entry.amountMinorUnits = amount; entry.currencyCode = amount == nil ? nil : currency
        context.insert(entry)
    }
}
