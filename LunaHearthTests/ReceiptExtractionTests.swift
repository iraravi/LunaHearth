import Testing
@testable import LunaHearth

struct ReceiptExtractionTests {
    @Test func sourceBackedStructuredProductsAndCoupons() throws {
        let text = "COSTCO\n123456 FAIRLIFECHOC 39.99\n987654 /123456 8.00-A\nSUBTOTAL 31.99\nTOTAL 34.00"
        let lines = try #require(ReceiptExtractionRules.validate([
            ReceiptItemEvidence(row: 1, name: "FAIRLIFECHOC", printedPrice: "39.99", discountRows: [2])
        ], text: text))
        #expect(lines.count == 1)
        #expect(lines[0].amount == "31.99")
        #expect(!lines[0].amountNeedsReview)
    }
    @Test func fabricatedNamesAmountsAndSourceIndexesFailClosed() {
        let text = "Milk 3.99\nTOTAL 3.99"
        for proposal in [ReceiptItemEvidence(row: 0, name: "Eggs"),
                         ReceiptItemEvidence(row: 0, name: "Milk", printedPrice: "2.99"),
                         ReceiptItemEvidence(row: -1, name: "Milk"),
                         ReceiptItemEvidence(row: 3, name: "Milk"),
                         ReceiptItemEvidence(row: 1, name: "TOTAL", printedPrice: "3.99")] {
            #expect(ReceiptExtractionRules.validate([proposal], text: text) == nil)
        }
    }
    @Test func repeatedPurchasesAggregateButDiscountCannotBeUsedTwice() throws {
        let text = "Milk 3.99\nMilk 3.99\nCoupon -1.00\nSUBTOTAL 6.98"
        var items = [ReceiptItemEvidence(row: 0, name: "Milk", printedPrice: "3.99", discountRows: [2]),
                     ReceiptItemEvidence(row: 1, name: "Milk", printedPrice: "3.99")]
        #expect(try #require(ReceiptExtractionRules.validate(items, text: text)).first?.amount == "6.98")
        items[1].discountRows = [2]
        #expect(ReceiptExtractionRules.validate(items, text: text) == nil)
    }
    @Test func omittedCouponAndUnreadablePriceRequireReview() throws {
        let text = "COSTCO\n123456 Milk 39.99\n987654 /123456 8.00-\nSUBTOTAL 31.99\nTAX 10.00\nTOTAL 41.99"
        let lines = try #require(ReceiptExtractionRules.validate([ReceiptItemEvidence(row: 1, name: "Milk", printedPrice: "39.99")], text: text))
        #expect(lines[0].amountNeedsReview && lines[0].amount == "39.99")
        let unknown = try #require(ReceiptExtractionRules.validate([ReceiptItemEvidence(row: 0, name: "Robot")], text: "Robot ??"))
        #expect(unknown[0].amountNeedsReview)
    }
    @Test func mismatchedSKUCannotTakeAnotherProductsCoupon() {
        let text = "COSTCO\n123456 Milk 9.99\n987654 /111111 2.00-"
        #expect(ReceiptExtractionRules.validate([ReceiptItemEvidence(row: 1, name: "Milk", printedPrice: "9.99", discountRows: [2])], text: text) == nil)
    }
}
