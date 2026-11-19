import Testing
@testable import LunaHearth

/// The item list is shown only when scanned amounts reproduce the receipt's printed totals.
struct ReceiptItemizationTests {
    private let costco = """
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
    private let india = """
    INDIA BAZAAR
    ***Sale***
    GOLD SPARKLERS #10 - BLACK CAT
    2 Each @ $2.99/Each T $5.98
    ROUND CINNAMON STICK INDIA
    BAZAAR 200G
    2 Each @ $2.99/Each F $5.98
    Discounts: IB ROUND CINNAMON -$0.98
    Temporary price $2.99, You saved $0.30
    SUB TOTAL $10.98
    TEXAS TAX $0.49
    AMOUNT DUE $11.47
    """
    private func line(_ amount: String, review: Bool = false) -> ReceiptLine {
        ReceiptLine(id: ReceiptRules.hash(amount + "\(review)"), name: "Item", amount: amount, amountNeedsReview: review)
    }

    @Test func costcoBasketMatchesSubtotalTaxAndTotal() {
        let scan = ReceiptRules.scan(text: costco, sameLinePrices: true)
        #expect(ReceiptReconciliation.totals(costco) == ReceiptPrintedTotals(subtotal: 72_319, tax: 4_744, total: 77_063, taxLabelSeen: true))
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: costco) == .verified)
    }
    @Test func multilineReceiptWithRegionalTaxLabelIsVerified() {
        let scan = ReceiptRules.scan(text: india, sameLinePrices: true)
        #expect(ReceiptReconciliation.totals(india) == ReceiptPrintedTotals(subtotal: 1_098, tax: 49, total: 1_147, taxLabelSeen: true))
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: india) == .verified)
    }
    @Test func garbledTotalDoesNotBlockAMatchingSubtotal() {
        // OCR lost the decimal in "95.97"; the subtotal still verifies the items.
        let text = "COSTCO\n1485984 FAIRLIFECHOC 39.99\n0000397989 /1485984 8.00-\nE 1485984 FAIRLIFECHOC 39.99\nE 0000397989 /1485984 8.00-\nE 1485984 FAIRLIFECHOC 39.99\nE 0000397989 /1485984 8.00-\nSUBTOTAL 95.97\nTAX 0.00\n**** TOTAL 95197\nAMOUNT: $95.97"
        let scan = ReceiptRules.scan(text: text, sameLinePrices: true)
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: text) == .verified)
    }
    @Test func missingOrWrongItemIsAMismatch() {
        var scan = ReceiptRules.scan(text: costco, sameLinePrices: true)
        scan.lines.removeLast()
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: costco) == .unverified(.mismatch))
        scan = ReceiptRules.scan(text: costco, sameLinePrices: true)
        scan.lines[2].amount = "699.99" // Discount not applied.
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: costco) == .unverified(.mismatch))
    }
    @Test func unitPriceInsteadOfLineTotalIsRejected() {
        let text = "METRO\nOKRA 2.49\nTOMATO 1.99\nSUBTOTAL 4.48\nTOTAL 4.48"
        #expect(ReceiptReconciliation.check(lines: [line("2.49"), line("1.99")], text: text) == .verified)
        #expect(ReceiptReconciliation.check(lines: [line("1.99"), line("1.99")], text: text) == .unverified(.mismatch))
    }
    @Test func blankOrFlaggedAmountsAreNeverShown() {
        let text = "SHOP\nSUBTOTAL 5.00\nTOTAL 5.00"
        #expect(ReceiptReconciliation.check(lines: [line("5.00", review: true)], text: text) == .unverified(.uncertainAmounts))
        #expect(ReceiptReconciliation.check(lines: [line("5.00"), line("")], text: text) == .unverified(.uncertainAmounts))
        #expect(ReceiptReconciliation.check(lines: [], text: text) == .unverified(.noItems))
    }
    @Test func subtotalTaxAndTotalMustAgree() {
        let text = "SHOP\nMILK 4.00\nSUBTOTAL 4.00\nTAX 0.40\nTOTAL 4.80"
        #expect(ReceiptReconciliation.check(lines: [line("4.00")], text: text) == .unverified(.mismatch))
    }
    @Test func receiptsWithoutCheckableTotalsAreUnverified() {
        #expect(ReceiptReconciliation.check(lines: [line("4.00")], text: "SHOP\nMILK 4.00") == .unverified(.noPrintedTotals))
        // A taxed receipt without a subtotal: the items do not reproduce the total.
        let taxed = "SHOP\nMILK 4.00\nTAX 0.33\nTOTAL 4.33"
        #expect(ReceiptReconciliation.check(lines: [line("4.00")], text: taxed) == .unverified(.mismatch))
        // Conflicting subtotals are not guessed between.
        let conflict = "SHOP\nMILK 4.00\nSUBTOTAL 4.00\nSUBTOTAL 4.50"
        #expect(ReceiptReconciliation.check(lines: [line("4.00")], text: conflict) == .unverified(.noPrintedTotals))
    }
    @Test func untaxedReceiptCanVerifyAgainstTotalAlone() {
        let text = "FRESH MARKET\nCurd 3.99\n2 x Bananas 2.49\nTOTAL 6.48"
        let scan = ReceiptRules.scan(text: text, sameLinePrices: true)
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: text) == .verified)
    }
    @Test func sameLinePricesAreKeptAndRepeatedRowsAdd() {
        let text = "MARKET\nMilk ₹60\nCurd Rs. 35.00\nMilk ₹60\nBread 2.00 T\nSUBTOTAL 157.00\nTOTAL INR 157.00"
        let scan = ReceiptRules.scan(text: text, sameLinePrices: true)
        #expect(scan.lines.map(\.name) == ["Milk", "Curd", "Bread"])
        #expect(scan.lines.map(\.amount) == ["120.00", "35.00", "2.00"])
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: text) == .verified)
        // Default scans used by import tests and pantry flows still carry no prices.
        #expect(ReceiptRules.scan(text: text).lines.allSatisfy { $0.amount.isEmpty && !$0.amountNeedsReview })
    }
    @Test func connectedDemoReceiptStaysItemized() {
        let scan = ReceiptRules.scan(text: ConnectedDemo.receipt, sameLinePrices: true)
        #expect(scan.lines.count == 5)
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: ConnectedDemo.receipt) == .verified)
    }
    @Test func couponUnderItsItemIsSubtractedAndVerified() {
        // A negative savings row directly under one item belongs to that item (ReceiptItemDiscounts).
        let text = "SHOP\nMILK 4.00\nCOUPON MILK -1.00\nSUBTOTAL 3.00\nTOTAL 3.00"
        let scan = ReceiptRules.scan(text: text, sameLinePrices: true)
        #expect(scan.lines.map(\.amount) == ["3.00"])
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: text) == .verified)
    }
    @Test func discountWithNoClearItemStaysForReview() {
        // Two discounts stacked under one item: never guess which applies.
        let text = "SHOP\nMILK 4.00\nCOUPON -1.00\nCOUPON -0.50\nSUBTOTAL 2.50\nTOTAL 2.50"
        let scan = ReceiptRules.scan(text: text, sameLinePrices: true)
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: text) != .verified)
    }
    // Regression: TestFlight 2.0.2 (84) Target receipt was hidden as a mismatch.
    private let target = """
    STATIONERY & OFFICE SUPPLIES
    081040691 BEAD KIT T $9.74
    Regular Price $12.99
    25% off Circle
    053316233 Amrch Grings $1.99
    Regular Price $5.99
    TOYS
    081045043 CRAFT KIT T $17.99
    Regular Price $23.99
    25% off Circle
    SUBTOTAL $29.72
    Target Circle Card 5% $0.33 -
    T = TX TAX 8.25000 on $29.39 $2.42
    TOTAL $31.81
    *9906 GIFT CARD PAYMENT $25.58
    *1820 TARGET DEBIT CARD $6.23
    """
    @Test func targetReferencePricesCardDiscountAndRatedTaxVerify() {
        let scan = ReceiptRules.scan(text: target, sameLinePrices: true)
        #expect(scan.lines.map(\.name) == ["BEAD KIT", "Amrch Grings", "CRAFT KIT"])
        #expect(scan.lines.map(\.amount) == ["9.74", "1.99", "17.99"])
        #expect(ReceiptReconciliation.totals(target) == ReceiptPrintedTotals(subtotal: 2_972, tax: 242, total: 3_181, taxLabelSeen: true, discounts: 33))
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: target) == .verified)
    }
    @Test func targetLayoutReaderVariantWithSplitPriceVerifies() {
        // Vision document reader: price on its own row, trailing minus lost on the card discount.
        let text = target
            .replacingOccurrences(of: "053316233 Amrch Grings $1.99", with: "053316233 Amrch Grings T\n$1.99")
            .replacingOccurrences(of: "Target Circle Card 5% $0.33 -", with: "Target Circle Card 5% $0.33")
        let scan = ReceiptRules.scan(text: text, sameLinePrices: true)
        #expect(scan.lines.map(\.name) == ["BEAD KIT", "Amrch Grings", "CRAFT KIT"])
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: text) == .verified)
    }
    @Test func referencePriceAndPromotionRowsAreNotProducts() {
        for row in ["Regular Price $12.99", "Reg Price 4.99", "Original price $3.00", "25% off Circle", "Target Circle Card 5% $0.33 -"] {
            #expect(ReceiptRules.isNonProductRow(row), "\(row)")
        }
        #expect(!ReceiptRules.isNonProductRow("2% MILK 1GAL $3.49"))
        // Without a tax legend a trailing single letter stays part of the name.
        #expect(ReceiptRules.scan(text: "VITAMIN C 4.00\nTOTAL 4.00", sameLinePrices: true).lines.map(\.name) == ["VITAMIN C"])
    }
    @Test func receiptLevelAdjustmentsMustBeMarkedAndTaxMustMatchItsBase() {
        let items = [line("10.00")]
        // An explicitly negative adjustment between subtotal and total is deducted.
        let coupon = "SHOP\nSUBTOTAL 10.00\nSTORE COUPON -1.00\nTAX 0.72\nTOTAL 9.72"
        #expect(ReceiptReconciliation.totals(coupon).discounts == 100)
        #expect(ReceiptReconciliation.check(lines: items, text: coupon) == .verified)
        // A positive charge is never treated as a discount.
        let fee = "SHOP\nSUBTOTAL 10.00\nBAG 0.10\nTOTAL 10.10"
        #expect(ReceiptReconciliation.totals(fee).discounts == 0)
        #expect(ReceiptReconciliation.check(lines: items, text: fee) == .unverified(.mismatch))
        // A rated tax row whose amount disagrees with rate × base is not trusted.
        let wrongTax = "SHOP\nSUBTOTAL 10.00\nTAX 8.25 on $10.00 $0.90\nTOTAL 10.90"
        #expect(ReceiptReconciliation.totals(wrongTax).tax == nil)
        #expect(ReceiptReconciliation.check(lines: items, text: wrongTax) == .unverified(.noPrintedTotals))
    }
    @Test func taxRateRowsAreTrustedOnlyWhenRateTimesSubtotalMatches() {
        // "TAX 8.25% 0.33": 8.25% of 4.00 is 0.33, so the amount is the tax.
        let text = "SHOP\nMILK 4.00\nSUBTOTAL 4.00\nTAX 8.25% 0.33\nTOTAL 4.33"
        #expect(ReceiptReconciliation.totals(text).tax == 33)
        #expect(ReceiptReconciliation.check(lines: [line("4.00")], text: text) == .verified)
        // A rate table printing the taxable base ("TAX 8.25% 4.00") is never read as the tax.
        let base = "SHOP\nMILK 4.00\nSUBTOTAL 4.00\nTAX 8.25% 4.00\nTOTAL 4.33"
        #expect(ReceiptReconciliation.totals(base).tax == nil)
        #expect(ReceiptReconciliation.check(lines: [line("4.00")], text: base) == .unverified(.noPrintedTotals))
    }
}
