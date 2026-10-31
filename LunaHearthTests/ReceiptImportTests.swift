import Foundation
import SwiftData
import Testing
import UIKit
@testable import LunaHearth

@MainActor struct ReceiptImportTests {
    private func repo() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        return repo
    }
    @Test func bulkInventorySelectionPreservesExcludedAndLinkedPurchases() {
        var lines = [ReceiptLine(id: "new", name: "Milk", addToInventory: false),
                     ReceiptLine(id: "excluded", name: "Bread", included: false, addToInventory: false),
                     ReceiptLine(id: "linked", name: "Rice", addToInventory: false, existingPurchaseID: UUID()),
                     ReceiptLine(id: "imported", name: "Curd", addToInventory: false)]
        ReceiptInventorySelection.setAll(true, lines: &lines, unavailableIDs: ["imported"])
        #expect(lines.map(\.addToInventory) == [true, false, false, false])
        ReceiptInventorySelection.setAll(false, lines: &lines, unavailableIDs: ["imported"])
        #expect(lines.allSatisfy { !$0.addToInventory })
    }
    @Test func parserExcludesPaymentsAndNeverUsesPriceAsQuantity() {
        let scan = ReceiptRules.scan(text: "MARKET\n123456 CURD 3.99 T\n2 x BANANAS 2.49\nSUBTOTAL 6.48\nTax 0.25\nTOTAL 6.73\nVISA 6.73\nCoupon -1.00\nRefund curd 3.99")
        #expect(scan.lines.map(\.name) == ["CURD", "BANANAS"])
        #expect(scan.lines[0].quantity.isEmpty)
        #expect(scan.lines[1].quantity == "2 pieces")
        #expect(scan.lines.map(\.id) == ReceiptRules.scan(text: scan.text).lines.map(\.id))
        #expect(ReceiptRules.scan(text: "TOTAL 25.00\nNet Amount 25.00\nAmount payable 25.00\nThank you").lines.isEmpty)
    }
    @Test func currencyLabelsAndWholeRupeesDoNotDropItems() {
        let result = ReceiptRules.scan(text: "MARKET\nMilk ₹60\nCurd Rs. 35.00\nRice INR 120\nApples₹80.00\nBread $2.00\nTOTAL INR 297.00")
        #expect(result.lines.map(\.name) == ["Milk", "Curd", "Rice", "Apples", "Bread"])
        #expect(result.lines.allSatisfy { $0.quantity.isEmpty && $0.amount.isEmpty })
    }

    @Test func currencyFormatsDoNotTurnRefundsOrPackSizesIntoPurchases() {
        let result = ReceiptRules.scan(text: "Milk - ₹60.00\nCurd ₹-35.00\nRice −120.00\nBread -2.00\nMilk 500\nTOTAL ₹120\nCGST Rs. 5.00\nVISA $20.00")
        #expect(result.lines.isEmpty)
    }

    @Test func repeatedIngredientLinesAreOneReviewRow() {
        let result = ReceiptRules.scan(text: "2 x CURD 4.00\n3 x Curd 6.00\nMilk 2.00\nMILK 2.00")
        #expect(result.lines.count == 2)
        #expect(result.lines[0].quantity == "5 pieces")
        #expect(result.lines[1].quantity.isEmpty)
    }
    @Test func receiptCompletesMatchedShoppingRestocksAndAddsNewFoodAtomically() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        var draft = InventoryDraft(); draft.name = "Curd"; draft.isLowStock = true; draft.quantity = "1 tub"
        let inventoryID = try repo.saveInventory(draft)
        try repo.add(EntryDraft(kind: .grocery, title: "Curd"))
        let groceryID = try #require(repo.groceries.first?.id)
        var lines = ReceiptRules.scan(text: "STORE\nCurd 3.99\n2 x Bananas 2.49\nTOTAL 6.48").lines
        lines[0].groceryID = groceryID; lines[0].inventoryID = inventoryID
        #expect(try repo.importReceipt(lines, householdID: home, storeName: "Costco") == 2)
        #expect(repo.groceries.count == 2 && repo.groceries.allSatisfy(\.isCompleted))
        #expect(repo.inventory.count == 2)
        #expect(repo.inventory.first(where: { $0.id == inventoryID })?.isLowStock == false)
        #expect(repo.inventory.first(where: { $0.id == inventoryID })?.quantityText == "1 tub")
        #expect(repo.inventory.first(where: { $0.name == "Bananas" })?.quantityText == "2 pieces")
        #expect(repo.stores.count == 1)
        let copy = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try copy.restoreBackup(repo.makeBackup())
        #expect(copy.groceries.allSatisfy { $0.receiptImportKey != nil })
        #expect(try copy.importReceipt(lines, householdID: home, storeName: "Costco") == 0)
        #expect(copy.inventory.count == 2 && copy.groceries.count == 2)
    }
    @Test func invalidSecondLineDoesNotPartiallyCompleteFirst() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        try repo.add(EntryDraft(kind: .grocery, title: "Curd"))
        var lines = ReceiptRules.scan(text: "Curd 3.99\nMilk 2.49").lines
        lines[0].groceryID = repo.groceries.first?.id
        lines[1].name = " "
        #expect(throws: HouseholdValidation.self) { try repo.importReceipt(lines, householdID: home, storeName: "Costco") }
        #expect(repo.inventory.isEmpty && repo.stores.isEmpty && repo.groceries.first?.isCompleted == false)
        lines[1].name = "Milk"; lines[1].groceryID = UUID()
        #expect(throws: ReceiptImportError.self) { try repo.importReceipt(lines, householdID: home, storeName: "") }
        #expect(repo.inventory.isEmpty)
    }
    @Test func excludedAndElsewhereItemsNeverStockHome() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        var lines = ReceiptRules.scan(text: "Curd 3.99\nMilk 2.49").lines
        lines[0].included = false; lines[1].addToInventory = false
        #expect(try repo.importReceipt(lines, householdID: home, storeName: "") == 1)
        #expect(repo.inventory.isEmpty && repo.groceries.first?.purchaseDisposition == "elsewhere")
        #expect(throws: HouseholdValidation.self) { try repo.importReceipt(lines, householdID: UUID(), storeName: "") }
    }
    @Test func staleInventoryMatchCannotCreateDuplicate() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        var draft = InventoryDraft(); draft.name = "Curd"
        try repo.saveInventory(draft)
        let lines = ReceiptRules.scan(text: "Curd 3.99").lines
        #expect(throws: InventoryError.self) { try repo.importReceipt(lines, householdID: home, storeName: "") }
        #expect(repo.groceries.isEmpty && repo.inventory.count == 1)
    }
    @Test func readOnlyAndDuplicateReviewSaveNothing() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        var lines = ReceiptRules.scan(text: "Curd 3.99\nMilk 2.49").lines
        lines[1].name = "CURD"
        #expect(throws: ReceiptImportError.self) { try repo.importReceipt(lines, householdID: home, storeName: "") }
        #expect(repo.inventory.isEmpty && repo.groceries.isEmpty)
        lines[1].name = "Milk"
        try repo.configureSharing(SyncDestination(householdID: home, zoneName: "LHHousehold-\(home)", ownerName: "owner", accountID: "account", isOwner: false))
        repo.syncConfiguration?.readOnly = true
        #expect(throws: HouseholdSharingError.self) { try repo.importReceipt(lines, householdID: home, storeName: "Costco") }
        #expect(repo.inventory.isEmpty && repo.groceries.isEmpty && repo.stores.isEmpty)
    }

    @Test func cameraEncodingBoundsSizeAndPreservesReadableText() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 3000, height: 4000), format: format).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 3000, height: 4000))
            ("MARKET\nCURD 3.99\nTOTAL 3.99" as NSString).draw(
                in: CGRect(x: 200, y: 200, width: 2600, height: 1200),
                withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 120, weight: .regular), .foregroundColor: UIColor.black])
        }
        let data = try await ReceiptCameraEncoder().encode(image)
        let output = try #require(UIImage(data: data))
        #expect(max(output.size.width, output.size.height) <= 2600)
        let scan = try await VisionReceiptScanner().scan(imageData: data)
        #expect(scan.lines.contains { $0.name.localizedCaseInsensitiveContains("curd") })
    }

    @Test func invalidAndOversizedImagesFailWithoutRecognition() async {
        for data in [Data(), Data("not an image".utf8), Data(repeating: 0, count: 20_000_001)] {
            do {
                _ = try await VisionReceiptScanner().scan(imageData: data)
                Issue.record("Invalid image was accepted")
            } catch {
                #expect(error is ReceiptImportError)
            }
        }
    }

    @Test func visionReadsActualReceiptImage() async throws {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 900, height: 700))
        let data = renderer.jpegData(withCompressionQuality: 0.95) { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 900, height: 700))
            let text = "FRESH MARKET\n\nCURD                 3.99\nBANANAS              2.49\n\nTOTAL                6.48"
            (text as NSString).draw(in: CGRect(x: 50, y: 60, width: 800, height: 580), withAttributes: [.font: UIFont.monospacedSystemFont(ofSize: 36, weight: .regular), .foregroundColor: UIColor.black])
        }
        let scan = try await VisionReceiptScanner().scan(imageData: data)
        #expect(scan.lines.contains { $0.name.localizedCaseInsensitiveContains("curd") })
        #expect(scan.lines.contains { $0.name.localizedCaseInsensitiveContains("bananas") })
        #expect(!scan.lines.contains { $0.name.localizedCaseInsensitiveContains("total") })
    }
}
