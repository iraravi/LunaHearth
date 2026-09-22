import Foundation
import SwiftData
import Testing
@testable import LunaHearth

@MainActor struct ReceiptReconciliationTests {
    private func setup() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Receipt audit", owner: "Owner", members: [])
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", quantity: "1 litre"))
        try repo.recordPurchase(try #require(repo.groceries.first), addToInventory: true)
        return repo
    }
    private var expense: ExpenseDraft {
        var value = ExpenseDraft(); value.merchant = "Market"; value.amount = "4.00"; value.currency = "USD"
        return value
    }
    @Test func boughtThenReceiptRequiresReviewAndNeverStocksAgain() throws {
        let repo = try setup(), home = try #require(repo.household?.id)
        let key = ReceiptRules.hash("first receipt")
        var lines = ReceiptRules.scan(text: "Milk 4.00").lines
        lines[0].quantity = "1 litre"; lines[0].inventoryID = repo.inventory.first?.id
        #expect(throws: ReceiptImportError.reviewPurchase) { try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: key) }
        #expect(repo.expenses.isEmpty && repo.inventory.first?.quantityText == "1 litre")
        let id = try #require(repo.purchases.first?.id)
        lines[0].existingPurchaseID = id
        #expect(try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: key) == 1)
        #expect(repo.inventory.first?.quantityText == "1 litre")
        #expect(repo.purchases.count == 1 && repo.purchases.first?.id == id)
        #expect(repo.expenses.count == 1 && repo.purchases.first?.expenseID == repo.expenses.first?.id)
        #expect(repo.purchases.first?.receiptLineKey == lines[0].id)
        // History retains replay protection even if the shopping record has disappeared.
        try repo.deletePlanningEntry(id: try #require(repo.groceries.first?.id), kind: .grocery)
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(repo.makeBackup())
        #expect(try restored.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: key) == 0)
        #expect(restored.inventory.first?.quantityText == "1 litre" && restored.expenses.count == 1)
    }
    @Test func reviewedNewPurchaseAddsOnceAndRescanDoesNotGuess() throws {
        let repo = try setup(), home = try #require(repo.household?.id)
        var lines = ReceiptRules.scan(text: "Milk 5.00").lines
        lines[0].quantity = "1 litre"; lines[0].inventoryID = repo.inventory.first?.id
        lines[0].confirmedNewPurchase = true
        try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: ReceiptRules.hash("second"))
        #expect(repo.inventory.first?.quantityText == "2 l")
        var rescanned = ReceiptRules.scan(text: "MILK 5.00 T").lines
        rescanned[0].inventoryID = repo.inventory.first?.id
        #expect(throws: ReceiptImportError.reviewPurchase) { try repo.importReceipt(rescanned, householdID: home, storeName: "Market") }
        rescanned[0].existingPurchaseID = repo.purchases.first(where: { $0.expenseID != nil })?.id
        #expect(throws: ReceiptImportError.alreadyExpensed) { try repo.importReceipt(rescanned, householdID: home, storeName: "Market") }
        #expect(repo.inventory.first?.quantityText == "2 l" && repo.expenses.count == 1)
    }
    @Test func linkingConsumedPackDoesNotResurrectStockOrClearLowFlag() throws {
        let repo = try setup(), home = try #require(repo.household?.id)
        let item = try #require(repo.inventory.first)
        item.quantityText = "0 l"; item.isLowStock = true; item.isUsedUp = true
        try repo.context.save()
        var lines = ReceiptRules.scan(text: "Milk 4.00").lines
        lines[0].existingPurchaseID = repo.purchases.first?.id
        lines[0].quantity = "10 litres"; lines[0].expiryDay = "2099-01-01"
        try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: ReceiptRules.hash("consumed"))
        #expect(item.quantityText == "0 l" && item.isUsedUp && item.isLowStock == true && item.expiryDay == nil)
    }
    @Test func changedOrCrossHomePurchaseRejectsWholeReview() throws {
        let repo = try setup(), home = try #require(repo.household?.id)
        var lines = ReceiptRules.scan(text: "Milk 4.00\nBananas 3.00").lines
        lines[0].existingPurchaseID = UUID()
        #expect(throws: ReceiptImportError.changedMatch) { try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: ReceiptRules.hash("bad")) }
        #expect(repo.inventory.count == 1 && repo.expenses.isEmpty)
        lines[0].existingPurchaseID = repo.purchases.first?.id
        lines[1].name = ""
        #expect(throws: HouseholdValidation.self) { try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: ReceiptRules.hash("bad")) }
        #expect(repo.purchases.first?.receiptLineKey == nil && repo.expenses.isEmpty)
    }
    @Test func legacyPurchasePayloadStillDecodesWithoutMarker() throws {
        let repo = try setup()
        let snapshot = try repo.makeBackup()
        let records = try snapshot.records.map { record -> BackupRecord in
            guard record.kind == "PurchaseEntry" else { return record }
            var payload = try #require(JSONSerialization.jsonObject(with: record.payload) as? [String: Any])
            payload.removeValue(forKey: "receiptLineKey")
            return BackupRecord(id: record.id, householdID: record.householdID, kind: record.kind,
                createdAt: record.createdAt, modifiedAt: record.modifiedAt,
                payload: try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]))
        }
        let legacy = try BackupCodec.snapshot(householdID: snapshot.householdID, records: records)
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(legacy)
        #expect(restored.purchases.count == 1 && restored.purchases.first?.receiptLineKey == nil)
        #expect(restored.inventory.first?.quantityText == "1 litre")
    }
    @Test func candidateWindowIncludesAliasesButNotUnrelatedOldPurchases() {
        let item = ReceiptPurchaseCandidate(id: UUID(), name: "cumin seeds", quantity: "", merchant: "", day: "2026-09-10", alreadyLinked: false)
        #expect(ReceiptPurchaseMatching.candidates(name: "Cumin", day: "2026-09-14", purchases: [item]).count == 1)
        #expect(ReceiptPurchaseMatching.candidates(name: "Cumin", day: "2026-09-20", purchases: [item]).isEmpty)
        #expect(ReceiptPurchaseMatching.candidates(name: "Milk", day: "2026-09-14", purchases: [item]).isEmpty)
    }
}
