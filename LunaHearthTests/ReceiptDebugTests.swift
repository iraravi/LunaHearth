import Testing
@testable import LunaHearth

struct ReceiptDebugTests {
    @Test func validationExplainsMultilinePriceMismatch() {
        let result = ReceiptExtractionRules.evaluate([
            ReceiptItemEvidence(row: 0, name: "ROUND CINNAMON", printedPrice: "5.98")
        ], text: "ROUND CINNAMON\n2 Each @ $2.99/Each F $5.98")
        guard case .failure(let failure) = result else { Issue.record("Expected a row-evidence failure"); return }
        #expect(failure.reason.contains("row 0"))
        #expect(failure.reason.contains("price"))
    }
    #if RECEIPT_DEBUG
    @Test func reportSeparatesHiddenCandidatesFromMainScreenAndExplainsConflicts() {
        let text = "SHOP\nMilk 4.00\nSUBTOTAL 4.00\nTOTAL 4.00\nTOTAL 4.50"
        let scan = ReceiptRules.scan(text: text, sameLinePrices: true)
        let report = ReceiptDebugReport.make(scan)
        #expect(report.contains("Total evidence: conflicting"))
        #expect(report.contains("Conflicting printed amounts: yes"))
        #expect(report.contains("Visible scanned items: 0"))
        #expect(report.contains("Expense-only fallback"))
        #expect(report.contains("RAW ITEM CANDIDATES (1)"))
        #expect(report.contains("Milk | amount=4.00"))
        #expect(report.contains("This debug screen saves no expense, products or receipt image."))
    }

    @Test func debugPreviewMatchesAcceptedMainScreenItemsAndMissingTotals() {
        let scan = ReceiptRules.scan(text: "SHOP\nMilk 4.00\nSUBTOTAL 4.00\nTOTAL 4.00", sameLinePrices: true)
        #expect(ReceiptDebugReport.make(scan).contains("Visible scanned items: 1"))
        #expect(ReceiptDebugReport.totalEvidenceSummary(scan.text) == "readable proposal: 4.00")
        #expect(ReceiptDebugReport.totalEvidenceSummary("SHOP") == "absent — enter total manually")
        #expect(ReceiptDebugReport.totalEvidenceSummary("TOTAL unclear") == "unreadable — compare with receipt")
        var unknown = scan
        unknown.lines[0].amountNeedsReview = true
        #expect(ReceiptDebugReport.make(unknown).contains("Visible scanned items: 0"))
    }

    @Test func reportShowsBothRejectedAIAndFallbackWithoutSavingRecords() {
        var scan = ReceiptScan(text: "TEST MARKET\nMilk 4.00\nTOTAL 4.00", lines: [ReceiptLine(id: "test", name: "Milk")], extractionMessage: "Standard scan used")
        scan.debugOutput = "STRUCTURED AI OUTPUT\nrow=99\nVALIDATION: rejected"
        let report = ReceiptDebugReport.make(scan)
        #expect(report.contains("[1] Milk 4.00"))
        #expect(report.contains("row=99"))
        #expect(report.contains("VALIDATION: rejected"))
        #expect(report.contains("amount=unknown"))
        #expect(report.contains("Date: needs review"))
        #expect(report.contains("Total: 4.00"))
    }
    #endif
}
