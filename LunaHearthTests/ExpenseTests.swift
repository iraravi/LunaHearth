import Foundation
import SwiftData
import Testing
@testable import LunaHearth

@MainActor struct ExpenseTests {
    private func repo() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        return repo
    }
    @Test func moneyIsExactAndRejectsAmbiguousOrOverflowingValues() throws {
        #expect(try ExpenseRules.minorUnits("0.10") == 10)
        #expect(try ExpenseRules.minorUnits("1234.56") == 123456)
        #expect(try ExpenseRules.minorUnits("12,50") == 1250)
        for value in ["-2", "0", "12.345", "1,234.56", "nan", "10000000000"] {
            #expect(throws: ExpenseError.self) { try ExpenseRules.minorUnits(value) }
        }
        #expect(ExpenseRules.receiptTotal("Subtotal 20.00\nTax 1.20\nTOTAL 21.20\nVISA 21.20") == "21.20")
        #expect(ExpenseRules.receiptTotal("Subtotal 20.00\nVISA 21.20") == nil)
        #expect(ExpenseRules.receiptTotal("TOTAL 21.20\nTOTAL SAVINGS 5.00") == "21.20")
    }
    @Test func receiptTotalsSupportCommonPrintedFormatsWithoutGuessing() throws {
        let examples = [
            ("GRAND TOTAL: Rs. 1,234.50", "1234.50"),
            ("TOTAL\n₹ 250", "250.00"),
            ("TOTAL INR ₹250.00", "250.00"),
            ("Net Amount 1,23,456.70", "123456.70"),
            ("Amount payable: 12,50 EUR", "12.50"),
            ("Total 1.234,56 €", "1234.56"),
            ("Total 100.00\nGrand Total 118.00\nCash 200.00\nChange 82.00", "118.00")
        ]
        for (text, expected) in examples { #expect(ExpenseRules.receiptTotal(text) == expected) }
        for text in ["Total items 12", "Total savings 5.00", "Total 12.00\nTotal 15.00", "Total 1,234", "Subtotal 20.00\nCash 30.00"] {
            #expect(ExpenseRules.receiptTotal(text) == nil)
        }
        #expect(ExpenseRules.receiptCurrency("TOTAL Rs. 250.00") == "INR")
        #expect(ExpenseRules.receiptCurrency("TOTAL $25.00") == nil)
        #expect(ExpenseRules.receiptCurrency("INR 250.00 / USD 3.00") == nil)
    }

    @Test func reviewedReceiptTotalAndInventoryChoicePersistIndependently() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        let text = "Market\nMilk 40.00\nRice 100.00\nGrand Total Rs. 147.00"
        var lines = ReceiptRules.scan(text: text).lines
        for index in lines.indices { lines[index].addToInventory = lines[index].name == "Milk" }
        var draft = ExpenseDraft(); draft.merchant = "Market"
        draft.amount = try #require(ExpenseRules.receiptTotal(text)); draft.currency = "INR"
        try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: draft, receiptKey: ExpenseRules.receiptKey(text))
        #expect(repo.expenses.first?.amountMinorUnits == 14700)
        #expect(repo.expenses.first?.currencyCode == "INR")
        #expect(repo.inventory.count == 1)
        #expect(repo.inventory.first?.name == "Milk")
        #expect(repo.groceries.count == 2)
    }

    @Test func monthlyReportsSeparateCurrencyRefundsAndYearBoundaries() {
        func entry(_ date: String, _ amount: Int, _ currency: String = "USD", refund: Bool = false) -> ExpenseReportItem {
            ExpenseReportItem(id: UUID(), merchant: "Market", day: date, amount: amount, currency: currency, category: .groceries, isRefund: refund, notes: "")
        }
        let items = [entry("2026-12-31",1000), entry("2027-01-01",1200), entry("2027-01-02",200,refund:true), entry("2027-01-03",9000,"INR")]
        let report = ExpenseRules.summary(items, month: "2027-01", currency: "USD")
        #expect(report.spent == 1200 && report.refunded == 200 && report.net == 1000)
        #expect(report.spending(in: .groceries) == 1200 && report.items.count == 2)
        #expect(ExpenseRules.offset("2027-01", by: -1) == "2026-12")
        #expect(ExpenseRules.offset("2026-12", by: 1) == "2027-01")
        #expect(ExpenseRules.summary(items, month: "2027-01", currency: "INR").spent == 9000)
    }
    @Test func createEditRestoreAndDeleteExpenseKeepsInventoryIndependent() throws {
        let repo = try repo()
        var draft = ExpenseDraft(); draft.merchant = "Costco"; draft.amount = "12.50"; draft.category = .groceries
        draft.date = try #require(ShoppingEntryRules.date(for: "2026-09-01")); draft.notes = "Weekly shop"
        let id = try repo.saveExpense(draft)
        draft.amount = "15.25"; try repo.saveExpense(draft, editing: id)
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(repo.makeBackup())
        let item = try #require(restored.expenses.first)
        #expect(item.id == id && item.amountMinorUnits == 1525 && item.day == "2026-09-01" && item.notes == "Weekly shop")
        #expect(restored.inventory.isEmpty && restored.groceries.isEmpty)
        try restored.deleteExpense(item)
        #expect(restored.expenses.isEmpty)
    }
    @Test func receiptExpenseAndInventoryCommitOnceTogether() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        let text = "MARKET\nCurd 3.99\nTOTAL 3.99"
        let lines = ReceiptRules.scan(text: text).lines
        var expense = ExpenseDraft(); expense.merchant = "Market"; expense.amount = "3.99"; expense.category = .groceries
        expense.date = try #require(ShoppingEntryRules.date(for: "2026-09-01"))
        let key = ExpenseRules.receiptKey(text)
        try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: key)
        #expect(repo.expenses.count == 1 && repo.inventory.count == 1 && repo.groceries.count == 1)
        #expect(repo.inventory.first?.purchasedDay == "2026-09-01")
        #expect(try repo.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: key) == 0)
        #expect(repo.expenses.count == 1 && repo.expenses.first?.amountMinorUnits == 399)
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(repo.makeBackup())
        try restored.importReceipt(lines, householdID: home, storeName: "Market", expense: expense, receiptKey: key)
        #expect(restored.expenses.count == 1 && restored.expenses.first?.receiptKey == key)
        try restored.deleteExpense(try #require(restored.expenses.first))
        #expect(restored.inventory.count == 1 && restored.groceries.count == 1)
    }
    @Test func invalidReceiptTotalSavesNothingAndExpenseOnlyReceiptIsSupported() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        var expense = ExpenseDraft(); expense.merchant = "Electric bill"; expense.amount = "bad"
        let key = ReceiptRules.hash("bill")
        let lines = ReceiptRules.scan(text: "Milk 1.00").lines
        #expect(throws: ExpenseError.self) { try repo.importReceipt(lines, householdID: home, storeName: "", expense: expense, receiptKey: key) }
        #expect(repo.expenses.isEmpty && repo.inventory.isEmpty && repo.groceries.isEmpty)
        expense.amount = "40.00"
        try repo.importReceipt([], householdID: home, storeName: "", expense: expense, receiptKey: key)
        #expect(repo.expenses.count == 1 && repo.inventory.isEmpty && repo.groceries.isEmpty)
    }
    @Test func reportsQuoteCSVAndKeepRefundAmountsNumeric() {
        let item = ExpenseReportItem(id: UUID(), merchant: "=DANGER,\"shop\"", day: "2026-09-01", amount: 1250,
            currency: "USD", category: .other, isRefund: true, notes: "first\nsecond")
        let csv = ExpenseRules.csv(ExpenseRules.summary([item], month: "2026-09", currency: "USD"))
        #expect(csv.contains("\"'=DANGER,\"\"shop\"\"\""))
        #expect(csv.contains(",-12.50,\"USD\","))
        #expect(csv.contains("\"first\nsecond\""))
    }
    @Test func expenseReusesShoppingStoreSpellingWithoutCreatingPayeeStores() throws {
        let repo = try repo()
        try repo.addStore(name: "Anand Stores", branch: "Adyar")
        let saved = try #require(repo.stores.first?.displayName)
        var expense = ExpenseDraft(); expense.merchant = saved.lowercased(); expense.amount = "25.00"
        try repo.saveExpense(expense)
        #expect(repo.expenses.first?.merchant == saved && repo.stores.count == 1)
        expense.merchant = "Monthly rent"
        try repo.saveExpense(expense)
        #expect(repo.expenses.contains { $0.merchant == "Monthly rent" })
        #expect(repo.stores.count == 1)
    }

    @Test func expenseCreationHonorsReadOnlyHouseholds() throws {
        let repo = try repo(); let home = try #require(repo.household?.id)
        try repo.configureSharing(SyncDestination(householdID: home, zoneName: "LHHousehold-\(home)", ownerName: "owner", accountID: "account", isOwner: false))
        repo.syncConfiguration?.readOnly = true
        var expense = ExpenseDraft(); expense.merchant = "Market"; expense.amount = "10"
        #expect(throws: HouseholdSharingError.self) { try repo.saveExpense(expense) }
        #expect(repo.expenses.isEmpty)
    }
}
