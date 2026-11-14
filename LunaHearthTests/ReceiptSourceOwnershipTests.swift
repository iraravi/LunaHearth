import Testing
@testable import LunaHearth

struct ReceiptSourceOwnershipTests {
    @Test func modelCannotRemoveVariantOrInventAName() {
        #expect(ReceiptLabelReview.validated("Chocolate", original: "FAIRLIFECHOC") == nil)
        #expect(ReceiptLabelReview.validated("Milk", original: "KS 5DZ EGGS") == nil)
        #expect(ReceiptLabelReview.validated("ENVY", original: "4LB ENVY") == nil)
        #expect(ReceiptLabelReview.validated("FAIRLIFECHOC", original: "E 1485984 FAIRLIFECHOC") == "FAIRLIFECHOC")
    }
    @Test func reportedBasketReconcilesWithoutGeneratedRowLinks() {
        let text = """
        COSTCO
        E 1485984 FAIRLIFECHOC 39.99
        E 0000397989 /1485984 8.00-
        1485984 FAIRLIFECHOC 39.99
        E 0000397989 /1485984 8.00-
        E 1485984 FAIRLIFECHOC 39.99
        E 0000397989 /1485984 8.00-
        E 1025795 KS 5DZ EGGS 9.19
        ***********BOB Count 4 **************
        9140914 DYSON ROBOT 699.99 A
        0000396634 /9140914 140.00-A
        1068080 PASTURE EGGS 8.69
        2007722 VC WOOL/COAT 15.00 A
        3741 ALB ENVY 6.69
        E 0000399157 / 3741 2.00-
        E 113523 ORG MUSHROOM 6.49
        E 3741 4LB ENVY 6.69
        E 0000399157 / 3741 2.00-
        Y801 MANDARINS 4.49
        E 00003984T5 / 1801 1.50-
        E 2043259 MELTAWAYS 15.49
        SUBTOTAL 723.19
        TAX 47.44
        TOTAL 770.63
        """
        let lines = ReceiptRules.scan(text: text).lines
        #expect(lines.count == 9)
        #expect(lines.map(\.amount) == ["95.97", "9.19", "559.99", "8.69", "15.00", "9.38", "6.49", "2.99", "15.49"])
        #expect(lines[5].name == "4LB ENVY")
        #expect(lines[7].name == "MANDARINS")
        #expect(lines[7].amountNeedsReview)
        #expect(lines.filter(\.amountNeedsReview).count == 1)
    }
    @Test func differentSKUsDoNotMergeAndNonAdjacentDamagedCodeStaysUnresolved() {
        let scan = ReceiptRules.scan(text: "COSTCO\n3741 ALB ENVY 6.69\n3742 4LB ENVY 6.69\nY801 MANDARINS 4.49\n123456 MILK 2.00\n999999 /1801 1.50-")
        #expect(scan.lines.count == 4)
        #expect(scan.lines.first(where: { $0.name == "Y801 MANDARINS" })?.amount.isEmpty == true)
    }
}
