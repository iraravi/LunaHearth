import Foundation
import SwiftData
import Testing
import UIKit
@testable import LunaHearth

@MainActor struct ReceiptExpenseOnlyTests {
    @Test func expenseOnlyReceiptRetainsImageWithoutCreatingProducts() async throws {
        let container = try LocalStoreConfiguration.makeContainer(inMemory: true)
        let repo = LocalHouseholdRepository(container: container)
        try repo.createHousehold(name: "Test home", owner: "", members: [])
        let home = try #require(repo.household?.id)
        let text = "TEST MARKET\nMilk 4.00\nSUBTOTAL 8.00\nTOTAL USD 8.00"
        let scan = ReceiptRules.scan(text: text, sameLinePrices: true)
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: text) == .unverified(.mismatch))
        let key = ExpenseRules.receiptKey(text)
        var expense = ExpenseDraft(category: .groceries)
        expense.merchant = "Test market"; expense.amount = "8.00"; expense.currency = "USD"
        #expect(try repo.importReceipt([], householdID: home, storeName: expense.merchant, expense: expense, receiptKey: key) == 0)
        #expect(repo.expenses.count == 1)
        #expect(repo.groceries.isEmpty && repo.inventory.isEmpty && repo.purchases.isEmpty)

        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let storage = LocalReceiptImages(root: root)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 200)).jpegData(withCompressionQuality: 0.65) { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 100, height: 200))
        }
        let id = ReceiptRules.groceryID(home: home, key: "purchase|" + key)
        // Images remain opt-in: importing the expense alone writes no image.
        #expect(try await storage.load(home: home, purchase: id).isEmpty)
        try await storage.save([image], home: home, purchase: id)
        let reopened = LocalHouseholdRepository(container: container)
        try reopened.reload()
        let saved = try #require(reopened.expenses.first)
        let reopenedID = ReceiptRules.groceryID(home: saved.householdID, key: "purchase|" + (saved.receiptKey ?? ""))
        #expect(try await LocalReceiptImages(root: root).load(home: home, purchase: reopenedID) == [image])
        #expect(try repo.importReceipt([], householdID: home, storeName: expense.merchant, expense: expense, receiptKey: key) == 0)
        #expect(repo.expenses.count == 1)
        try await storage.remove(home: home, purchase: reopenedID)
        #expect(try await storage.load(home: home, purchase: reopenedID).isEmpty)
        #expect(repo.expenses.count == 1 && repo.inventory.isEmpty && repo.groceries.isEmpty)
    }
}
