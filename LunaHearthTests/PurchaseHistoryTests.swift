import Foundation
import SwiftData
import Testing
@testable import LunaHearth

@MainActor struct PurchaseHistoryTests {
    private func repo() throws -> LocalHouseholdRepository {
        let result = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try result.createHousehold(name: "Home", owner: "", members: [])
        return result
    }
    @Test func receiptLinksExpenseShoppingAndInventoryAndRestoresHistory() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        let text = "COSTCO\nMilk 4.00\nTOTAL 4.00"
        var lines = ReceiptRules.scan(text: text).lines
        lines[0].quantity = "2 bottles"; lines[0].amount = "4.00"
        var expense = ExpenseDraft(); expense.merchant = "Costco"; expense.amount = "4.00"
        try repo.importReceipt(lines, householdID: home, storeName: "Costco", expense: expense, receiptKey: ExpenseRules.receiptKey(text))
        let entry = try #require(repo.purchases.first)
        #expect(entry.expenseID == repo.expenses.first?.id)
        #expect(entry.inventoryID == repo.inventory.first?.id)
        #expect(entry.groceryID == repo.groceries.first?.id)
        #expect(entry.amountMinorUnits == 400 && entry.quantity == "2 bottles" && entry.stockAction == "added")
        #expect(try repo.importReceipt(lines, householdID: home, storeName: "Costco", expense: expense, receiptKey: ExpenseRules.receiptKey(text)) == 0)
        #expect(repo.purchases.count == 1)
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(repo.makeBackup())
        #expect(restored.purchases.first?.id == entry.id)
        #expect(restored.purchases.first?.inventoryID == entry.inventoryID)
        try restored.deleteExpense(try #require(restored.expenses.first))
        try restored.deleteInventory(try #require(restored.inventory.first))
        #expect(restored.purchases.count == 1)
        try BackupCodec.validate(restored.makeBackup())
    }
    @Test func restockHistoryAndLaterExpenseDoNotCreateDuplicateStock() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        var draft = InventoryDraft(); draft.name = "Curd"; draft.quantity = "1 tub"; draft.isLowStock = true
        let inventoryID = try repo.saveInventory(draft)
        var lines = ReceiptRules.scan(text: "Curd 3.00").lines
        lines[0].inventoryID = inventoryID; lines[0].quantity = "2 tubs"
        let key = ReceiptRules.hash("curd receipt")
        try repo.importReceipt(lines, householdID: home, storeName: "Costco", receiptKey: key)
        let entry = try #require(repo.purchases.first)
        #expect(entry.inventoryID == inventoryID && entry.stockAction == "restocked")
        #expect(repo.inventory.count == 1 && repo.inventory.first?.isLowStock == false)
        var expense = ExpenseDraft(); expense.merchant = "Costco"; expense.amount = "3.00"
        let other = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try other.restoreBackup(repo.makeBackup())
        try repo.saveExpense(expense, purchaseID: entry.purchaseID)
        try other.saveExpense(expense, purchaseID: entry.purchaseID)
        #expect(other.expenses.first?.id == repo.expenses.first?.id)
        #expect(repo.purchases.first?.expenseID == repo.expenses.first?.id)
        #expect(throws: HouseholdValidation.self) { try repo.saveExpense(expense, purchaseID: entry.purchaseID) }
        try repo.importReceipt(lines, householdID: home, storeName: "Costco", expense: expense, receiptKey: key)
        #expect(repo.expenses.count == 1 && repo.purchases.count == 1 && repo.inventory.count == 1)
    }
    @Test func invalidItemPriceRollsBackWholeReceipt() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        var lines = ReceiptRules.scan(text: "Milk 4.00").lines; lines[0].amount = "-4"
        var expense = ExpenseDraft(); expense.merchant = "Store"; expense.amount = "4"
        #expect(throws: ExpenseError.self) { try repo.importReceipt(lines, householdID: home, storeName: "Store", expense: expense, receiptKey: ReceiptRules.hash("test")) }
        #expect(repo.purchases.isEmpty && repo.expenses.isEmpty && repo.inventory.isEmpty && repo.groceries.isEmpty)
    }
}
