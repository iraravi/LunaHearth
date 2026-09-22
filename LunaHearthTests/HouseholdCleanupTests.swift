import Foundation
import Testing
@testable import LunaHearth

@MainActor struct HouseholdCleanupTests {
    private func fixture() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Cleanup test", owner: "Owner", members: [])
        var pantry = InventoryDraft(); pantry.name = "Rice"; try repo.saveInventory(pantry)
        try repo.add(EntryDraft(kind: .grocery, title: "Milk"))
        try repo.recordPurchase(try #require(repo.groceries.first), addToInventory: true)
        try repo.add(EntryDraft(kind: .meal, title: "Dinner"))
        try repo.addMealPrep(try #require(repo.meals.first), title: "Prepare dinner", due: .now.addingTimeInterval(3600), memberID: nil)
        try repo.add(EntryDraft(kind: .task, title: "Unrelated task"))
        var expense = ExpenseDraft(); expense.merchant = "Test store"; expense.amount = "10.00"; expense.currency = "USD"
        try repo.saveExpense(expense)
        return repo
    }
    @Test func eachCategoryClearsOnlyItsPromisedScope() throws {
        for scope in HouseholdCleanupScope.allCases {
            let repo = try fixture()
            let preview = try repo.cleanupPreview(scope)
            try repo.clearCategory(preview, confirmation: "CLEAR")
            #expect(try repo.cleanupPreview(scope).count == 0)
            #expect(repo.household?.name == "Cleanup test" && repo.members.count == 1)
            #expect(repo.purchases.count == 1)
            if scope != .pantry { #expect(repo.inventory.count == 2) }
            if scope != .shopping { #expect(repo.groceries.count == 1) }
            if scope != .meals { #expect(repo.meals.count == 1) }
            if scope != .expenses { #expect(repo.expenses.count == 1) }
            if scope == .meals { #expect(repo.tasks.count == 1 && repo.tasks.first?.title == "Unrelated task") }
            let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
            try restored.restoreBackup(repo.makeBackup())
            #expect(try restored.cleanupPreview(scope).count == 0)
        }
    }
    @Test func confirmationAndStalePreviewsCannotDelete() throws {
        let repo = try fixture(); let preview = try repo.cleanupPreview(.pantry)
        #expect(throws: HouseholdCleanupError.self) { try repo.clearCategory(preview, confirmation: "") }
        #expect(repo.inventory.count == 2)
        var pantry = InventoryDraft(); pantry.name = "Carrots"; try repo.saveInventory(pantry)
        #expect(throws: HouseholdCleanupError.self) { try repo.clearCategory(preview, confirmation: "CLEAR") }
        #expect(repo.inventory.count == 3)
        let other = try fixture()
        #expect(throws: HouseholdCleanupError.self) { try other.clearCategory(preview, confirmation: "CLEAR") }
        #expect(other.inventory.count == 2)
    }
}
