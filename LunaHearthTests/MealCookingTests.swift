import Foundation
import Testing
@testable import LunaHearth

@MainActor struct MealCookingTests {
    private func fixture() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Cooking home", owner: "Cook", members: [])
        var draft = EntryDraft(kind: .meal, title: "Rice dinner")
        draft.mealIngredients = "Rice\nCurd"; draft.mealSteps = "Cook rice\nServe with curd"; draft.mealServings = 4
        try repo.add(draft)
        var pantry = InventoryDraft(); pantry.name = "Rice"; pantry.measuredAmount = "2"; pantry.measuredUnit = .kg
        try repo.saveInventory(pantry)
        return repo
    }
    @Test func allBuiltInMealsAreIdeasWithoutInstructions() throws {
        for idea in MealSuggestionRules.starters {
            #expect(idea.steps.isEmpty)
            try MealCookingRules.validate(servings: 2, ingredients: idea.ingredients, steps: idea.steps)
        }
    }

    @Test func editingLegacyMealPreservesHiddenSteps() throws {
        let repo = try fixture()
        let meal = try #require(repo.meals(on: .now).first)
        let original = meal.preparationSteps
        var edit = EntryDraft.editing(meal)
        edit.title = "Updated meal"
        try repo.add(edit)
        #expect(meal.preparationSteps == original)
    }

    @Test func ingredientStatusTracksShoppingAndPantry() throws {
        let repo = try fixture()
        #expect(repo.mealIngredientAvailability("curd").label == "Need to buy")
        try repo.add(EntryDraft(kind: .grocery, title: "Curd"))
        #expect(repo.mealIngredientAvailability("curd").label == "Already in shopping")
        let grocery = try #require(repo.groceries.first)
        try repo.recordPurchase(grocery, addToInventory: true)
        #expect(repo.mealIngredientAvailability("curd").label == "In pantry")
        #expect(!repo.mealIngredientAvailability("curd").inShopping)
        #expect(MealIngredientAvailability.resolve("Cumin", pantry: [], shopping: ["Cumin seeds"]).inShopping)
        #expect(MealIngredientAvailability.resolve("Rice", pantry: ["rice"], shopping: ["Rice"]).label == "In pantry · Already in shopping")
    }
    @Test func measuredUnitsConvertOnlyWithinDimension() throws {
        #expect(try PantryAmount(amount: 2, unit: .kg).subtract(.init(amount: 250, unit: .g)).text == "1.75 kg")
        #expect(try PantryAmount(amount: 1, unit: .l).subtract(.init(amount: 250, unit: .ml)).text == "0.75 l")
        #expect(throws: MealCookingError.self) { try PantryAmount(amount: 1, unit: .kg).subtract(.init(amount: 1, unit: .ml)) }
        #expect(throws: MealCookingError.self) { try PantryAmount(amount: 1, unit: .piece).subtract(.init(amount: 2, unit: .piece)) }
        #expect(PantryAmount.parse("half a bag") == nil)
        #expect(PantryAmount.number("-1") == nil)
    }
    @Test func shoppingSkipsAliasesAndPendingDuplicates() throws {
        let repo = try fixture(); let meal = try #require(repo.meals.first)
        try repo.add(EntryDraft(kind: .grocery, title: "curd"))
        #expect(try repo.addMealShopping(meal, names: ["Curd", "curd"]) == 0)
        #expect(repo.groceries.count == 1)
        #expect(throws: HouseholdValidation.self) { try repo.addMealShopping(meal, names: ["Chocolate"]) }
    }
    @Test func cookedTransactionIsIdempotentAndCompletesPrep() throws {
        let repo = try fixture(); let meal = try #require(repo.meals.first); let rice = try #require(repo.inventory.first)
        let prep = try repo.addMealPrep(meal, title: "Wash rice", due: .now.addingTimeInterval(3600), memberID: nil)
        let review = PantryUseReview(id: rice.id, modifiedAt: rice.modifiedAt, action: .amount, amount: "250", unit: .g)
        let version = meal.modifiedAt
        try repo.finishMeal(meal, expectedModifiedAt: version, reviews: [review])
        #expect(rice.quantityText == "1.75 kg" && meal.cookedAt != nil && prep.isCompleted)
        #expect(throws: MealCookingError.self) { try repo.finishMeal(meal, expectedModifiedAt: version, reviews: [review]) }
        #expect(rice.quantityText == "1.75 kg")
        let copy = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try copy.restoreBackup(repo.makeBackup())
        #expect(copy.meals.first?.servings == 4)
        #expect(copy.meals.first?.ingredientNames == ["Rice", "Curd"])
        #expect(copy.meals.first?.preparationSteps == ["Cook rice", "Serve with curd"])
        #expect(copy.meals.first?.cookedAt != nil)
        #expect(copy.tasks.first?.mealID == meal.id && copy.tasks.first?.isCompleted == true)
        #expect(copy.inventory.first?.quantityText == "1.75 kg")
    }
    @Test func staleOrExcessUseNeverPartiallyFinishes() throws {
        let repo = try fixture(); let meal = try #require(repo.meals.first); let rice = try #require(repo.inventory.first)
        let review = PantryUseReview(id: rice.id, modifiedAt: rice.modifiedAt, action: .amount, amount: "9", unit: .kg)
        #expect(throws: MealCookingError.self) { try repo.finishMeal(meal, expectedModifiedAt: meal.modifiedAt, reviews: [review]) }
        #expect(meal.cookedAt == nil && rice.quantityText == "2 kg")
        try repo.setMeasuredAmount(rice, amount: "3", unit: .kg)
        #expect(throws: MealCookingError.self) { try repo.finishMeal(meal, expectedModifiedAt: meal.modifiedAt, reviews: [review]) }
        #expect(meal.cookedAt == nil && rice.quantityText == "3 kg")
    }
    @Test func explicitUsedUpAndLowStockRemainAvailableWithoutQuantity() throws {
        let repo = try fixture(); let meal = try #require(repo.meals.first); let rice = try #require(repo.inventory.first)
        try repo.finishMeal(meal, expectedModifiedAt: meal.modifiedAt, reviews: [.init(id: rice.id, modifiedAt: rice.modifiedAt, action: .low)])
        #expect(rice.isLowStock == true && rice.quantityText == "2 kg")
    }
}
