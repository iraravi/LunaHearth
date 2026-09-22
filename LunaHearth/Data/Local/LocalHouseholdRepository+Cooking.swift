import Foundation

extension LocalHouseholdRepository {
    func mealIngredientAvailability(_ name: String) -> MealIngredientAvailability {
        let today = HouseholdDay(.now).key
        let names = inventory.filter { !$0.isUsedUp && ($0.expiryDay.map { $0 >= today } ?? true) }.map(\.name)
        return .resolve(name, pantry: names, shopping: groceries.filter { !$0.isCompleted }.map(\.name))
    }

    func setMeasuredAmount(_ item: InventoryItem, amount: String, unit: PantryUnit) throws {
        guard inventory.contains(where: { $0.id == item.id }), let number = PantryAmount.number(amount) else { throw MealCookingError.amount }
        try commit { item.quantityText = PantryAmount(amount: number, unit: unit).text; item.isUsedUp = number == 0; item.modifiedAt = .now }
    }
    @discardableResult func addMealShopping(_ meal: MealPlanEntry, names: [String]) throws -> Int {
        guard meals.contains(where: { $0.id == meal.id }), meal.cookedAt == nil, let home = household?.id else { throw HouseholdValidation.invalidReference }
        let requested = PantrySuggestionRules.reviewed(names, existing: groceries.filter { !$0.isCompleted }.map(\.name))
        let allowed = meal.ingredientNames ?? []
        guard requested.allSatisfy({ name in allowed.contains { IngredientMatching.same($0, name) } }) else { throw HouseholdValidation.invalidReference }
        try commit { for name in requested { context.insert(GroceryItem(householdID: home, name: name)) } }
        return requested.count
    }
    @discardableResult func addMealPrep(_ meal: MealPlanEntry, title: String, due: Date, memberID: UUID?) throws -> HouseholdTask {
        guard meals.contains(where: { $0.id == meal.id }), meal.cookedAt == nil, let home = household?.id,
              memberID == nil || members.contains(where: { $0.id == memberID }), due > .now else { throw HouseholdValidation.invalidReference }
        let task = HouseholdTask(householdID: home, title: try HouseholdRules.requiredName(title), dueAt: due, assignedMemberID: memberID)
        task.mealID = meal.id
        try commit {
            context.insert(task)
            if let settings = reminderDeliverySettings, settings.enabled { context.insert(ReminderDeliveryLink(taskID: task.id, householdID: home, listID: settings.listID)) }
        }
        return task
    }
    func finishMeal(_ meal: MealPlanEntry, expectedModifiedAt: Date, reviews: [PantryUseReview]) throws {
        guard meals.contains(where: { $0.id == meal.id }), meal.householdID == household?.id else { throw HouseholdValidation.invalidReference }
        guard meal.cookedAt == nil else { throw MealCookingError.cooked }
        guard meal.modifiedAt == expectedModifiedAt, Set(reviews.map(\.id)).count == reviews.count else { throw MealCookingError.changed }
        var changes: [(InventoryItem, PantryUseReview, String?)] = []
        for review in reviews where review.action != .keep {
            guard let item = inventory.first(where: { $0.id == review.id }), item.modifiedAt == review.modifiedAt,
                  !item.isUsedUp, (meal.ingredientNames ?? []).contains(where: { IngredientMatching.same($0, item.name) }) else { throw MealCookingError.changed }
            var quantity: String?
            if review.action == .amount {
                guard let current = PantryAmount.parse(item.quantityText), let amount = PantryAmount.number(review.amount) else { throw MealCookingError.amount }
                quantity = try current.subtract(.init(amount: amount, unit: review.unit)).text
            }
            changes.append((item, review, quantity))
        }
        try commit {
            for (item, review, quantity) in changes {
                if let quantity { item.quantityText = quantity; item.isUsedUp = PantryAmount.parse(quantity)?.amount == 0 }
                if review.action == .low { item.isLowStock = true }
                if review.action == .finished { item.isUsedUp = true; if let known = PantryAmount.parse(item.quantityText) { item.quantityText = PantryAmount(amount: 0, unit: known.unit).text } }
                item.modifiedAt = .now
            }
            meal.cookedAt = .now; meal.modifiedAt = .now
            for task in tasks where task.mealID == meal.id && !task.isCompleted { task.isCompleted = true; task.modifiedAt = .now }
        }
    }
}
