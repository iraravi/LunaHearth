import Testing
@testable import LunaHearth

struct ReceiptReadingChoiceTests {
    private let good = """
    COSTCO
    1996645 METHOD BODY 4.97 A
    1996645 METHOD BODY 4.97 A
    2034323 HOLIDAY BOWL 8.99 A
    0000401809 / 2034323 2.00-A
    E 1169942 GINGER BEER 16.59 A
    E 0000398961 /1169942 5.00-A
    E 776948 STARBK COCOA 14.89
    E 0000400865 / 776948 3.00-
    SUBTOTAL 40.41
    TAX 2.35
    TOTAL 42.76
    """
    /// A reading that lost the second Method Body row and a coupon: it can't add up.
    private let lossy = """
    COSTCO
    1996645 METHOD BODY 4.97 A
    2034323 HOLIDAY BOWL 8.99 A
    E 1169942 GINGER BEER 16.59 A
    E 0000398961 /1169942 5.00-A
    SUBTOTAL 40.41
    TAX 2.35
    TOTAL 42.76
    """

    @Test func readingThatAddsUpWinsOverPreferredReader() throws {
        let pick = try #require(ReceiptReadingChoice.best([
            ReceiptReading(source: .layout, text: lossy), ReceiptReading(source: .plain, text: good)]))
        #expect(pick.reading.source == .plain)
        #expect(pick.score.verified)
    }

    @Test func preferredReaderWinsWhenBothAddUp() throws {
        let pick = try #require(ReceiptReadingChoice.best([
            ReceiptReading(source: .layout, text: good), ReceiptReading(source: .plain, text: good)]))
        #expect(pick.reading.source == .layout)
    }

    @Test func closestReadingWinsWhenNoneAddsUp() throws {
        let worse = lossy.replacingOccurrences(of: "2034323 HOLIDAY BOWL 8.99 A\n", with: "")
        let pick = try #require(ReceiptReadingChoice.best([
            ReceiptReading(source: .layout, text: worse), ReceiptReading(source: .plain, text: lossy)]))
        #expect(pick.reading.source == .plain)
        #expect(!pick.score.verified)
    }

    @Test func emptyReadingsAreIgnored() {
        #expect(ReceiptReadingChoice.best([ReceiptReading(source: .layout, text: "  \n")]) == nil)
    }

    private func lines(_ items: [(String, String)]) -> [ReceiptLine] {
        items.enumerated().map { ReceiptLine(id: "m\($0.offset)", name: $0.element.0, amount: $0.element.1) }
    }

    @Test func modelReadingBackedByPrintedNumbersIsAccepted() {
        // 9.94 = 2 × 4.97, 6.99 = 8.99 − 2.00, 11.59 = 16.59 − 5.00, 11.89 = 14.89 − 3.00.
        let read = lines([("METHOD BODY", "9.94"), ("HOLIDAY BOWL", "6.99"), ("GINGER BEER", "11.59"), ("STARBK COCOA", "11.89")])
        #expect(ReceiptModelReadingCheck.accepts(read, text: lossy, evidence: [good]))
    }

    @Test func modelReadingThatInventsAPriceIsRejected() {
        // Adds up to 40.41, but 12.77 is not printed nor made from printed numbers.
        let read = lines([("METHOD BODY", "4.97"), ("HOLIDAY BOWL", "8.99"), ("GINGER BEER", "12.77"), ("STARBK COCOA", "13.68")])
        #expect(ReceiptReconciliation.check(lines: read, text: good) == .verified)
        #expect(!ReceiptModelReadingCheck.accepts(read, text: good, evidence: []))
    }

    @Test func modelReadingThatDoesNotAddUpIsRejected() {
        let read = lines([("METHOD BODY", "4.97"), ("HOLIDAY BOWL", "8.99")])
        #expect(!ReceiptModelReadingCheck.accepts(read, text: good, evidence: []))
    }
}

import UIKit

/// Runs the real Vision readers on the demo receipt photo, as the app does after a scan.
struct ReceiptReaderImageTests {
    @Test @MainActor func demoReceiptPhotoReadsAndAddsUp() async throws {
        let data = try #require(DemoReceiptImage.make().pngData())
        let scan = try await ReceiptReader().read(pages: [data])
        #expect(!scan.lines.isEmpty)
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: scan.text) == .verified)
    }
}
