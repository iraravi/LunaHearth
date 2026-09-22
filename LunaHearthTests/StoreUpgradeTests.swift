import Foundation
import SwiftData
import Testing
@testable import LunaHearth

/// Frozen build-46 PurchaseEntry layout: optional receiptLineKey did not exist.
private enum Build46 {
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
        var createdAt: Date
        var modifiedAt: Date
        init(home: UUID, stock: UUID) {
            id = UUID(); householdID = home; purchaseID = UUID(); inventoryID = stock
            name = "Milk"; quantity = "1 litre"; merchant = "Market"; day = HouseholdDay(.now).key
            stockAction = "added"; createdAt = .now; modifiedAt = .now
        }
    }
}

@MainActor struct StoreUpgradeTests {
    @Test func build46PurchaseStoreUpgradesWithoutLosingStockOrHistory() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("upgrade.store")
        let homeID = UUID(), stockID = UUID()
        func writePreviousStore() throws {
            let schema = Schema([
                Household.self, HouseholdMember.self, FamilyEvent.self, HouseholdTask.self,
                GroceryItem.self, InventoryItem.self, HouseholdExpense.self, Build46.PurchaseEntry.self,
                ShoppingStore.self, MealPlanEntry.self, HomeFloor.self, Room.self, HomeAsset.self,
                Warranty.self, MaintenancePlan.self, MaintenanceHistory.self, DocumentRecord.self,
                ReminderDeliverySettings.self, ReminderDeliveryLink.self, CalendarDeliveryLink.self,
                HouseholdSyncConfiguration.self, HouseholdSyncBaseline.self, ActiveHouseholdSelection.self
            ])
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            context.insert(Household(id: homeID, name: "Upgrade test"))
            let stock = InventoryItem(id: stockID, householdID: homeID, name: "Milk")
            stock.quantityText = "1 litre"; context.insert(stock)
            context.insert(Build46.PurchaseEntry(home: homeID, stock: stockID))
            try context.save()
        }
        try writePreviousStore()
        let schema = LocalStoreConfiguration.schema
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let repo = LocalHouseholdRepository(container: container); try repo.reload()
        #expect(repo.household?.id == homeID)
        #expect(repo.inventory.first?.quantityText == "1 litre")
        #expect(repo.purchases.count == 1 && repo.purchases.first?.inventoryID == stockID)
        #expect(repo.purchases.first?.receiptLineKey == nil)
        var lines = ReceiptRules.scan(text: "Milk 4.00").lines
        lines[0].existingPurchaseID = repo.purchases.first?.id
        try repo.importReceipt(lines, householdID: homeID, storeName: "Market")
        #expect(repo.inventory.first?.quantityText == "1 litre")
        #expect(repo.purchases.first?.receiptLineKey == lines[0].id)
    }
}
