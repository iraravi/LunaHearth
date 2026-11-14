import Testing
@testable import LunaHearth

/// Store-free reading across countries. Fixtures are synthetic layouts, not real receipts:
/// they prove the general rules, not real-device OCR accuracy.
struct ReceiptCountryFormatTests {
    private func scan(_ text: String) -> ReceiptScan { ReceiptRules.scan(text: text, sameLinePrices: true) }

    @Test func indiaGSTInclusiveBillWithQtyRateAmountColumns() {
        let text = """
        SRI LAKSHMI SUPERMARKET
        GSTIN 33ABCDE1234F1Z5
        Item Qty Rate Amount
        Toor Dal 1kg 1 165.00 165.00
        Tomato 1.000 40.00 40.00
        Milk 500ml 2 30.00 60.00
        Total Qty: 4.000
        Net Amount 265.00
        CGST 2.5% 3.15
        SGST 2.5% 3.15
        UPI 265.00
        """
        let result = scan(text)
        #expect(result.lines.map(\.name) == ["Toor Dal 1kg", "Tomato", "Milk 500ml"])
        #expect(result.lines.map(\.amount) == ["165.00", "40.00", "60.00"])
        #expect(result.lines.map(\.quantity) == ["1 piece", "", "2 pieces"])
        // Prices include GST, so the items add up to the amount charged.
        #expect(ReceiptReconciliation.check(lines: result.lines, text: text) == .verified)
        #expect(ReceiptPurchaseDetails.merchant(text) == "SRI LAKSHMI SUPERMARKET")
    }

    @Test func germanVATInclusiveReceiptWithDecimalCommas() {
        let text = """
        BÄCKEREI MÜLLER
        Vollkornbrot 3,49 A
        Brötchen 2 x 1,29 2,58 A
        Milch 1,19 B
        SUMME EUR 7,26
        Bar 10,00
        Rückgeld 2,74
        MwSt 7% Netto Brutto
        """
        let result = scan(text)
        #expect(result.lines.map(\.name) == ["Vollkornbrot", "Brötchen", "Milch"])
        #expect(result.lines.map(\.amount) == ["3.49", "2.58", "1.19"])
        #expect(result.lines[1].quantity == "2 pieces")
        #expect(ExpenseRules.receiptTotal(text) == "7.26")
        #expect(ExpenseRules.receiptCurrency(text) == "EUR")
        #expect(ReceiptReconciliation.check(lines: result.lines, text: text) == .verified)
    }

    @Test func ukVATIncludedReceipt() {
        let text = """
        CORNER SHOP LTD
        Semi Skimmed Milk £1.45
        Bananas 5pk £0.95
        Bread £1.10
        BALANCE DUE £3.50
        VISA £3.50
        VAT 20% included £0.58
        """
        let result = scan(text)
        #expect(result.lines.map(\.name) == ["Semi Skimmed Milk", "Bananas 5pk", "Bread"])
        #expect(ReceiptReconciliation.check(lines: result.lines, text: text) == .verified)
        #expect(ExpenseRules.receiptCurrency(text) == "GBP")
    }

    @Test func usTaxExclusiveReceiptWithAtPriceColumns() {
        let text = """
        GREEN GROCER
        APPLES 2 @ 3.99 7.98
        OKRA 1.25 lb 1.99 2.49
        BREAD 2.50
        SUBTOTAL 12.97
        TAX 0.84
        TOTAL 13.81
        """
        let result = scan(text)
        #expect(result.lines.map(\.name) == ["APPLES", "OKRA", "BREAD"])
        #expect(result.lines.map(\.quantity) == ["2 pieces", "1.25 lb", ""])
        // The unit price 1.99/lb is never the amount charged.
        #expect(result.lines.map(\.amount) == ["7.98", "2.49", "2.50"])
        #expect(ReceiptReconciliation.check(lines: result.lines, text: text) == .verified)
    }

    @Test func columnsThatDoNotMultiplyKeepTheirTextAndTheLineAmount() {
        // 3 × 1.99 ≠ 4.50: the numbers stay in the name for the user to review.
        #expect(ReceiptColumns.split(name: "TEA 3 1.99", lineAmount: "4.50") == nil)
        #expect(ReceiptColumns.split(name: "TEA 3 1.50", lineAmount: "4.50") == .init(name: "TEA", quantity: "3 pieces"))
    }

    @Test func missingItemOnTaxInclusiveBillStaysHidden() {
        let text = "SHOP\nRice 120.00\nDal 80.00\nGrand Total 260.00\nCGST 2.5% 6.19"
        #expect(ReceiptReconciliation.check(lines: scan(text).lines, text: text) == .unverified(.mismatch))
    }

    @Test func multilingualTotalsAndTaxLabels() {
        #expect(ExpenseRules.receiptTotal("BOULANGERIE\nPain 2,10\nTOTAL TTC 2,10 €") == "2.10")
        #expect(ExpenseRules.receiptTotal("TIENDA\nPan 1,50\nTOTAL A PAGAR 1,50") == "1.50")
        #expect(ExpenseRules.receiptTotal("WINKEL\nBrood 2,25\nTE BETALEN 2,25") == "2.25")
        let printed = ReceiptReconciliation.totals("Zwischensumme 10,00\nMwSt 1,90\nGesamtbetrag 11,90")
        #expect(printed.subtotal == 1_000 && printed.tax == 190 && printed.total == 1_190)
    }

    @Test func storeNamesComeFromCatalogDataNotCode() {
        #expect(ReceiptPurchaseDetails.knownStore(in: "DMART\nAvenue Supermarts\nRice 120.00", saved: []) == "DMart")
        #expect(ReceiptPurchaseDetails.knownStore(in: "WHOLESALE\nCelina TX\nCostco Visa 770.63", saved: []) == "Costco")
        #expect(ReceiptPurchaseDetails.knownStore(in: "KUMAR STORES\nRice 1\nDal 2\nOil 3\nSalt 4\nTea 5\nCome again for more", saved: []) == nil)
        #expect(ReceiptPurchaseDetails.knownStore(in: "KUMAR STORES\nRice 120.00", saved: ["Kumar Stores"]) == "Kumar Stores")
    }

    @Test func currencyDetectionUsesPrintedCodesAndUnambiguousSymbols() {
        #expect(ExpenseRules.receiptCurrency("TOTAL ₹297.00") == "INR")
        #expect(ExpenseRules.receiptCurrency("TOTAL SGD 12.50") == "SGD")
        #expect(ExpenseRules.receiptCurrency("TOTAL $12.50") == nil) // "$" alone could be any dollar.
        #expect(ExpenseRules.currencies.contains("AED"))
    }
}
