import Foundation
import SwiftData
import Testing
@testable import LunaHearth

@MainActor struct ConnectedPurchaseAuditTests {
    @Test func quantitiesRespectUnitsUnknownBalancesAndLimits() {
        #expect(RestockQuantity.combined(existing: "200 g", purchased: "1 kg") == "1200 g")
        #expect(RestockQuantity.combined(existing: "0.5 l", purchased: "500 ml") == "1 l")
        #expect(RestockQuantity.combined(existing: "1 carton", purchased: "2 cartons") == "3 cartons")
        #expect(RestockQuantity.combined(existing: "1 box", purchased: "1 box") == "2 boxes")
        #expect(RestockQuantity.combined(existing: "2 pieces", purchased: "3 pcs") == "5 pieces")
        #expect(RestockQuantity.combined(existing: "2 pieces", purchased: "1 dozen") == "14 pieces")
        #expect(RestockQuantity.combined(existing: "1 kg", purchased: "500 ml") == nil)
        #expect(RestockQuantity.combined(existing: "1 bottle", purchased: "1 carton") == nil)
        #expect(RestockQuantity.combined(existing: nil, purchased: "1 kg") == nil)
        #expect(RestockQuantity.combined(existing: "half a bag", purchased: "1 bag") == nil)
        #expect(RestockQuantity.combined(existing: "9999999 g", purchased: "1 kg") == nil)
        #expect(RestockQuantity.combined(existing: "1 kg", purchased: "0 kg") == nil)
    }

    @Test func shoppingReceiptExpenseMealCycleSurvivesDiskReopen() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = folder.appendingPathComponent("audit.store")
        func open() throws -> LocalHouseholdRepository {
            let schema = LocalStoreConfiguration.schema
            return LocalHouseholdRepository(container: try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)]))
        }
        func purchaseAndCook() throws {
            let repo = try open()
            try repo.createHousehold(name: "Audit", owner: "Ravi", members: [("Kira", .adult)])
            let home = try #require(repo.household?.id)
            var pack = InventoryDraft(); pack.name = "Milk"; pack.quantity = "500 ml"; pack.isLowStock = true
            let stock = try repo.saveInventory(pack)
            try repo.add(EntryDraft(kind: .grocery, title: "milk", quantity: "1 litre"))
            let grocery = try #require(repo.groceries.first)
            try repo.recordPurchase(grocery, addToInventory: true, keeping: stock)
            #expect(repo.inventory.first?.quantityText == "1500 ml")
            #expect(repo.inventory.first?.isLowStock == false && grocery.isCompleted)
            try repo.toggle(grocery)
            try repo.recordPurchase(grocery, addToInventory: true, keeping: stock)
            #expect(repo.inventory.first?.quantityText == "1500 ml")
            // A second, distinct shopping trip is reviewed via its receipt.
            try repo.add(EntryDraft(kind: .grocery, title: "Milk", quantity: "1 litre"))
            let second = try #require(repo.groceries.first { !$0.isCompleted })
            let text = "MARKET\nMilk 4.00\nTOTAL 4.00"
            var lines = ReceiptRules.scan(text: text).lines
            lines[0].confirmedNewPurchase = true
            lines[0].quantity = "1 litre"; lines[0].inventoryID = stock; lines[0].groceryID = second.id; lines[0].amount = "4.00"
            var expense = ExpenseDraft(); expense.merchant = "Market"; expense.amount = "4.00"; expense.currency = "USD"
            let key = ExpenseRules.receiptKey(text)
            try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: key)
            #expect(repo.inventory.count == 1 && repo.inventory.first?.quantityText == "2500 ml")
            #expect(repo.expenses.count == 1 && repo.purchases.count == 2)
            #expect(repo.purchases.contains { $0.groceryID == second.id && $0.inventoryID == stock && $0.expenseID == repo.expenses.first?.id })
            #expect(try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: key) == 0)
            #expect(repo.inventory.first?.quantityText == "2500 ml")
            let report = ExpenseRules.summary(repo.expenseReportItems, month: ExpenseRules.month(.now), currency: "USD")
            #expect(report.spent == 400 && report.net == 400)
            try repo.add(EntryDraft(kind: .meal, title: "Milk oats", mealIngredients: "Milk\nOats", mealServings: 2, mealAmountsPerServing: ["Milk": "100 ml"]))
            let meal = try #require(repo.meals.first)
            #expect(try repo.addMealShopping(meal, names: ["Oats"]) == 1)
            #expect(try repo.addMealShopping(meal, names: ["oats"]) == 0)
            #expect(repo.mealIngredientAvailability("Oats").inShopping)
            let item = try #require(repo.inventory.first)
            let use = PantryUseReview(id: item.id, modifiedAt: item.modifiedAt, action: .amount, amount: "200", unit: .ml)
            try repo.finishMeal(meal, expectedModifiedAt: meal.modifiedAt, reviews: [use])
            #expect(item.quantityText == "2300 ml")
            #expect(throws: MealCookingError.self) { try repo.finishMeal(meal, expectedModifiedAt: meal.modifiedAt, reviews: [use]) }
        }
        try purchaseAndCook()
        let reopened = try open(); try reopened.reload()
        #expect(reopened.inventory.count == 1 && reopened.inventory.first?.quantityText == "2300 ml")
        #expect(reopened.expenses.first?.amountMinorUnits == 400)
        #expect(reopened.meals.first?.cookedAt != nil)
        #expect(reopened.groceries.filter { !$0.isCompleted }.map(\.name) == ["Oats"])
        let copy = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try copy.restoreBackup(reopened.makeBackup())
        #expect(copy.inventory.first?.quantityText == "2300 ml" && copy.purchases.count == 2)
    }

    @Test func newPurchaseNeverMergesIntoExpiredStock() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Ravi", members: [])
        let home = try #require(repo.household?.id)
        var pack = InventoryDraft(); pack.name = "Curd"; pack.quantity = "200 g"
        pack.hasExpiryDate = true; pack.expiryDate = Date.now.addingTimeInterval(-86400 * 3)
        let old = try repo.saveInventory(pack)
        try repo.add(EntryDraft(kind: .grocery, title: "Curd", quantity: "1 kg"))
        let grocery = try #require(repo.groceries.first)
        #expect(throws: HouseholdValidation.self) { try repo.recordPurchase(grocery, addToInventory: true, keeping: old) }
        try repo.recordPurchase(grocery, addToInventory: true)
        #expect(repo.inventory.count == 2)
        #expect(repo.inventory.first { $0.id == old }?.quantityText == "200 g")
        let fresh = try #require(repo.inventory.first { $0.id != old })
        #expect(fresh.quantityText == "1 kg" && fresh.expiryDay == nil)
        var lines = ReceiptRules.scan(text: "Curd 4.00").lines
        lines[0].inventoryID = old
        #expect(throws: ReceiptImportError.self) { try repo.importReceipt(lines, householdID: home, storeName: "Store") }
        #expect(repo.purchases.count == 1)
    }

    @Test func largeExpenseAmountsRoundTripWithout32BitTruncation() throws {
        let amount = try ExpenseRules.minorUnits("9999999999.00")
        #expect(ExpenseRules.amountText(amount) == "9999999999.00")
        #expect(try ExpenseRules.minorUnits(ExpenseRules.amountText(amount)) == amount)
    }
}
