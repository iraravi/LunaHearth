import Foundation
import SwiftData
import Testing
@testable import LunaHearth

@MainActor struct ReceiptReconciliationTests {
    @Test func aiShoppingLinkNeedsExactReviewedSnapshotAndPreservesAssignment() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Sam", members: [("Kim", .adult)])
        let home = try #require(repo.household?.id)
        let member = try #require(repo.members.first { $0.displayName == "Kim" })
        var draft = EntryDraft(kind: .grocery, title: "Milk"); draft.memberID = member.id
        try repo.add(draft)
        let item = try #require(repo.groceries.first)
        var lines = ReceiptRules.scan(text: "BRAND WHOLE MILK 1GAL 4.00").lines
        lines[0].groceryID = item.id
        let key = ReceiptRules.hash("ai-reviewed")
        #expect(throws: ReceiptImportError.changedMatch) { try repo.importReceipt(lines, householdID: home, storeName: "Market", receiptKey: key) }
        lines[0].reviewedShoppingMatch = ReceiptShoppingApproval(groceryID: item.id, receiptName: "Old receipt label", shoppingName: item.name)
        #expect(throws: ReceiptImportError.changedMatch) { try repo.importReceipt(lines, householdID: home, storeName: "Market", receiptKey: key) }
        lines[0].reviewedShoppingMatch = ReceiptShoppingApproval(groceryID: item.id, receiptName: lines[0].name, shoppingName: "Old shopping label")
        #expect(throws: ReceiptImportError.changedMatch) { try repo.importReceipt(lines, householdID: home, storeName: "Market", receiptKey: key) }
        #expect(repo.purchases.isEmpty && repo.inventory.isEmpty)
        lines[0].reviewedShoppingMatch = ReceiptShoppingApproval(groceryID: item.id, receiptName: lines[0].name, shoppingName: item.name)
        #expect(try repo.importReceipt(lines, householdID: home, storeName: "Market", receiptKey: key) == 1)
        #expect(item.assignedMemberID == member.id && item.name == "Milk" && item.isCompleted)
        #expect(repo.inventory.count == 1 && repo.purchases.count == 1)
        #expect(try repo.importReceipt(lines, householdID: home, storeName: "Market", receiptKey: key) == 0)
        #expect(repo.inventory.count == 1)
    }

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
    @Test func separateReceiptPackKeepsOldDatesAndAmountsAndSurvivesReplay() throws {
        let repo = try setup(), home = try #require(repo.household?.id)
        let old = try #require(repo.inventory.first)
        old.purchasedDay = "2026-10-01"; old.expiryDay = "2099-01-01"
        try repo.context.save()
        var lines = ReceiptRules.scan(text: "Milk 6.00").lines
        lines[0].quantity = "2 litres"
        lines[0].confirmedNewPurchase = true
        lines[0].keepSeparatePack = true
        lines[0].expiryDay = "2099-02-01"
        let key = ReceiptRules.hash("separate-pack")
        let receiptExpense = expense
        #expect(try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: receiptExpense, receiptKey: key) == 1)
        #expect(repo.inventory.count == 2)
        #expect(old.quantityText == "1 litre" && old.purchasedDay == "2026-10-01" && old.expiryDay == "2099-01-01")
        let added = try #require(repo.inventory.first { $0.id != old.id })
        #expect(added.quantityText == "2 litres" && added.expiryDay == "2099-02-01")
        #expect(added.purchasedDay == HouseholdDay(receiptExpense.date).key)
        #expect(try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: receiptExpense, receiptKey: key) == 0)
        #expect(repo.inventory.count == 2 && repo.purchases.count == 2)
    }

    @Test func separatePackCannotAlsoTargetExistingInventory() throws {
        let repo = try setup(), home = try #require(repo.household?.id)
        var lines = ReceiptRules.scan(text: "Milk 6.00").lines
        lines[0].confirmedNewPurchase = true
        lines[0].keepSeparatePack = true
        lines[0].inventoryID = repo.inventory.first?.id
        #expect(throws: ReceiptImportError.changedMatch) { try repo.importReceipt(lines, householdID: home, storeName: "Market") }
        #expect(repo.inventory.count == 1 && repo.purchases.count == 1 && repo.expenses.isEmpty)
    }

    @Test func newReceiptRestockPreservesOriginalPackDateButRecordsNewPurchaseDate() throws {
        let repo = try setup(), home = try #require(repo.household?.id)
        let pack = try #require(repo.inventory.first)
        pack.purchasedDay = "2026-10-01"
        try repo.context.save()
        var lines = ReceiptRules.scan(text: "Milk 7.00").lines
        lines[0].confirmedNewPurchase = true; lines[0].inventoryID = pack.id; lines[0].quantity = "1 litre"
        let receiptExpense = expense
        try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: receiptExpense, receiptKey: ReceiptRules.hash("restock-dates"))
        #expect(pack.purchasedDay == "2026-10-01" && pack.quantityText == "2 l")
        let purchase = try #require(repo.purchases.first { $0.id == ReceiptRules.groceryID(home: home, key: "purchase-line|" + lines[0].id) })
        #expect(purchase.day == HouseholdDay(receiptExpense.date).key)
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
    @Test func genericMuttonRequestLinksAfterReviewWithoutLosingAssignment() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Alex", members: [("Sam", .adult)])
        let home = try #require(repo.household?.id), member = try #require(repo.members.first?.id)
        var draft = EntryDraft(kind: .grocery, title: "Mutton", memberID: member, quantity: "1 lb", storeName: "Original shop")
        draft.quantityUnit = .custom
        try repo.add(draft)
        let grocery = try #require(repo.groceries.first)
        var lines = ReceiptRules.scan(text: "PREMIUM MUTTON LEG 12.00").lines
        #expect(lines.count == 1)
        lines[0].groceryID = grocery.id; lines[0].addToInventory = true
        try repo.importReceipt(lines, householdID: home, storeName: "Actual shop")
        #expect(repo.groceries.count == 1 && grocery.isCompleted)
        #expect(grocery.name == "Mutton" && grocery.assignedMemberID == member)
        #expect(repo.inventory.first?.name == "PREMIUM MUTTON LEG")
        #expect(repo.purchases.count == 1)
        #expect(try repo.importReceipt(lines, householdID: home, storeName: "Actual shop") == 0)
        #expect(repo.inventory.count == 1)
    }

    @Test func previouslyBoughtGenericMuttonIsOfferedWithoutDoubleStocking() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        try repo.add(EntryDraft(kind: .grocery, title: "Mutton", quantity: "1 lb"))
        try repo.recordPurchase(try #require(repo.groceries.first), addToInventory: false)
        var lines = ReceiptRules.scan(text: "PREMIUM MUTTON LEG 12.00").lines
        let candidates = repo.receiptPurchaseCandidates(name: lines[0].name, day: HouseholdDay(.now).key)
        #expect(candidates.count == 1)
        let home = try #require(repo.household?.id)
        #expect(throws: ReceiptImportError.reviewPurchase) { try repo.importReceipt(lines, householdID: home, storeName: "Another shop") }
        lines[0].existingPurchaseID = candidates.first?.id
        try repo.importReceipt(lines, householdID: home, storeName: "Another shop")
        #expect(repo.purchases.count == 1 && repo.groceries.count == 1 && repo.inventory.isEmpty)
    }

    @Test func receiptSuggestionsKeepMeaningfulFormsAndSpeciesSeparate() {
        #expect(ReceiptPurchaseMatching.possibleMatch(receipt: "PREMIUM MUTTON LEG", requested: "Mutton"))
        for pair in [("Mutton leg", "Mutton chops"), ("Mutton gravy", "Mutton"), ("Mutton leg", "Lamb"), ("Cumin powder", "Cumin"), ("Almond milk", "Milk"), ("Chicken feed", "Chicken")] {
            #expect(!ReceiptPurchaseMatching.possibleMatch(receipt: pair.0, requested: pair.1))
        }
        #expect(!IngredientMatching.same("Mutton", "Premium mutton leg"))
    }

    @Test func twoReceiptRowsCannotClaimOneReviewedShoppingItem() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Owner", members: [])
        try repo.add(EntryDraft(kind: .grocery, title: "Mutton"))
        let item = try #require(repo.groceries.first), home = try #require(repo.household?.id)
        var lines = ReceiptRules.scan(text: "MUTTON LEG 12.00\nMUTTON CHOPS 8.00").lines
        #expect(lines.count == 2)
        for index in lines.indices { lines[index].groceryID = item.id }
        #expect(throws: ReceiptImportError.changedMatch) {
            try repo.importReceipt(lines, householdID: home, storeName: "Shop", expense: expense, receiptKey: ReceiptRules.hash("two cuts"))
        }
        #expect(!item.isCompleted && repo.purchases.isEmpty && repo.inventory.isEmpty && repo.expenses.isEmpty)
    }

    @Test func completedShoppingItemInvalidatesEarlierAIApprovalAtomically() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Owner", members: [])
        try repo.add(EntryDraft(kind: .grocery, title: "Milk"))
        let item = try #require(repo.groceries.first), home = try #require(repo.household?.id)
        var lines = ReceiptRules.scan(text: "BRAND WHOLE MILK 1GAL 4.00\nBananas 3.00").lines
        lines[0].groceryID = item.id
        lines[0].reviewedShoppingMatch = ReceiptShoppingApproval(groceryID: item.id, receiptName: lines[0].name, shoppingName: item.name)
        item.isCompleted = true
        try repo.context.save()
        #expect(throws: ReceiptImportError.changedMatch) {
            try repo.importReceipt(lines, householdID: home, storeName: "Shop", expense: expense, receiptKey: ReceiptRules.hash("stale completion"))
        }
        #expect(repo.purchases.isEmpty && repo.inventory.isEmpty && repo.expenses.isEmpty)
    }

    @Test func recentPurchaseWindowIncludesSevenDaysButNotEightAcrossDST() {
        for (receiptDay, purchasedDay, included) in [
            ("2026-03-10", "2026-03-03", true), ("2026-03-10", "2026-03-02", false),
            ("2026-11-04", "2026-10-28", true), ("2026-11-04", "2026-10-27", false),
            ("2026-11-04", "2026-11-11", true), ("2026-11-04", "2026-11-12", false)
        ] {
            let purchase = ReceiptPurchaseCandidate(id: UUID(), name: "Mutton", quantity: "", merchant: "", day: purchasedDay, alreadyLinked: false)
            #expect(!ReceiptPurchaseMatching.candidates(name: "Premium mutton leg", day: receiptDay, purchases: [purchase]).isEmpty == included)
        }
        let invalid = ReceiptPurchaseCandidate(id: UUID(), name: "Milk", quantity: "", merchant: "", day: "2026-02-30", alreadyLinked: false)
        #expect(ReceiptPurchaseMatching.candidates(name: "Milk", day: "2026-03-01", purchases: [invalid]).isEmpty)
    }

}
