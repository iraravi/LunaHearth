import Foundation
import Testing
@testable import LunaHearth

struct ReceiptConflictingTotalsTests {
    private func items(_ amount: String) -> [ReceiptLine] {
        [ReceiptLine(id: "test-product", name: "Product", amount: amount)]
    }

    @Test func conflictingTotalsCannotBypassThroughMatchingSubtotal() {
        let text = "SHOP\nSUBTOTAL 4.00\nTOTAL 4.00\nTOTAL 4.50"
        #expect(ExpenseRules.receiptTotalEvidence(text) == .conflicting)
        #expect(ExpenseRules.receiptTotal(text) == nil)
        #expect(ReceiptReconciliation.check(lines: items("4.00"), text: text) == .unverified(.noPrintedTotals))
    }

    @Test func conflictingSubtotalsCannotBypassThroughMatchingTotal() {
        let text = "SHOP\nSUBTOTAL 4.00\nSUBTOTAL 4.50\nTOTAL 4.00"
        #expect(ReceiptReconciliation.totals(text).hasConflictingAmounts)
        #expect(ReceiptReconciliation.check(lines: items("4.00"), text: text) == .unverified(.noPrintedTotals))
    }

    @Test func conflictingTaxesCannotPassWhenTotalIsUnreadable() {
        let text = "SHOP\nSUBTOTAL 4.00\nTAX 0.20\nTAX 0.40\nTOTAL unreadable"
        #expect(ReceiptReconciliation.totals(text).hasConflictingAmounts)
        #expect(ReceiptReconciliation.check(lines: items("4.00"), text: text) == .unverified(.noPrintedTotals))
    }

    @Test func missingAndUnreadableTotalsRemainDistinctFromContradictions() {
        let missing = "SHOP\nSUBTOTAL 4.00"
        let unreadable = missing + "\nTOTAL unreadable"
        #expect(ExpenseRules.receiptTotalEvidence(missing) == .absent)
        #expect(ExpenseRules.receiptTotalEvidence(unreadable) == .unreadable)
        // A legible subtotal still supports an item proposal when no readable total contradicts it.
        #expect(ReceiptReconciliation.check(lines: items("4.00"), text: missing) == .verified)
        #expect(ReceiptReconciliation.check(lines: items("4.00"), text: unreadable) == .verified)
        let repeated = missing + "\nTOTAL 4.00\nTOTAL 4.00"
        #expect(ExpenseRules.receiptTotalEvidence(repeated) == .value("4.00"))
        #expect(ReceiptReconciliation.check(lines: items("4.00"), text: repeated) == .verified)
    }

    @Test func paymentConflictNeedsIndependentCorroboration() {
        let conflict = "SHOP\nSUBTOTAL 4.00\nTOTAL 4.00\nAMOUNT: $4.50"
        #expect(ExpenseRules.receiptTotalEvidence(conflict) == .conflicting)
        #expect(ReceiptReconciliation.check(lines: items("4.00"), text: conflict) == .unverified(.noPrintedTotals))
        // Preserve the source-backed Costco recovery: payment is printed and subtotal+tax agrees.
        let corroborated = "SUBTOTAL 723.19\nTAX 47.44\nTOTAL 170.63\nAMOUNT: $770.63"
        #expect(ExpenseRules.receiptTotalEvidence(corroborated) == .value("770.63"))
        #expect(ReceiptReconciliation.check(lines: items("723.19"), text: corroborated) == .verified)
    }

    @Test func ratedAndPlainTaxDisagreementCannotBypassUnreadableTotal() {
        let text = "SHOP\nSUBTOTAL 4.00\nTAX 0.20\nTAX 10 on $4.00 $0.40\nTOTAL unreadable"
        #expect(ReceiptReconciliation.totals(text).hasConflictingAmounts)
        #expect(ReceiptReconciliation.check(lines: items("4.00"), text: text) == .unverified(.noPrintedTotals))
        let agreeing = text.replacingOccurrences(of: "TAX 0.20", with: "TAX 0.40")
        #expect(!ReceiptReconciliation.totals(agreeing).hasConflictingAmounts)
        #expect(ReceiptReconciliation.check(lines: items("4.00"), text: agreeing) == .verified)
    }

}
