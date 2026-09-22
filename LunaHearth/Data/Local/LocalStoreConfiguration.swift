import SwiftData

@MainActor
enum LocalStoreConfiguration {
    static var schema: Schema {
        Schema([
            Household.self, HouseholdMember.self, FamilyEvent.self, HouseholdTask.self,
            GroceryItem.self, InventoryItem.self, HouseholdExpense.self, PurchaseEntry.self, ShoppingStore.self, MealPlanEntry.self, HomeFloor.self, Room.self, HomeAsset.self,
            Warranty.self, MaintenancePlan.self, MaintenanceHistory.self, DocumentRecord.self,
            ReminderDeliverySettings.self, ReminderDeliveryLink.self, CalendarDeliveryLink.self,
            HouseholdSyncConfiguration.self, HouseholdSyncBaseline.self, ActiveHouseholdSelection.self
        ])
    }
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Self.schema
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory,
                                               cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
