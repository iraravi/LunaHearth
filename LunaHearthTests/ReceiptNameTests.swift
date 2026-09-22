import Foundation
import Testing
@testable import LunaHearth

struct ReceiptNameTests {
    @Test func validatesGeneratedNamesAndIndexes() {
        let inputs = [ReceiptNameInput(id: "a", name: "ORG BANANA")]
        let proposal = ReceiptNameRules.proposal(index: 0, name: " Organic bananas ", inputs: inputs)
        #expect(proposal?.id == "a")
        #expect(proposal?.original == "ORG BANANA")
        #expect(proposal?.name == "Organic bananas")
        #expect(ReceiptNameRules.proposal(index: -1, name: "Bananas", inputs: inputs) == nil)
        #expect(ReceiptNameRules.proposal(index: 4, name: "Bananas", inputs: inputs) == nil)
        for invalid in ["", "123", "ORG BANANA", "Bananas\nOther item", "https://example.com", String(repeating: "a", count: 101)] {
            #expect(ReceiptNameRules.proposal(index: 0, name: invalid, inputs: inputs) == nil)
        }
        #expect(ReceiptNameRules.proposal(index: 0, name: "Bananas", inputs: [ReceiptNameInput(id: "b", name: "123456")]) == nil)
    }

    @Test func proposalsNeverOverwriteAnEditedOrDifferentLine() {
        let proposal = ReceiptNameProposal(id: "a", original: "GRK YOG", name: "Greek yogurt")
        var line = ReceiptLine(id: "a", name: "GRK YOG", quantity: "2 tubs")
        #expect(ReceiptNameRules.canApply(proposal, to: line))
        #expect(line.name == "GRK YOG") // A suggestion is not a mutation.
        line.name = "My yogurt"
        #expect(!ReceiptNameRules.canApply(proposal, to: line))
        line.name = "GRK YOG"; line.included = false
        #expect(!ReceiptNameRules.canApply(proposal, to: line))
        #expect(!ReceiptNameRules.canApply(proposal, to: ReceiptLine(id: "other", name: "GRK YOG")))
        #expect(line.quantity == "2 tubs")
    }
}
