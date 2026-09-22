import Foundation
import Testing
@testable import LunaHearth

@MainActor struct ConnectedDemoTests {
    @Test func sampleReceiptFlowsThroughRealOCRAndRepository() async throws {
        let data = try #require(DemoReceiptImage.make().pngData())
        let scan = try await VisionReceiptScanner().scan(imageData: data)
        #expect(scan.lines.count == 5)
        #expect(ExpenseRules.receiptTotal(scan.text) == "16.00")
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Demo", owner: "", members: [])
        let home = try #require(repo.household?.id)
        for line in scan.lines { try repo.add(EntryDraft(kind: .grocery, title: line.name)) }
        var lines = scan.lines
        for index in lines.indices {
            lines[index].groceryID = repo.groceries.first { IngredientMatching.same($0.name, lines[index].name) }?.id
            lines[index].expiryDay = "2026-10-01"
        }
        var expense = ExpenseDraft(); expense.merchant = "Luna Demo Market"; expense.amount = "16.00"; expense.currency = "USD"
        try repo.importReceipt(lines, householdID: home, storeName: expense.merchant, expense: expense, receiptKey: ExpenseRules.receiptKey(scan.text))
        #expect(repo.expenses.first?.amountMinorUnits == 1600)
        #expect(repo.inventory.count == 5 && repo.purchases.count == 5)
        #expect(repo.groceries.allSatisfy { $0.isCompleted })
        #expect(repo.inventory.allSatisfy { $0.expiryDay == "2026-10-01" })
        #expect(repo.syncConfiguration == nil)
        let curdRice = try #require(ConnectedDemo.ideas.first)
        #expect(curdRice.missing(from: repo.inventory.map(\.name)).isEmpty)
        #expect(ConnectedDemo.ideas[2].missing(from: repo.inventory.map(\.name)) == ["Oats", "Milk"])
    }
    @Test func invalidExpiryDoesNotSaveAndRestockDatesNeedExplicitReview() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Demo", owner: "", members: [])
        let home = try #require(repo.household?.id)
        var draft = InventoryDraft(); draft.name = "Curd"; draft.hasExpiryDate = true
        let firstExpiry = HouseholdDay(Date.now.addingTimeInterval(30 * 86400)).key
        let nextExpiry = HouseholdDay(Date.now.addingTimeInterval(40 * 86400)).key
        draft.expiryDate = try #require(ShoppingEntryRules.date(for: firstExpiry))
        let id = try repo.saveInventory(draft)
        var lines = ReceiptRules.scan(text: "Curd 3.00").lines; lines[0].inventoryID = id
        lines[0].expiryDay = "invalid"
        #expect(throws: InventoryError.self) { try repo.importReceipt(lines, householdID: home, storeName: "Demo") }
        #expect(repo.purchases.isEmpty)
        lines[0].expiryDay = nil
        try repo.importReceipt(lines, householdID: home, storeName: "Demo")
        #expect(repo.inventory.first?.expiryDay == firstExpiry)
        var next = ReceiptLine(id: ReceiptRules.hash("next curd purchase"), name: "Curd")
        next.confirmedNewPurchase = true
        next.inventoryID = id; next.expiryDay = nextExpiry
        try repo.importReceipt([next], householdID: home, storeName: "Demo")
        #expect(repo.inventory.first?.expiryDay == nextExpiry)
    }
}
