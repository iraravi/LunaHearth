#if DEBUG
import Foundation

@MainActor enum UITestPantryFixture {
    /// Synthetic data only, called exclusively for an in-memory UI test store.
    static func seed(_ repository: LocalHouseholdRepository) throws {
        if ProcessInfo.processInfo.arguments.contains("--store-screenshots") { try storeScreenshots(repository); return }
        try repository.createHousehold(name: "Test home", owner: "Ravi", members: [])
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-calendar") {
            try repository.addMember(name: "Kira", role: .adult)
            for (name, title, hour) in [("Ravi", "Morning appointment", 9), ("Kira", "Afternoon appointment", 14)] {
                var draft = EntryDraft(kind: .event, title: title)
                draft.memberID = repository.members.first { $0.displayName == name }?.id
                draft.date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
                draft.endDate = draft.date.addingTimeInterval(3600)
                try repository.add(draft)
            }
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-assignments") {
            try repository.add(EntryDraft(kind: .task, title: "Take bins out", memberID: repository.members.first?.id))
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-receipt-link") {
            try repository.add(EntryDraft(kind: .grocery, title: "Curd", quantity: "1 tub"))
            if let item = repository.groceries.first { try repository.recordPurchase(item, addToInventory: true) }
        }
        let milkOffset = ProcessInfo.processInfo.arguments.contains("--ui-testing-duplicate-milk") || ProcessInfo.processInfo.arguments.contains("--ui-testing-fresh-milk") ? 1 : -1
        for (name, offset, low) in [("Milk", milkOffset, false), ("Paneer", 2, false), ("Rice", 90, true)] {
            var draft = InventoryDraft(); draft.name = name; draft.quantity = name == "Rice" ? "500 g" : "1 pack"
            draft.storeName = "Walmart"; draft.isLowStock = low; draft.hasExpiryDate = true
            draft.expiryDate = Calendar.current.date(byAdding: .day, value: offset, to: .now) ?? .now
            try repository.saveInventory(draft)
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-category-hints") {
            var draft = InventoryDraft(); draft.name = "Family special"
            try repository.saveInventory(draft)
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-restock-count") {
            try repository.add(EntryDraft(kind: .grocery, title: "Rice", quantity: "1 kg"))
        }
        if ProcessInfo.processInfo.arguments.contains("--ui-testing-duplicate-milk") {
            var duplicate = InventoryDraft(); duplicate.name = "milk"; duplicate.quantity = "2"
            try repository.saveInventory(duplicate, allowSeparatePack: true)
        }
        for (name, quantity, later) in [("Cumin seeds", "200 g", false), ("Tomatoes", "3 pieces", false), ("Milk", "1 carton", true), ("Family special", "", false)] {
            if name == "Family special" && ProcessInfo.processInfo.arguments.contains("--ui-testing-known-groceries") { continue }
            var draft = EntryDraft(kind: .grocery, title: name)
            draft.quantity = quantity; draft.storeName = "Walmart"; draft.neededLater = later
            draft.memberID = repository.members.first?.id
            if ProcessInfo.processInfo.arguments.contains("--ui-testing-today"), later {
                draft.shoppingDate = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
            }
            try repository.add(draft)
        }
    }
    private static func storeScreenshots(_ repository: LocalHouseholdRepository) throws {
        try repository.createHousehold(name: "Maple House", owner: "Alex", members: [("Maya", .adult)])
        if let id = repository.household?.id {
            UserDefaults.standard.set("pantry,shopping,planning", forKey: HomeSetupProgress.storageKey(householdID: id, field: "completed"))
            UserDefaults.standard.set("sharing", forKey: HomeSetupProgress.storageKey(householdID: id, field: "skipped"))
        }
        for (name, quantity, days, low) in [("Basmati rice", "2 kg", 90, false), ("Toor dal", "500 g", 120, true), ("Cumin seeds", "100 g", 180, false), ("Tomatoes", "6 pieces", 3, false), ("Milk", "1 L", 2, false), ("Bananas", "4 pieces", 4, false)] {
            var draft = InventoryDraft(); draft.name = name; draft.quantity = quantity
            draft.hasExpiryDate = true; draft.expiryDate = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
            draft.isLowStock = low; try repository.saveInventory(draft)
        }
        for (name, quantity) in [("Tomatoes", "6 pieces"), ("Milk", "2 L"), ("Cumin seeds", "100 g"), ("Bananas", "6 pieces")] {
            var draft = EntryDraft(kind: .grocery, title: name)
            draft.quantity = quantity; draft.storeName = "Fresh Market"; draft.memberID = repository.members.first?.id
            try repository.add(draft)
        }
        for (name, title, hour) in [("Alex", "Garden walk", 18), ("Maya", "Pottery class", 19)] {
            var draft = EntryDraft(kind: .event, title: title)
            draft.memberID = repository.members.first { $0.displayName == name }?.id
            draft.date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
            draft.endDate = draft.date.addingTimeInterval(3600); try repository.add(draft)
        }
        var task = EntryDraft(kind: .task, title: "Water the balcony plants")
        task.hasDate = true; task.memberID = repository.members.first?.id; try repository.add(task)
        var meal = EntryDraft(kind: .meal, title: "Tomato rice & cucumber salad")
        meal.mealIngredients = "Basmati rice, Tomatoes, Cumin seeds, Cucumber"
        meal.mealSteps = "Rinse the rice and cook until tender.\nCook chopped tomatoes with cumin.\nFold in the rice and serve with cucumber salad."
        try repository.add(meal)
        for (merchant, amount, category) in [("Fresh Market", "64.80", ExpenseCategory.groceries), ("Neighborhood Bakery", "12.50", .dining), ("Home supplies", "28.00", .home)] {
            var expense = ExpenseDraft(); expense.merchant = merchant; expense.amount = amount; expense.currency = "USD"; expense.category = category
            try repository.saveExpense(expense)
        }
    }

}
#endif
