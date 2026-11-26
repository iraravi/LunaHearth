import Testing
@testable import LunaHearth

struct ReceiptGapHintTests {
    private let costco = """
    COSTCO
    1996645 METHOD BODY 4,97 AÍ
    1996645 METHOD BODY 4.97 A
    2034323 HOLIDAY BOWL 8.99 A
    0000401809Ś / 2034323 2.00-A
    E 1169942 GINGER BEER 16.59 A
    E 0000398961 /1169942 5.00-A
    E 776948 STARBK COCOA 14.89
    E 0000400865 / 776948 3.00-
    SUBTOTAL 40.41
    TAX 2.35
    TOTAL 42.76
    """
    /// What build 98 read: one Method Body and no Holiday Bowl coupon ($37.44 against $40.41).
    private var misread: [ReceiptLine] {
        [("METHOD BODY", "4.97"), ("HOLIDAY BOWL", "8.99"), ("GINGER BEER", "11.59"), ("STARBK COCOA", "11.89")]
            .enumerated().map { ReceiptLine(id: "l\($0.offset)", name: $0.element.0, quantity: "1 piece", amount: $0.element.1) }
    }

    @Test func pointsAtTheMissedRowAndCoupon() throws {
        let hints = ReceiptGapHints.hints(lines: misread, text: costco)
        #expect(hints.count == 2)
        #expect(hints.contains { $0.kind == .missedItem(name: "METHOD BODY", amount: 497) })
        #expect(hints.contains { $0.kind == .missedDiscount(amount: 200, lineID: "l1") })
        var lines = misread
        for hint in hints { ReceiptGapHints.apply(hint, to: &lines, idSeed: costco) }
        #expect(lines.first { $0.name == "METHOD BODY" }?.amount == "9.94")
        #expect(lines.first { $0.name == "METHOD BODY" }?.quantity == "2 pieces")
        #expect(lines.first { $0.name == "HOLIDAY BOWL" }?.amount == "6.99")
        #expect(ReceiptReconciliation.check(lines: lines, text: costco) == .verified)
    }
    @Test func noHintWhenNothingExplainsTheGap() {
        let lines = [ReceiptLine(id: "a", name: "MILK", amount: "3.00")]
        #expect(ReceiptGapHints.hints(lines: lines, text: "MARKET\nMILK 3.00\nSUBTOTAL 9.99\nTOTAL 9.99").isEmpty)
    }
    @Test func noHintWhenTwoDifferentRowsWouldFit() {
        let lines = [ReceiptLine(id: "a", name: "MILK", amount: "3.00")]
        let text = "MARKET\nMILK 3.00\nBREAD 2.00\nEGGS 2.00\nSUBTOTAL 5.00\nTOTAL 5.00"
        #expect(ReceiptGapHints.hints(lines: lines, text: text).isEmpty)
    }
    @Test func singleMissedRowIsAddedAsNewItem() throws {
        let lines = [ReceiptLine(id: "a", name: "MILK", amount: "3.00")]
        let text = "MARKET\nMILK 3.00\nBREAD 2.49\nSUBTOTAL 5.49\nTOTAL 5.49"
        let hints = ReceiptGapHints.hints(lines: lines, text: text)
        #expect(hints.map(\.kind) == [.missedItem(name: "BREAD", amount: 249)])
        var fixed = lines
        ReceiptGapHints.apply(try #require(hints.first), to: &fixed, idSeed: text)
        #expect(fixed.count == 2)
        #expect(ReceiptReconciliation.check(lines: fixed, text: text) == .verified)
    }
}
