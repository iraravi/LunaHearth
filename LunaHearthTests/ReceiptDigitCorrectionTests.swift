import Foundation
import Testing
@testable import LunaHearth

struct ReceiptDigitCorrectionTests {
    private func receipt(_ items: String, subtotal: String, tax: String, total: String) -> String {
        "FRESH MART\n" + items + "\nSUBTOTAL \(subtotal)\nTAX \(tax)\nTOTAL \(total)\nVISA \(total)"
    }

    @Test func oneMisreadDigitIsFixedWhenTheTotalsProveIt() {
        // BREAD is 2.89; the camera read 2.39. Subtotal + tax = total, so the 0.50 gap is real,
        // and only BREAD can close it by changing one commonly confused digit (3↔8).
        let text = receipt("MILK 3.49\nBREAD 2.39\nEGGS 4.75", subtotal: "11.13", tax: "0.56", total: "11.69")
        let lines = ReceiptRules.scan(text: text, sameLinePrices: true).lines
        let bread = lines.first { $0.name == "BREAD" }
        #expect(bread?.amount == "2.89" && bread?.correctedFrom == "2.39")
        #expect(lines.filter { $0.correctedFrom != nil }.count == 1)
        #expect(ReceiptReconciliation.check(lines: lines, text: text) == .verified)
    }

    @Test func twoPossibleFixesChangeNothing() {
        // A one-cent gap could be BREAD 2.98→2.99 or EGGS 4.25→4.26: no guess is made.
        let text = receipt("MILK 3.49\nBREAD 2.98\nEGGS 4.25", subtotal: "10.73", tax: "0.54", total: "11.27")
        let lines = ReceiptRules.scan(text: text, sameLinePrices: true).lines
        #expect(lines.allSatisfy { $0.correctedFrom == nil })
        #expect(ReceiptReconciliation.check(lines: lines, text: text) == .unverified(.mismatch))
    }

    @Test func totalsThatDisagreeChangeNothing() {
        let text = receipt("MILK 3.49\nBREAD 2.39\nEGGS 4.75", subtotal: "11.23", tax: "0.56", total: "12.79")
        let lines = ReceiptRules.scan(text: text, sameLinePrices: true).lines
        #expect(lines.allSatisfy { $0.correctedFrom == nil })
        #expect(ReceiptReconciliation.check(lines: lines, text: text) != .verified)
    }

    @Test func aGapNoSingleDigitExplainsChangesNothing() {
        // A whole missing item (0.87) is not a misread digit.
        let text = receipt("MILK 3.49\nBREAD 2.99\nEGGS 4.75", subtotal: "12.10", tax: "0.61", total: "12.71")
        let lines = ReceiptRules.scan(text: text, sameLinePrices: true).lines
        #expect(lines.allSatisfy { $0.correctedFrom == nil })
    }

    @Test func aMisreadSubtotalIsOutvotedByTaxAndTotal() {
        // Items 11.23 + tax 0.56 = total 11.79; the subtotal was read as 11.28.
        let text = receipt("MILK 3.49\nBREAD 2.99\nEGGS 4.75", subtotal: "11.28", tax: "0.56", total: "11.79")
        let lines = ReceiptRules.scan(text: text, sameLinePrices: true).lines
        #expect(ReceiptReconciliation.check(lines: lines, text: text) == .verified)
        #expect(lines.allSatisfy { $0.correctedFrom == nil })
    }

    @Test func oneDigitApartMeansExactlyOneDigit() {
        #expect(ReceiptDigitCorrection.oneDigitApart(239, 289))
        #expect(!ReceiptDigitCorrection.oneDigitApart(400, 800), "4↔8 is not a camera misread: likely a missing item")
        #expect(!ReceiptDigitCorrection.oneDigitApart(349, 350))
        #expect(!ReceiptDigitCorrection.oneDigitApart(999, 1099))
        #expect(!ReceiptDigitCorrection.oneDigitApart(500, 500))
    }

    @Test func uncheckedListsReportHowFarOffTheyAre() {
        let text = receipt("MILK 3.49\nBREAD 2.98\nEGGS 4.25", subtotal: "10.73", tax: "0.54", total: "11.27")
        let lines = ReceiptRules.scan(text: text, sameLinePrices: true).lines
        let gap = ReceiptReconciliation.difference(lines: lines, text: text)
        #expect(gap?.items == 1072 && gap?.printed == 1073)
    }
}
