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

    /// Build 98 debug text (sanitized): the same item printed twice, one copy with a decimal
    /// comma and an accented tax letter, and a coupon row with a stray mark after its code.
    @Test func damagedPunctuationKeepsRepeatedItemAndCoupon() throws {
        let text = """
        COSTCO
        -WHOLESALE
        ***START OF PRE-SCANNED ITEMS*********
        1996645 METHOD BODY 4,97 AÍ
        1996645 METHOD BODY 4.97 A
        2034323 HOLIDAY BOWL 8.99 A
        0000401809Ś / 2034323 2.00-A
        E 1169942 GINGER BEER 16.59 A
        E 0000398961 /1169942 5.00-A
        E 776948 STARBK COCOA 14.89
        E 0000400865 / 776948 3.00-
        ***END OF PRE-SCANNED ITEMS***
        TOTAL NUMBER OF PRE-SCANNED ITEMS 5
        SUBTOTAL 40.41
        TAX 2.35
        **** TOTAL 42716
        APPROVED - Purchase
        AMOUNT: $42.76
        Visa 42.76
        CHANGE 0.00
        TAX PLAN A 8.250% 2.35
        TOTAL NUMBER OF ITEMS SOLD = 5
        INSTANT SAVINGS $ 10.00
        """
        let scan = ReceiptRules.scan(text: text, sameLinePrices: true)
        let byName = Dictionary(uniqueKeysWithValues: scan.lines.map { ($0.name, $0) })
        #expect(byName["METHOD BODY"]?.amount == "9.94")
        #expect(byName["METHOD BODY"]?.quantity == "2 pieces")
        #expect(byName["HOLIDAY BOWL"]?.amount == "6.99")
        #expect(byName["GINGER BEER"]?.amount == "11.59")
        #expect(byName["STARBK COCOA"]?.amount == "11.89")
        #expect(scan.lines.count == 4)
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: text) == .verified)
    }
    @Test func punctuationRepairNeverTouchesDigits() {
        #expect(ItemCodeReceiptDetails.repaired("0000401809Ś / 2034323 2.00-A") == "0000401809 / 2034323 2.00-A")
        #expect(ItemCodeReceiptDetails.repaired("1996645 METHOD BODY 4,97 AÍ") == "1996645 METHOD BODY 4.97 A")
        #expect(ItemCodeReceiptDetails.repaired("1996645 TV 1,234.56 A") == "1996645 TV 1,234.56 A")
        #expect(ItemCodeReceiptDetails.repaired("E 776948 STARBK COCOA 14.89") == "E 776948 STARBK COCOA 14.89")
    }
}

struct ReceiptMisreadTests {
    @Test func cleanupRepairsPunctuationOnly() {
        #expect(ReceiptOCRCleanup.row("1996645 METHOD BODY 4.97 А") == "1996645 METHOD BODY 4.97 A")
        #expect(ReceiptOCRCleanup.row("MILK 4. 97") == "MILK 4.97")
        #expect(ReceiptOCRCleanup.row("ХЛЕБ 45,00") == "ХЛЕБ 45.00") // real Cyrillic stays Cyrillic
        #expect(ReceiptOCRCleanup.row("TOTAL 1,234.56") == "TOTAL 1,234.56")
        #expect(ReceiptOCRCleanup.row("Thank You!") == "Thank You!")
    }
    @Test func mathReaderCountsItemCodeCoupons() {
        let text = "COSTCO\n2034323 HOLIDAY BOWL 8.99 A\n0000401809 / 2034323 2.00-A\nE 776948 STARBK COCOA 14.89\nSUBTOTAL 21.88\nTAX 0.00\nTOTAL 21.88"
        let outcome = ReceiptSolver.solve(text: text)
        #expect(outcome.status == .unique)
        #expect(outcome.lines.first { $0.name.contains("HOLIDAY") }?.amount == "6.99")
    }
    @Test func mathReaderTriesDigitLookAlikesOnlyWhenTheyAddUp() {
        let text = "FRESH MART\nBANANAS 1O.99\nMILK 3.49\nSUBTOTAL 14.48\nTOTAL 14.48"
        let outcome = ReceiptSolver.solve(text: text)
        #expect(outcome.status == .unique)
        #expect(outcome.lines.first { $0.name == "BANANAS" }?.amount == "10.99")
        // When the fixed reading still doesn't add up, nothing is proposed.
        #expect(ReceiptSolver.solve(text: "FRESH MART\nBANANAS 1O.99\nMILK 3.49\nSUBTOTAL 20.00\nTOTAL 20.00").status != .unique)
    }
}
