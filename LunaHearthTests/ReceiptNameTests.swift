import Foundation
import Testing
@testable import LunaHearth

struct ReceiptNameTests {
    @Test func validatesGeneratedNamesAndIndexes() {
        let inputs = [ReceiptNameInput(id: "a", name: "ORG BANANA")]
        let proposal = ReceiptNameRules.proposal(index: 0, name: " Organic bananas ", inputs: inputs)
        #expect(proposal?.id == "a")
        #expect(proposal?.original == "ORG BANANA")
        #expect(proposal?.name == "Organic bananas")
        #expect(ReceiptNameRules.proposal(index: -1, name: "Bananas", inputs: inputs) == nil)
        #expect(ReceiptNameRules.proposal(index: 4, name: "Bananas", inputs: inputs) == nil)
        for invalid in ["", "123", "ORG BANANA", "Bananas\nOther item", "https://example.com", String(repeating: "a", count: 101)] {
            #expect(ReceiptNameRules.proposal(index: 0, name: invalid, inputs: inputs) == nil)
        }
        #expect(ReceiptNameRules.proposal(index: 0, name: "Bananas", inputs: [ReceiptNameInput(id: "b", name: "123456")]) == nil)
    }

    @Test func proposalsNeverOverwriteAnEditedOrDifferentLine() {
        let proposal = ReceiptNameProposal(id: "a", original: "GRK YOG", name: "Greek yogurt")
        var line = ReceiptLine(id: "a", name: "GRK YOG", quantity: "2 tubs")
        #expect(ReceiptNameRules.canApply(proposal, to: line))
        #expect(line.name == "GRK YOG") // A suggestion is not a mutation.
        line.name = "My yogurt"
        #expect(!ReceiptNameRules.canApply(proposal, to: line))
        line.name = "GRK YOG"; line.included = false
        #expect(!ReceiptNameRules.canApply(proposal, to: line))
        #expect(!ReceiptNameRules.canApply(proposal, to: ReceiptLine(id: "other", name: "GRK YOG")))
        #expect(line.quantity == "2 tubs")
    }
}

struct ReceiptSavedNameTests {
    @Test func costcoLabelOffersSavedNameWithoutChangingProduct() {
        let line = ReceiptLine(id: "one", name: "FAIRLIFECHOC")
        let proposal = ReceiptNameRules.savedProposal(for: line, names: ["Fairlife chocolate", "Milk"])
        #expect(proposal?.name == "Fairlife chocolate")
        #expect(proposal?.fromSavedItem == true)
        #expect(line.name == "FAIRLIFECHOC")
        #expect(ReceiptPurchaseMatching.possibleMatch(receipt: line.name, requested: "Fairlife chocolate"))
        #expect(!IngredientMatching.same(line.name, "Fairlife chocolate")) // Review-only, not automatic pantry identity.
    }
    @Test func meaningfulDifferencesAreNeverRemoved() {
        for name in ["Milk", "Chocolate", "Fairlife vanilla", "Fairlife chocolate milk", "Fairlife chocolate 12 pack", "Fairlife chocolate lactose free"] {
            #expect(!ReceiptNameRules.compactMatch("FAIRLIFECHOC", name))
        }
        #expect(!ReceiptNameRules.compactMatch("1485984", "Fairlife chocolate"))
        #expect(ReceiptNameRules.compactMatch("ORG BANANA", "Organic banana"))
        #expect(!ReceiptNameRules.compactMatch("ORG BANANA", "Banana"))
    }
    @Test func ambiguousSavedNamesRequireSelection() {
        let line = ReceiptLine(id: "one", name: "FAIRLIFECHOC")
        #expect(ReceiptNameRules.savedProposal(for: line, names: ["Fairlife choc", "Fairlife chocolate"]) == nil)
        #expect(ReceiptNameRules.savedProposal(for: line, names: ["Fairlife chocolate", "Fairlife chocolate"])?.name == "Fairlife chocolate")
    }
}

@MainActor struct ReceiptSavedNameImportTests {
    @Test func confirmedNameConnectsShoppingAndPantryWithoutLosingAssignee() throws {
        let repository = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repository.createHousehold(name: "Home", owner: "Sam", members: [("Kim", .adult)])
        let home = try #require(repository.household?.id)
        let member = try #require(repository.members.first { $0.displayName == "Kim" })
        var request = EntryDraft(kind: .grocery, title: "Fairlife chocolate")
        request.memberID = member.id
        try repository.add(request)
        let shopping = try #require(repository.groceries.first)
        var stock = InventoryDraft(); stock.name = "Fairlife chocolate"; stock.quantity = "1 piece"
        let stockID = try repository.saveInventory(stock)
        var lines = ReceiptRules.scan(text: "COSTCO\nE 1485984 FAIRLIFECHOC 39.99\nTOTAL $39.99").lines
        let suggestion = try #require(ReceiptNameRules.savedProposal(for: lines[0], names: [shopping.name]))
        #expect(ReceiptNameRules.canApply(suggestion, to: lines[0]))
        // The user explicitly accepts the name, shopping request and existing pantry pack.
        lines[0].name = suggestion.name; lines[0].groceryID = shopping.id; lines[0].inventoryID = stockID
        var expense = ExpenseDraft(); expense.merchant = "Costco"; expense.amount = "39.99"; expense.currency = "USD"
        #expect(try repository.importReceipt(lines, householdID: home, storeName: "Costco", expense: expense, receiptKey: ReceiptRules.hash("saved-name-test")) == 1)
        #expect(shopping.name == "Fairlife chocolate")
        #expect(shopping.assignedMemberID == member.id)
        #expect(shopping.isCompleted)
        #expect(repository.inventory.count == 1)
        #expect(repository.purchases.count == 1)
    }
}
