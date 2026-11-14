import Testing
@testable import LunaHearth

/// Image-model proposals are untrusted; only the OCR-based totals check can verify them.
struct ReceiptImageProposalTests {
    private let text = "SHOP\nMILK 4.00\nBREAD 2.50\nSUBTOTAL 6.50\nTOTAL 6.50"

    @Test func validProposalsVerifyAgainstOCRTotals() {
        let lines = ReceiptImageProposalRules.lines([.init(name: "MILK", lineTotal: "4.00"), .init(name: "BREAD", lineTotal: "$2.50")], text: text)
        #expect(lines.map(\.amount) == ["4.00", "2.50"])
        #expect(ReceiptReconciliation.check(lines: lines, text: text) == .verified)
    }
    @Test func inventedOrMissingItemsStayHidden() {
        let invented = ReceiptImageProposalRules.lines([.init(name: "MILK", lineTotal: "4.00"), .init(name: "EGGS", lineTotal: "3.00")], text: text)
        #expect(ReceiptReconciliation.check(lines: invented, text: text) == .unverified(.mismatch))
        let unreadable = ReceiptImageProposalRules.lines([.init(name: "MILK", lineTotal: "4.00"), .init(name: "BREAD", lineTotal: "about two")], text: text)
        #expect(unreadable.last?.amountNeedsReview == true)
        #expect(ReceiptReconciliation.check(lines: unreadable, text: text) == .unverified(.uncertainAmounts))
    }
    @Test func blankAndNonTextNamesAreDropped() {
        let lines = ReceiptImageProposalRules.lines([.init(name: " ", lineTotal: "1.00"), .init(name: "42", lineTotal: "1.00"), .init(name: "MILK", lineTotal: "4.00")], text: text)
        #expect(lines.map(\.name) == ["MILK"])
    }
    @Test func printedEvidenceMatchesWholeAmountsOnly() {
        #expect(ReceiptImageProposalRules.isPrinted("4.00", in: text))
        #expect(!ReceiptImageProposalRules.isPrinted("0.50", in: text)) // Inside 6.50 / 2.50.
        #expect(!ReceiptImageProposalRules.isPrinted("", in: text))
    }
}
