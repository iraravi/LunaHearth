import Foundation
import SwiftData

/// One household pack/batch. Separate dates must never be silently merged by name.
@Model final class InventoryItem {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var name: String
    var quantityText: String?
    var packDetails: String?
    var storeName: String?
    var storeID: UUID?
    var location: String?
    var packedDay: String?
    var expiryDay: String?
    var purchasedDay: String?
    var sourceGroceryID: UUID?
    var isLowStock: Bool? = nil
    var isUsedUp: Bool
    var createdAt: Date
    var modifiedAt: Date
    init(id: UUID = UUID(), householdID: UUID, name: String, createdAt: Date = .now) {
        self.id = id; self.householdID = householdID; self.name = name
        self.isUsedUp = false; self.createdAt = createdAt; self.modifiedAt = createdAt
    }
}
