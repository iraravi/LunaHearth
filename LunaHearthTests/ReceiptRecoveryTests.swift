import Testing
@testable import LunaHearth

struct ReceiptRecoveryTests {
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
    @Test func multilineFallbackUsesProductNamesAndNetAmounts() {
        let scan = ReceiptRules.scan(text: india)
        #expect(scan.lines.map(\.name) == ["GOLD SPARKLERS #10 - BLACK CAT", "ROUND CINNAMON STICK INDIA BAZAAR 200G"])
        #expect(scan.lines.map(\.amount) == ["5.98", "5.00"])
        #expect(scan.lines.map(\.quantity) == ["2 pieces", "2 pieces"])
    }
    @Test func aiMultilineEvidenceUsesLineTotalNotUnitPrice() throws {
        let proposals = [ReceiptItemEvidence(row: 2, name: "GOLD SPARKLERS #10 - BLACK CAT", printedPrice: "5.98", priceRow: 3), ReceiptItemEvidence(row: 4, name: "ROUND CINNAMON STICK INDIA BAZAAR 200G", printedPrice: "5.98", discountRows: [7], priceRow: 6)]
        let lines = try #require(ReceiptExtractionRules.validate(proposals, text: india))
        #expect(lines.map(\.amount) == ["5.98", "5.00"])
        var bad = proposals; bad[0].printedPrice = "2.99"
        #expect(ReceiptExtractionRules.validate(bad, text: india) == nil)
    }
    @Test func invalidCouponDoesNotDiscardOtherValidatedProducts() throws {
        let text = "COSTCO\n1485984 FAIRLIFECHOC 39.99\n1485984 FAIRLIFECHOC 39.99\n1025795 KS 5DZ EGGS 9.19\nSUBTOTAL 89.17"
        let proposals = [ReceiptItemEvidence(row: 1, name: "FAIRLIFECHOC", printedPrice: "39.99", discountRows: [2]), ReceiptItemEvidence(row: 3, name: "KS 5DZ EGGS", printedPrice: "9.19")]
        #expect(ReceiptExtractionRules.validate(proposals, text: text) == nil)
        let recovered = try #require(ReceiptExtractionRules.recover(proposals, text: text))
        #expect(recovered.map(\.name) == ["KS 5DZ EGGS"])
        #expect(recovered.first?.amount == "9.19")
        #expect(recovered.first?.amountNeedsReview == true)
    }
    @Test func unicodeTaxMarkerAndAccentDoNotLoseVerifiedPrices() {
        let text = "COSTCO\n9140914 DYSON ROBOT 699.99 A\n0000396634 /9140914 140.00-月\nE 1068080 PASTURE ÉGGS 8.69\nSUBTOTAL 568.68"
        let lines = ReceiptRules.scan(text: text).lines
        #expect(lines.map(\.amount) == ["559.99", "8.69"])
    }
    @Test func priceRowCannotBeSharedOrPointToTotal() {
        #expect(ReceiptExtractionRules.validate([ReceiptItemEvidence(row: 0, name: "Milk", printedPrice: "4.00", priceRow: 1)], text: "Milk\nTOTAL 4.00") == nil)
    }
}
