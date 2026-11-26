import Foundation

/// One clean-up step for camera misreads, run before every receipt reader (line reader, item
/// codes, discounts, math reader). It only repairs punctuation and look-alike characters that
/// cannot change what a row says: digits are never added, removed or reordered, and the
/// printed totals still decide whether any item list is trusted.
///
/// Repairs, each seen on real receipts (see `LunaHearthTests/ReceiptCorpus`):
/// - a decimal comma in a row's closing price: "METHOD BODY 4,97 A" → "4.97 A"
/// - an accent or stray mark on the tax letter after a price: "4.97 AÍ" → "4.97 A"
/// - a stray mark glued to a coupon's own code: "0000401809Ś / 2034323" → "0000401809 / 2034323"
/// - a space inside a price: "4. 97" → "4.97"
/// - Cyrillic or Greek look-alike capitals inside a Latin row: "4.97 А" → "4.97 A"
enum ReceiptOCRCleanup {
    static func clean(_ text: String) -> String {
        text.components(separatedBy: "\n").map(row).joined(separator: "\n")
    }

    static func row(_ raw: String) -> String {
        var row = raw
        row = latinLookAlikes(row)
        row = row.replacingOccurrences(of: #"^(\s*(?:[EA]\s+)?[0-9A-Z]{4,})[^\s/0-9A-Za-z]{1,2}(?=\s*/)"#, with: "$1", options: .regularExpression)
        row = row.replacingOccurrences(of: #"(?<![\d.,])(\d{1,6})\.\s(\d{2})(?=\s*[-−]?\s*[A-Za-z]?\s*$)"#, with: "$1.$2", options: .regularExpression)
        row = row.replacingOccurrences(of: #"(?<![\d.,])(\d{1,6}),(\d{2})(?=\s*[-−]?\s*[A-Za-z]?[^\s\d]?\s*$)"#, with: "$1.$2", options: .regularExpression)
        row = row.replacingOccurrences(of: #"(\d[.,]\d{2}[-−]?)\s*([A-Za-z])[^\s\dA-Za-z$€£₹*%()]\s*$"#, with: "$1 $2", options: .regularExpression)
        return row
    }

    /// Capitals that look identical in Latin, Cyrillic and Greek. Only replaced in rows that are
    /// otherwise Latin, so real Cyrillic or Greek text is left alone.
    private static let lookAlikes: [Character: Character] = [
        "А": "A", "В": "B", "Е": "E", "К": "K", "М": "M", "Н": "H", "О": "O", "Р": "P", "С": "C", "Т": "T", "Х": "X",
        "Α": "A", "Β": "B", "Ε": "E", "Κ": "K", "Μ": "M", "Ν": "N", "Ο": "O", "Ρ": "P", "Τ": "T", "Χ": "X",
    ]
    private static func latinLookAlikes(_ row: String) -> String {
        guard row.contains(where: { lookAlikes[$0] != nil }) else { return row }
        let otherNonLatin = row.contains { character in
            character.isLetter && lookAlikes[character] == nil && !character.isASCII
                && character.unicodeScalars.contains { (0x0370...0x04FF).contains($0.value) }
        }
        guard !otherNonLatin, row.contains(where: { $0.isASCII && $0.isLetter }) else { return row }
        return String(row.map { lookAlikes[$0] ?? $0 })
    }

    /// A second, stronger reading for the math reader only: letters that a camera commonly
    /// reads in place of digits inside a price ("1O.99", "4.9S", "l2.49"). Used only when it
    /// makes the receipt add up exactly, in one way, to its printed totals.
    static func digitLookAlikes(_ text: String) -> String {
        let pattern = #"(?<![\p{L}\d])([0-9OoSlIB]{1,6}[.,][0-9OoSlIB]{2})(?![\p{L}\d])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        var result = text
        for match in regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            guard let range = Range(match.range(at: 1), in: result) else { continue }
            let token = result[range]
            guard token.contains(where: \.isNumber), token.contains(where: \.isLetter) else { continue }
            let map: [Character: Character] = ["O": "0", "o": "0", "S": "5", "l": "1", "I": "1", "B": "8"]
            result.replaceSubrange(range, with: String(token.map { map[$0] ?? $0 }))
        }
        return result
    }
}
