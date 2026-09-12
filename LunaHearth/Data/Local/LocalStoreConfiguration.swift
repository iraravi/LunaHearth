import SwiftData

@MainActor
enum LocalStoreConfiguration {
    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            Household.self, HouseholdMember.self, FamilyEvent.self, HouseholdTask.self,
            GroceryItem.self, MealPlanEntry.self, HomeFloor.self, Room.self, HomeAsset.self,
            Warranty.self, MaintenancePlan.self, MaintenanceHistory.self, DocumentRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory,
                                               cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
