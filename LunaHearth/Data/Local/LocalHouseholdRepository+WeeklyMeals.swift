import Foundation

struct WeeklyShoppingPreview {
    let householdID: UUID
    let start: Date
    let rows: [WeeklyShoppingNeed]
}
extension LocalHouseholdRepository {
    func weeklyShoppingPreview(start: Date) throws -> WeeklyShoppingPreview {
        guard let home = household?.id else { throw HouseholdValidation.invalidReference }
        let days = Set(WeeklyMealRules.days(from: start).map { HouseholdDay($0).key })
        let demands = meals.filter { $0.cookedAt == nil && days.contains($0.dateKey ?? HouseholdDay($0.date).key) }.flatMap { meal in
            (meal.ingredientNames ?? []).map { WeeklyMealDemand(name: $0, day: meal.dateKey ?? HouseholdDay(meal.date).key, perServing: meal.ingredientAmountsPerServing?[$0], servings: meal.servings ?? 2) }
        }
        let packs = inventory.filter { !$0.isUsedUp }.map { WeeklyPantryPack(name: $0.name, quantity: $0.quantityText, expiry: $0.expiryDay) }
        return .init(householdID: home, start: start, rows: WeeklyMealRules.shopping(demands: demands, pantry: packs, pending: groceries.filter { !$0.isCompleted }.map(\.name)))
    }
    func addWeeklyShopping(_ preview: WeeklyShoppingPreview, selected: Set<String>) throws {
        guard preview.householdID == household?.id else { throw MealCookingError.changed }
        let fresh = try weeklyShoppingPreview(start: preview.start)
        guard fresh.rows == preview.rows, selected.isSubset(of: Set(fresh.rows.map(\.id))) else { throw MealCookingError.changed }
        let rows = fresh.rows.filter { selected.contains($0.id) && !$0.covered && !$0.alreadyListed }
        try commit {
            for row in rows {
                let item = GroceryItem(householdID: preview.householdID, name: row.name)
                // Unknown quantities stay unknown; no model or pack-count assumptions.
                item.quantityText = row.amount
                if let amount = PantryAmount.parse(row.amount) {
                    item.quantityAmount = NSDecimalNumber(decimal: amount.amount).stringValue
                    item.quantityUnit = amount.unit == .l ? "litre" : amount.unit.rawValue
                }
                context.insert(item)
            }
        }
    }
    func saveWeeklyDrafts(_ drafts: [EntryDraft], householdID: UUID, prepTimes: [UUID: Date] = [:]) throws {
        try FeatureAccess.require(.weeklyMeals)
        guard household?.id == householdID, !drafts.isEmpty, drafts.count <= 21 else { throw HouseholdValidation.invalidReference }
        guard Set(prepTimes.keys).isSubset(of: Set(drafts.map(\.id))) else { throw MealCookingError.changed }
        var slots: Set<String> = []
        for draft in drafts {
            let slot = HouseholdDay(draft.date).key + draft.mealType
            guard draft.kind == .meal, slots.insert(slot).inserted,
                  !meals.contains(where: { ($0.dateKey ?? HouseholdDay($0.date).key) == HouseholdDay(draft.date).key && $0.mealType == draft.mealType }) else { throw MealCookingError.changed }
            if let prep = prepTimes[draft.id] {
                let appointments = events.map { AppointmentSlot(start: $0.startAt, end: $0.endAt) }
                guard draft.mealType == "Dinner", prep > Date.now,
                      FamilyWeekRules.prepTime(on: draft.date, appointments: appointments) == prep else { throw MealCookingError.changed }
            }
            _ = try HouseholdRules.requiredName(draft.title)
            try MealCookingRules.validate(servings: draft.mealServings, ingredients: MealCookingRules.lines(draft.mealIngredients), steps: MealCookingRules.lines(draft.mealSteps))
            try WeeklyMealRules.validateAmounts(draft.mealAmountsPerServing, names: MealCookingRules.lines(draft.mealIngredients))
        }
        try commit {
            for draft in drafts {
                let meal = MealPlanEntry(householdID: householdID, date: draft.date, mealType: draft.mealType, title: draft.title, notes: draft.notes)
                meal.ingredientNames = MealCookingRules.lines(draft.mealIngredients); meal.preparationSteps = MealCookingRules.lines(draft.mealSteps)
                meal.servings = draft.mealServings; meal.ingredientAmountsPerServing = draft.mealAmountsPerServing
                context.insert(meal)
                if let due = prepTimes[draft.id] {
                    let task = HouseholdTask(householdID: householdID, title: "Prepare for \(draft.title)", dueAt: due)
                    task.mealID = meal.id
                    context.insert(task)
                }
            }
        }
    }
}
