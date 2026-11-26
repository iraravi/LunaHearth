import Foundation
import Testing
@testable import LunaHearth

/// Every real receipt that ever misread lives in `ReceiptCorpus/` (personal details removed) and
/// runs through the same reader the app uses. A fix for a new receipt must keep all old ones
/// passing. How to add one: `ReceiptCorpus/README.md`.
struct ReceiptCorpusTests {
    struct Sample: CustomTestStringConvertible, Sendable {
        var name: String
        var verified: Bool
        var items: [(name: String, amount: String)]
        var text: String
        var testDescription: String { name }
    }

    static let samples: [Sample] = {
        final class Token {}
        let bundle = Bundle(for: Token.self)
        let urls = (bundle.urls(forResourcesWithExtension: "txt", subdirectory: nil) ?? [])
            + (bundle.urls(forResourcesWithExtension: "txt", subdirectory: "ReceiptCorpus") ?? [])
        return urls.compactMap { url -> Sample? in
            guard let raw = try? String(contentsOf: url, encoding: .utf8), raw.hasPrefix("#!") else { return nil }
            let rows = raw.components(separatedBy: "\n")
            let header = rows.prefix { $0.hasPrefix("#!") }.map { $0.dropFirst(2).trimmingCharacters(in: .whitespaces) }
            let items = header.compactMap { row -> (String, String)? in
                guard row.hasPrefix("item ") else { return nil }
                let parts = row.dropFirst(5).components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
                return parts.count == 2 ? (parts[0], parts[1]) : nil
            }
            return Sample(name: url.deletingPathExtension().lastPathComponent, verified: header.contains("verified"),
                          items: items, text: rows.dropFirst(header.count).joined(separator: "\n"))
        }.sorted { $0.name < $1.name }
    }()

    @Test func corpusIsBundled() {
        #expect(Self.samples.count >= 3)
    }

    @Test(arguments: samples) func receiptReadsAsExpected(_ sample: Sample) {
        let scan = ReceiptRules.scan(text: sample.text, sameLinePrices: true)
        let found = scan.lines.map { "\($0.name) | \($0.amount)" }.joined(separator: "\n")
        if sample.verified {
            #expect(ReceiptReconciliation.check(lines: scan.lines, text: scan.text) == .verified, "\(sample.name) should add up:\n\(found)")
        }
        #expect(scan.lines.count == sample.items.count, "\(sample.name) item count:\n\(found)")
        for item in sample.items {
            let match = scan.lines.first { $0.name.localizedCaseInsensitiveContains(item.name) }
            #expect(match?.amount == item.amount, "\(sample.name): \(item.name) should be \(item.amount):\n\(found)")
        }
    }
}
