import Foundation
import Testing
@testable import LunaHearth

@MainActor struct WeeklyMealTests {
    @Test func stockIsAllocatedOnceAcrossDaysAndUnits() throws {
        let rows = WeeklyMealRules.shopping(demands: [
            .init(name: "Rice", day: "2026-09-14", perServing: "250 g", servings: 2),
            .init(name: "rice", day: "2026-09-15", perServing: "0.5 kg", servings: 2)
        ], pantry: [.init(name: "Rice", quantity: "1 kg", expiry: nil)], pending: [])
        #expect(rows.count == 1)
        #expect(rows.first?.amount == "500 g")
        #expect(rows.first?.needsAmountReview == false)
        #expect(rows.first?.covered == false)
    }
    @Test func expiryUnknownAndIncompatibleUnitsAreExplicit() {
        let demand = WeeklyMealDemand(name: "Milk", day: "2026-09-16", perServing: "250 ml", servings: 2)
        let expired = WeeklyMealRules.shopping(demands: [demand], pantry: [.init(name: "Milk", quantity: "1 l", expiry: "2026-09-15")], pending: [])
        #expect(expired.first?.amount == "500 ml")
        for quantity in ["one bottle", "1 kg"] {
            let unknown = WeeklyMealRules.shopping(demands: [demand], pantry: [.init(name: "Milk", quantity: quantity, expiry: nil)], pending: [])
            #expect(unknown.first?.needsAmountReview == true)
            #expect(unknown.first?.amount == nil)
        }
        let missingRecipe = WeeklyMealRules.shopping(demands: [.init(name: "Milk", day: "2026-09-16", perServing: nil, servings: 2)], pantry: [], pending: [])
        #expect(missingRecipe.first?.needsAmountReview == true)
    }
    @Test func aliasesAndPendingItemsDoNotDuplicate() {
        let rows = WeeklyMealRules.shopping(demands: [
            .init(name: "Cumin", day: "2026-09-14", perServing: "2 g", servings: 2),
            .init(name: "Cumin seeds", day: "2026-09-15", perServing: "2 g", servings: 2)
        ], pantry: [], pending: ["Cumin seed"])
        #expect(rows.count == 1)
        #expect(rows.first?.alreadyListed == true)
    }
    @Test func weekUsesCivilDaysAcrossDST() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 30)))
        let days = WeeklyMealRules.days(from: start, calendar: calendar)
        #expect(days.count == 7)
        #expect(days.allSatisfy { calendar.component(.hour, from: $0) == 0 })
        #expect(days[3].timeIntervalSince(days[2]) == 25 * 3600)
    }
    @Test func quantitiesValidateAndRoundTripWithBackup() throws {
        let repo = try makeRepository()
        var draft = EntryDraft(kind: .meal, title: "Rice", mealIngredients: "Rice", mealServings: 3, mealAmountsPerServing: ["Rice": "100 g"])
        try repo.add(draft)
        let copy = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try copy.restoreBackup(repo.makeBackup())
        #expect(copy.meals.first?.ingredientAmountsPerServing == ["Rice": "100 g"])
        #expect(copy.meals.first?.servings == 3)
        draft.mealAmountsPerServing = ["Rice": "-5 g"]
        #expect(throws: MealCookingError.self) { try repo.add(draft) }
        #expect(repo.meals.count == 1)
    }
    @Test func weeklyDraftSaveIsAtomicAndPreservesExistingSlots() throws {
        let repo = try makeRepository(); let home = try #require(repo.household?.id)
        let drafts = [EntryDraft(kind: .meal, title: "Breakfast", mealType: "Breakfast"), EntryDraft(kind: .meal, title: "Dinner", mealType: "Dinner")]
        try repo.saveWeeklyDrafts(drafts, householdID: home)
        #expect(repo.meals.count == 2)
        #expect(throws: MealCookingError.self) { try repo.saveWeeklyDrafts(drafts, householdID: home) }
        #expect(repo.meals.count == 2)
        #expect(throws: HouseholdValidation.self) { try repo.saveWeeklyDrafts(drafts, householdID: UUID()) }
    }
    @Test func shoppingReviewRechecksChangesAndDoesNotChangePantry() throws {
        let repo = try makeRepository()
        try repo.add(EntryDraft(kind: .meal, title: "Rice", mealIngredients: "Rice", mealServings: 2, mealAmountsPerServing: ["Rice": "100 g"]))
        let preview = try repo.weeklyShoppingPreview(start: .now)
        #expect(preview.rows.first?.amount == "200 g")
        try repo.addWeeklyShopping(preview, selected: ["Rice"])
        #expect(repo.groceries.count == 1 && repo.groceries.first?.quantityText == "200 g")
        #expect(repo.inventory.isEmpty)
        #expect(throws: MealCookingError.self) { try repo.addWeeklyShopping(preview, selected: ["Rice"]) }
        let current = try repo.weeklyShoppingPreview(start: .now)
        try repo.addWeeklyShopping(current, selected: ["Rice"])
        #expect(repo.groceries.count == 1)
    }
    private func makeRepository() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Week home", owner: "Cook", members: [])
        return repo
    }
}
