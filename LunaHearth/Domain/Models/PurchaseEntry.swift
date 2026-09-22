import Foundation
import SwiftData

/// Purchased stock snapshot with stable identity; receipt grouping/evidence may be attached later.
@Model final class PurchaseEntry {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var purchaseID: UUID
    var expenseID: UUID?
    var groceryID: UUID?
    var inventoryID: UUID?
    var name: String
    var quantity: String
    var merchant: String
    var day: String
    var amountMinorUnits: Int?
    var currencyCode: String?
    var stockAction: String
    var receiptLineKey: String?
    var createdAt: Date
    var modifiedAt: Date
    init(id: UUID, householdID: UUID, purchaseID: UUID, name: String, quantity: String, merchant: String, day: String, stockAction: String) {
        self.id = id; self.householdID = householdID; self.purchaseID = purchaseID
        self.name = name; self.quantity = quantity; self.merchant = merchant; self.day = day; self.stockAction = stockAction
        createdAt = .now; modifiedAt = .now
    }
}
