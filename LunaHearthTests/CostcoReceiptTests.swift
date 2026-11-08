import Testing
@testable import LunaHearth

struct CostcoReceiptTests {
    // Sanitized reproduction of Vision output; no membership, payment or location details.
    private let receipt = """
    COSTCO WHOLESALE
    1485984 FAIRLIFECHOC 39.99
    0000397989 /1485984 8.00-
    E 1485984 FAIRLIFECHOC 39.99
    E 0000397989 /1485984 8.00-
    E 1485984 FAIRLIFECHOC 39.99
    E 0000397989 /1485984 8.00-
    TOTAL NUMBER OF ITEMS SOLD =
    3
    SUBTOTAL 95.97
    TAX 0.00
    **** TOTAL 95197
    APPROVED - Purchase
    AMOUNT: $95.97
    Costco Visa 95.97
    CHANGE 0.00
    INSTANT SAVINGS $24.00
    """

    @Test func repeatedSKUDiscountsAndPaymentFooter() throws {
        let scan = ReceiptRules.scan(text: receipt)
        #expect(scan.lines.count == 1)
        let line = try #require(scan.lines.first)
        #expect(line.name == "FAIRLIFECHOC")
        #expect(line.quantity == "3 pieces")
        #expect(line.amount == "95.97")
        #expect(ExpenseRules.receiptTotal(receipt) == "95.97")
        #expect(scan.lines.map(\.id) == ReceiptRules.scan(text: receipt).lines.map(\.id))
    }
    @Test func decoratedTotalAndAmountFallbackRemainConservative() {
        #expect(ExpenseRules.receiptTotal("**** TOTAL 95.97\nAMOUNT: $95.97") == "95.97")
        #expect(ExpenseRules.receiptTotal("**** TOTAL\n95.97") == "95.97")
        #expect(ExpenseRules.receiptTotal("AMOUNT: $95.97") == "95.97")
        #expect(ExpenseRules.receiptTotal("AMOUNT: $95.97\nAMOUNT: $39.99") == nil)
        #expect(ExpenseRules.receiptTotal("**** TOTAL 95197\nVISA $95.97") == nil)
        #expect(ReceiptRules.scan(text: "AMOUNT: $95.97\nAPPROVED 95.97").lines.isEmpty)
    }
    @Test func discountOnlyRowsNeverBecomeProducts() {
        #expect(ReceiptRules.scan(text: "COSTCO\nE 0000397989 /1485984 8.00-\nINSTANT SAVINGS $8.00").lines.isEmpty)
        let scan = ReceiptRules.scan(text: "COSTCO\nE 123456 MILK 10.00\nE 987654 /111111 2.00-")
        #expect(scan.lines.first?.amount == "10.00") // An unrelated coupon cannot discount milk.
    }
    @Test func differentSKUsWithSameNameAndOverDiscountNeedManualReview() {
        let ambiguous = ReceiptRules.scan(text: "COSTCO\nE 123456 MILK 10.00\nE 234567 MILK 12.00")
        #expect(ambiguous.lines.first?.amount.isEmpty == true)
        #expect(ambiguous.lines.first?.quantity.isEmpty == true)
        let invalid = ReceiptRules.scan(text: "COSTCO\nE 123456 MILK 10.00\nE 987654 /123456 12.00-")
        #expect(invalid.lines.first?.amount.isEmpty == true)
    }
    @Test func unreadableCouponDoesNotOverAllocateExpense() {
        let scan = ReceiptRules.scan(text: "COSTCO\nE 123456 MILK 10.00\nE 987654 /123456 ?.00-\nTOTAL $8.00")
        #expect(scan.lines.first?.quantity == "1 piece")
        #expect(scan.lines.first?.amount.isEmpty == true)
    }
    @Test func genericReceiptsKeepUnknownQuantities() {
        let scan = ReceiptRules.scan(text: "MARKET\n123456 MILK 10.00\n123456 MILK 10.00")
        #expect(scan.lines.first?.quantity.isEmpty == true)
        #expect(scan.lines.first?.amount.isEmpty == true)
    }
}
