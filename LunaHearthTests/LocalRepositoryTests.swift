import Foundation
import SwiftData
import Testing
@testable import LunaHearth

@MainActor
struct LocalRepositoryTests {
    private func makeRepository() throws -> LocalHouseholdRepository {
        let repository = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repository.reload()
        return repository
    }

    @Test func fullHomeHierarchyAndCareSurviveFreshRepository() throws {
        let container = try LocalStoreConfiguration.makeContainer(inMemory: true)
        let repo = LocalHouseholdRepository(container: container)
        try repo.createHousehold(name: "Our home", owner: "", members: [])
        try repo.add(EntryDraft(kind: .floor, title: "Ground floor"))
        let floor = try #require(repo.floors.first)
        try repo.add(EntryDraft(kind: .room, title: "Kitchen", parentID: floor.id))
        let kitchen = try #require(repo.rooms.first)
        try repo.add(EntryDraft(kind: .room, title: "Utility", parentID: floor.id))
        let utility = try #require(repo.rooms.first(where: { $0.name == "Utility" }))
        try repo.add(EntryDraft(kind: .asset, title: "Fridge", parentID: kitchen.id, category: .appliance, manufacturer: "Acme"))
        let asset = try #require(repo.assets.first)
        try repo.add(EntryDraft(kind: .warranty, title: "Appliance cover", parentID: asset.id))
        try repo.add(EntryDraft(kind: .maintenance, title: "Clean filter", parentID: asset.id,
                               intervalDays: 30, repeats: true, shoppingItem: "Water filter"))
        let plan = try #require(repo.maintenance.first)
        let completion = Date(timeIntervalSince1970: 1_700_000_000)
        try repo.completeMaintenance(plan, at: completion, calendar: Calendar(identifier: .gregorian))
        try repo.addReplacementToShopping(plan)
        try repo.move(asset, to: utility.id)
        let fresh = LocalHouseholdRepository(container: container)
        try fresh.reload()
        #expect(fresh.rooms.count == 2)
        #expect(fresh.rooms.allSatisfy { $0.floorID == floor.id })
        #expect(fresh.assets.first?.id == asset.id)
        #expect(fresh.assets.first?.roomID == utility.id)
        #expect(fresh.assets.first?.manufacturer == "Acme")
        #expect(fresh.warranties.first?.assetID == asset.id)
        #expect(fresh.maintenance.first?.lastCompletedAt == completion)
        #expect(fresh.maintenance.first?.nextDueAt != nil)
        #expect(fresh.history.first?.planID == plan.id)
        #expect(fresh.groceries.first?.relatedAssetID == asset.id)
    }

    @Test func householdPersistsAcrossRepositoryReloadAndSetupIsAtomic() throws {
        let container = try LocalStoreConfiguration.makeContainer(inMemory: true)
        let repository = LocalHouseholdRepository(container: container)
        #expect(throws: HouseholdValidation.self) {
            try repository.createHousehold(name: "House", owner: "Alex", members: [(" ", .child)])
        }
        try repository.reload()
        #expect(repository.household == nil)
        try repository.createHousehold(name: " House ", owner: "Alex", members: [("Sam", .child)])
        let reloaded = LocalHouseholdRepository(container: container)
        try reloaded.reload()
        #expect(reloaded.household?.name == "House")
        #expect(reloaded.members.count == 2)
        #expect(reloaded.members.allSatisfy { $0.householdID == reloaded.household?.id })
        #expect(throws: HouseholdValidation.self) {
            try reloaded.createHousehold(name: "Duplicate", owner: "", members: [])
        }
    }

    @Test func householdCanSkipPeople() throws {
        let repository = try makeRepository()
        try repository.createHousehold(name: "Solo", owner: "", members: [])
        #expect(repository.household != nil)
        #expect(repository.members.isEmpty)
    }

    @Test func planningWritesAndCompletionArePersisted() throws {
        let repository = try makeRepository()
        try repository.createHousehold(name: "Home", owner: "", members: [])
        try repository.add(EntryDraft(kind: .task, title: "Filter", hasDate: true))
        try repository.add(EntryDraft(kind: .grocery, title: "Milk", quantity: "2 cartons"))
        try repository.add(EntryDraft(kind: .meal, title: "Pasta"))
        try repository.add(EntryDraft(kind: .event, title: "Dinner"))
        let task = try #require(repository.tasks.first)
        try repository.toggle(task)
        let grocery = try #require(repository.groceries.first)
        try repository.toggle(grocery)
        try repository.reload()
        #expect(repository.tasks.first?.isCompleted == true)
        #expect(repository.groceries.first?.isCompleted == true)
        #expect(repository.dueTasks(on: .now).isEmpty)
        #expect(repository.meals(on: .now).count == 1)
        #expect(repository.events(on: .now).count == 1)
    }

    @Test func validatesCrossHouseholdRelationshipsBeforeWriting() throws {
        let repository = try makeRepository()
        try repository.createHousehold(name: "Home", owner: "", members: [])
        #expect(throws: HouseholdValidation.self) {
            try repository.add(EntryDraft(kind: .task, title: "Foreign member", memberID: UUID()))
        }
        #expect(throws: HouseholdValidation.self) {
            try repository.add(EntryDraft(kind: .maintenance, title: "Foreign asset", parentID: UUID()))
        }
        #expect(repository.tasks.isEmpty)
        #expect(repository.maintenance.isEmpty)
    }

    @Test func maintenanceHistoryAndReplacementRemainLinkedWhenAssetMoves() throws {
        let repository = try makeRepository()
        try repository.createHousehold(name: "Home", owner: "", members: [])
        try repository.add(EntryDraft(kind: .room, title: "Kitchen"))
        try repository.add(EntryDraft(kind: .asset, title: "Fridge"))
        let asset = try #require(repository.assets.first)
        try repository.add(EntryDraft(kind: .warranty, title: "Manufacturer", parentID: asset.id))
        try repository.add(EntryDraft(kind: .maintenance, title: "Water filter", hasDate: true,
                                      parentID: asset.id, intervalDays: 90, repeats: true, shoppingItem: "Filter cartridge"))
        let plan = try #require(repository.maintenance.first)
        let now = Date.now
        try repository.completeMaintenance(plan, at: now, calendar: Calendar(identifier: .gregorian))
        #expect(repository.history.count == 1)
        #expect(plan.lastCompletedAt == now)
        #expect(plan.nextDueAt == Calendar(identifier: .gregorian).date(byAdding: .day, value: 90, to: now))
        #expect(repository.groceries.isEmpty)
        try repository.addReplacementToShopping(plan)
        try repository.addReplacementToShopping(plan)
        #expect(repository.groceries.count == 1)
        try repository.move(asset, to: repository.rooms.first?.id)
        #expect(repository.warranties.first?.assetID == asset.id)
        #expect(repository.history.first?.planID == plan.id)
        #expect(repository.groceries.first?.relatedAssetID == asset.id)
    }

    @Test func oneTimeMaintenanceDoesNotCreateNextOccurrence() throws {
        let repository = try makeRepository()
        try repository.createHousehold(name: "Home", owner: "", members: [])
        try repository.add(EntryDraft(kind: .asset, title: "Oven"))
        let asset = try #require(repository.assets.first)
        try repository.add(EntryDraft(kind: .maintenance, title: "Repair", parentID: asset.id))
        let plan = try #require(repository.maintenance.first)
        try repository.completeMaintenance(plan)
        #expect(plan.nextDueAt == nil)
        #expect(throws: HouseholdValidation.self) { try repository.completeMaintenance(plan) }
        #expect(repository.history.count == 1)
    }

    @Test func editsPreserveIdentityAndInvalidEditsLeaveSavedDataUntouched() throws {
        let repository = try makeRepository()
        try repository.createHousehold(name: "Home", owner: "", members: [])
        try repository.add(EntryDraft(kind: .event, title: "Dinner"))
        let event = try #require(repository.events.first)
        let originalStart = event.startAt
        var draft = EntryDraft.editing(event)
        draft.title = "Family dinner"
        try repository.add(draft)
        #expect(repository.events.count == 1)
        #expect(event.title == "Family dinner")
        #expect(event.id == draft.recordID)
        draft.endDate = originalStart.addingTimeInterval(-1)
        #expect(throws: HouseholdValidation.self) { try repository.add(draft) }
        #expect(event.endAt > event.startAt)
        try repository.deletePlanningEntry(id: event.id, kind: .event)
        try repository.reload()
        #expect(repository.events.isEmpty)
    }

    @Test func planningCRUDPreservesCompletionAndDeletesOnlyRequestedRecords() throws {
        let repository = try makeRepository()
        try repository.createHousehold(name: "Home", owner: "", members: [])
        try repository.add(EntryDraft(kind: .task, title: "Original"))
        try repository.add(EntryDraft(kind: .grocery, title: "Milk"))
        try repository.add(EntryDraft(kind: .meal, title: "Pasta"))
        let task = try #require(repository.tasks.first)
        try repository.toggle(task)
        var edited = EntryDraft.editing(task)
        edited.title = "Renamed"
        try repository.add(edited)
        #expect(task.isCompleted)
        #expect(task.title == "Renamed")
        let grocery = try #require(repository.groceries.first)
        var groceryDraft = EntryDraft.editing(grocery)
        groceryDraft.quantity = "3 cartons"
        try repository.add(groceryDraft)
        #expect(grocery.quantityText == "3 cartons")
        let meal = try #require(repository.meals.first)
        var mealDraft = EntryDraft.editing(meal)
        mealDraft.title = "Soup"
        try repository.add(mealDraft)
        #expect(meal.title == "Soup")
        try repository.deletePlanningEntry(id: task.id, kind: .task)
        #expect(repository.groceries.count == 1)
        try repository.deletePlanningEntry(id: grocery.id, kind: .grocery)
        try repository.deletePlanningEntry(id: meal.id, kind: .meal)
        #expect(repository.tasks.isEmpty && repository.groceries.isEmpty && repository.meals.isEmpty)
    }

    @Test func queriesAreScopedToCurrentHousehold() throws {
        let container = try LocalStoreConfiguration.makeContainer(inMemory: true)
        let repository = LocalHouseholdRepository(container: container)
        try repository.createHousehold(name: "Home", owner: "", members: [])
        let otherContext = ModelContext(container)
        otherContext.insert(HouseholdTask(householdID: UUID(), title: "Other household"))
        try otherContext.save()
        try repository.reload()
        #expect(repository.tasks.isEmpty)
    }

    @Test func legacyMealDateIsBackfilledWithoutDeletingTheRecord() throws {
        let container = try LocalStoreConfiguration.makeContainer(inMemory: true)
        let repository = LocalHouseholdRepository(container: container)
        try repository.createHousehold(name: "Home", owner: "", members: [])
        let home = try #require(repository.household)
        let context = ModelContext(container)
        let meal = MealPlanEntry(householdID: home.id, date: .now, mealType: "Dinner", title: "Legacy meal")
        meal.dateKey = nil
        context.insert(meal)
        try context.save()
        try repository.reload()
        let restored = try #require(repository.meals.first)
        #expect(restored.id == meal.id)
        #expect(restored.dateKey == HouseholdDay(meal.date).key)
        let secondRepository = LocalHouseholdRepository(container: container)
        try secondRepository.reload()
        #expect(secondRepository.meals.first?.dateKey == restored.dateKey)
    }

    @Test func mealDateKeyDoesNotChangeWhenViewedInAnotherTimeZone() throws {
        let repository = try makeRepository()
        try repository.createHousehold(name: "Home", owner: "", members: [])
        try repository.add(EntryDraft(kind: .meal, title: "Breakfast"))
        let meal = try #require(repository.meals.first)
        let key = try #require(meal.dateKey)
        let zone = try #require(TimeZone(identifier: "Pacific/Auckland"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let parts = key.split(separator: "-").compactMap { Int($0) }
        let sameDayInNewZone = try #require(calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)))
        #expect(repository.meals(on: sameDayInNewZone, timeZone: zone).count == 1)
        #expect(meal.dateKey == key)
    }
}
