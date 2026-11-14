import Foundation

/// Normalized OCR geometry; independent of Vision for deterministic layout tests.
struct ReceiptTextFragment: Sendable {
    let text: String
    let x: Double
    let y: Double
    let width: Double
    let height: Double
    let slope: Double
}

enum ReceiptTextRows {
    static func assemble(_ fragments: [ReceiptTextFragment]) -> String {
        let slopes = fragments.filter { $0.width > 0.15 && $0.slope.isFinite && abs($0.slope) < 0.3 }
            .map(\.slope).sorted()
        let slope = slopes.isEmpty ? 0 : slopes[slopes.count / 2]
        func baseline(_ fragment: ReceiptTextFragment) -> Double { fragment.y - slope * fragment.x }
        var rows: [[ReceiptTextFragment]] = []
        for fragment in fragments.sorted(by: { baseline($0) > baseline($1) }) {
            if let anchor = rows.last?.first,
               abs(baseline(anchor) - baseline(fragment)) < min(anchor.height, fragment.height) * 0.5 {
                rows[rows.count - 1].append(fragment)
            } else { rows.append([fragment]) }
        }
        return rows.map { $0.sorted { $0.x < $1.x }.map(\.text).joined(separator: " ") }.joined(separator: "\n")
    }
}
