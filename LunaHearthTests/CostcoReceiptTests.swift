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
        #expect(scan.lines.first?.amount == "10.00")
        #expect(scan.lines.first?.amountNeedsReview == true)
    }
    @Test func mixedBasketReconcilesAllDiscountsAgainstSubtotal() {
        let receipt = """
        COSTCO
        E 1485984 FAIRLIFECHOC 39.99
        E 0000397989 /1485984 8.00-
        E 1485984 FAIRLIFECHOC 39.99
        E 0000397989 /1485984 8.00-
        E 1485984 FAIRLIFECHOC 39.99
        E 0000397989 /1485984 8.00-
        E 1025795 KS 5DZ EGGS 9.19
        9140914 DYSON ROBOT 699.99 A
        0000396634 /9140914 140.00-A
        E 1068080 PASTURE EGGS 8.69
        2007722 VC/WOOL/COAT 15.00 A
        E 3741 4LB ENVY 6.69
        E 0000399157 /3741 2.00-
        E 113523 ORG MUSHROOM 6.49
        E 3741 4LB ENVY 6.69
        E 0000399157 /3741 2.00-
        E 1801 MANDARINS 4.49
        E 0000398415 /1801 1.50-
        E 2043259 MELTAWAYS 15.49
        SUBTOTAL 723.19
        TAX 47.44
        TOTAL 770.63
        1OUNT: 770.63
        AX PLAN A 8.250% 47.44
        """
        let scan = ReceiptRules.scan(text: receipt)
        #expect(scan.lines.count == 9)
        #expect(scan.lines.map(\.amount) == ["95.97", "9.19", "559.99", "8.69", "15.00", "9.38", "6.49", "2.99", "15.49"])
        #expect(scan.lines[5].quantity == "2 pieces")
        #expect(scan.lines.allSatisfy { !$0.amountNeedsReview })
    }

    @Test func taxSuffixedCouponsAndNumericProductNames() {
        let scan = ReceiptRules.scan(text: "COSTCO\n9140914 DYSON ROBOT 699.99 A\n0000396634 /9140914 140.00-A\nE 3741 4LB ENVY 6.69\nE 0000399157 /3741 2.00-\nSUBTOTAL 564.68\nTAX 46.59\nTOTAL 611.27\n1OUNT: $611.27\nAX PLAN A 8.250% 46.59")
        #expect(scan.lines.map(\.name) == ["DYSON ROBOT", "4LB ENVY"])
        #expect(scan.lines.map(\.amount) == ["559.99", "4.69"])
    }
    @Test func taxCannotHideMissingDiscountsOrPartialRows() {
        let scan = ReceiptRules.scan(text: "COSTCO\nE 123456 MILK 39.99\nE 987654 /123456 ?.00-\nSUBTOTAL 31.99\nTAX 10.00\nTOTAL 41.99")
        #expect(scan.lines.first?.amount == "39.99")
        #expect(scan.lines.first?.amountNeedsReview == true)
    }
    @Test func damagedFooterAfterSplitSubtotalNeverBecomesStock() {
        let scan = ReceiptRules.scan(text: "COSTCO\nE 123456 MILK 10.00\nSUBTOTAL\n10.00\n1OUNT: 10.00\nAX PLAN A 8.250% 0.00")
        #expect(scan.lines.map(\.name) == ["MILK"])
        #expect(scan.lines.first?.amount == "10.00")
    }

    @Test(arguments: ["1699厚99A", "【69再99A"])
    func malformedPriceRetainsReadableProductForManualReview(price: String) {
        let scan = ReceiptRules.scan(text: "COSTCO\n9140914 DYSON ROBOT \(price)\nSUBTOTAL 559.99\nTOTAL 606.19")
        #expect(scan.lines.map(\.name) == ["DYSON ROBOT"])
        #expect(scan.lines.first?.amount.isEmpty == true)
        #expect(scan.lines.first?.amountNeedsReview == true)
    }

    /// Store-free: the item-code layout is recognized from its rows, whatever the store name.
    @Test func itemCodeLayoutIsRecognizedWithoutAStoreName() {
        let scan = ReceiptRules.scan(text: "MARKET\n123456 MILK 10.00\n123456 MILK 10.00")
        #expect(scan.lines.first?.quantity == "2 pieces")
        #expect(scan.lines.first?.amount == "20.00")
        let withoutCodes = ReceiptRules.scan(text: "MARKET\nMILK 10.00\nMILK 10.00")
        #expect(withoutCodes.lines.first?.quantity.isEmpty == true)
    }
}
