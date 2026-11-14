import Foundation
import SwiftData
import Testing
@testable import LunaHearth

/// Regressions from the November 13, 2026 bug scan (docs/review/2026-11-13-bug-scan.md).
@MainActor struct BugScanRegressionTests {
    // 1. Header lines must not cut item-code receipts.
    @Test func taxInvoiceHeaderAndAddressKeepItems() {
        let text = "SRI LAKSHMI STORES\n1234 Anna Salai Chennai\nTAX INVOICE\nToor Dal 165.00\nRice 120.00\nNet Amount 285.00"
        let scan = ReceiptRules.scan(text: text, sameLinePrices: true)
        #expect(scan.lines.map(\.name) == ["Toor Dal", "Rice"])
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: text) == .verified)
    }
    @Test func storeNamedTotalKeepsItems() {
        let text = "TOTAL WINE & MORE\n5100 Belt Line Rd\nMERLOT 12.99\nSUBTOTAL 12.99\nTOTAL 12.99"
        #expect(ReceiptRules.scan(text: text, sameLinePrices: true).lines.map(\.name) == ["MERLOT"])
    }
    @Test func itemCodeRowsAfterAHeaderStillCutAtTheirSubtotal() {
        let text = "TAX INVOICE\nE 123456 MILK 10.00\nSUBTOTAL 10.00\n987654 GIFT CARD 5.00"
        #expect(ReceiptRules.scan(text: text, sameLinePrices: true).lines.map(\.name) == ["MILK"])
    }

    // 2. A catalog word inside another store's header is not that store.
    @Test func headerStoreNameMustStartTheRow() {
        #expect(ReceiptPurchaseDetails.knownStore(in: "TOTAL WINE & MORE\nMERLOT 12.99", saved: []) == nil)
        #expect(ReceiptPurchaseDetails.knownStore(in: "COSTCO WHOLESALE\nMILK 4.00", saved: []) == "Costco")
        #expect(ReceiptPurchaseDetails.knownStore(in: "** DMART **\nRice 120.00", saved: []) == "DMart")
    }

    private func repository() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "Owner", members: [])
        return repo
    }

    // 3. Room scans and documents stay local but no longer block sharing snapshots.
    @Test func syncSnapshotToleratesLocalRoomScans() throws {
        let repo = try repository()
        try repo.add(EntryDraft(kind: .room, title: "Kitchen"))
        let room = try #require(repo.rooms.first)
        try repo.commit { room.roomPlanAssetPath = "RoomPlans/kitchen.usdz" }
        #expect(throws: BackupError.self) { try repo.makeBackup() }
        let snapshot = try repo.makeSyncSnapshot()
        #expect(snapshot.records.contains { $0.id == room.id && $0.kind == "Room" })
    }

    // 4. Deleting an expense releases its purchases for a later receipt.
    @Test func deletingAnExpenseUnlinksItsPurchases() throws {
        let repo = try repository()
        try repo.add(EntryDraft(kind: .grocery, title: "Milk"))
        try repo.recordPurchase(try #require(repo.groceries.first), addToInventory: false)
        let purchase = try #require(repo.purchases.first)
        var draft = ExpenseDraft(); draft.merchant = "Market"; draft.amount = "4.00"; draft.currency = "USD"
        let expenseID = try repo.saveExpense(draft, purchaseID: purchase.purchaseID)
        let day = purchase.day
        #expect(repo.receiptPurchaseCandidates(name: "Milk", day: day).first?.alreadyLinked == true)
        try repo.deleteExpense(try #require(repo.expenses.first { $0.id == expenseID }))
        #expect(repo.purchases.first?.expenseID == nil)
        #expect(repo.receiptPurchaseCandidates(name: "Milk", day: day).first?.alreadyLinked == false)
    }

    // 6. A pantry-only import uses the receipt's date, not today.
    @Test func pantryOnlyImportUsesTheReceiptDate() throws {
        let repo = try repository()
        let home = try #require(repo.household?.id)
        var lines = ReceiptRules.scan(text: "Milk 4.00").lines
        lines[0].addToInventory = true
        let receiptDate = try #require(ShoppingEntryRules.date(for: "2026-10-02"))
        try repo.importReceipt(lines, householdID: home, storeName: "Market", receiptKey: ReceiptRules.hash("dated"), purchaseDate: receiptDate)
        #expect(repo.purchases.first?.day == "2026-10-02")
        #expect(repo.inventory.first?.purchasedDay == "2026-10-02")
    }
}
