import Foundation

/// Review suggestions only. Missing or conflicting evidence is never replaced with today's date.
enum ReceiptPurchaseDetails {
    /// A catalog or saved store name printed on the receipt. In the header the name must start
    /// its row ("COSTCO WHOLESALE"), so a word inside another store's name ("TOTAL WINE & MORE")
    /// never matches. Elsewhere (e.g. a store-branded card line) only distinctive names of six
    /// or more letters count, so short common words cannot match body text. Ambiguity returns nil.
    static func knownStore(in text: String, saved: [String]) -> String? {
        let rows = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let names = Set(ShoppingStoreCatalog.stores.map(\.name) + saved).filter { !$0.isEmpty && $0.count <= 60 }
        func pattern(_ name: String, leading: Bool = false) -> String {
            let words = name.split(whereSeparator: { $0.isWhitespace }).map { word in
                NSRegularExpression.escapedPattern(for: String(word)).replacingOccurrences(of: "’", with: "['’]?").replacingOccurrences(of: "'", with: "['’]?")
            }
            return (leading ? #"(?i)^[^\p{L}\p{N}]*"# : #"(?i)(?<![\p{L}\p{N}])"#) + words.joined(separator: #"\s*"#) + #"(?![\p{L}\p{N}])"#
        }
        func found(_ rows: some Sequence<String>, leading: Bool = false) -> Set<String> {
            Set(names.filter { name in rows.contains { $0.range(of: pattern(name, leading: leading), options: .regularExpression) != nil } })
        }
        let header = found(rows.prefix(5), leading: true)
        if !header.isEmpty { return header.count == 1 ? header.first : nil }
        let anywhere = found(rows).filter { $0.filter(\.isLetter).count >= 6 }
        return anywhere.count == 1 ? anywhere.first : nil
    }
    /// - Parameter saved: the household's own store names; with the offline catalog they are
    ///   data for recognizing a store, never per-store parsing code.
    static func merchant(_ text: String, saved: [String] = []) -> String? {
        let bounded = String(text.prefix(40_000))
        if let known = knownStore(in: bounded, saved: saved) { return known }
        guard let first = bounded.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?.trimmingCharacters(in: .whitespaces),
              first.count <= 200, first.contains(where: \.isLetter),
              !["wholesale", "receipt", "invoice", "tax invoice"].contains(first.lowercased()),
              !ReceiptRules.isNonProductRow(first) else { return nil }
        return first
    }

    static func day(_ text: String) -> String? {
        let bounded = String(text.prefix(40_000))
        // A US address supplies ordering evidence; an ambiguous date elsewhere needs review.
        let usAddress = bounded.range(of: #"\b(?:AL|AK|AZ|AR|CA|CO|CT|DE|FL|GA|HI|ID|IL|IN|IA|KS|KY|LA|ME|MD|MA|MI|MN|MS|MO|MT|NE|NV|NH|NJ|NM|NY|NC|ND|OH|OK|OR|PA|RI|SC|SD|TN|TX|UT|VT|VA|WA|WV|WI|WY|DC)\s+\d{5}(?:-\d{4})?\b"#, options: .regularExpression) != nil
        guard let regex = try? NSRegularExpression(pattern: #"\b(\d{1,4})[/-](\d{1,2})[/-](\d{2,4})\b"#) else { return nil }
        var days = Set<String>()
        for match in regex.matches(in: bounded, range: NSRange(bounded.startIndex..., in: bounded)) {
            let numbers = (1...3).compactMap { index -> Int? in
                guard let range = Range(match.range(at: index), in: bounded) else { return nil }
                return Int(bounded[range])
            }
            guard numbers.count == 3 else { continue }
            let year: Int; let month: Int; let day: Int
            if numbers[0] >= 2000 { year = numbers[0]; month = numbers[1]; day = numbers[2] }
            else {
                guard numbers[2] >= 2000 else { continue }
                year = numbers[2]
                if usAddress { month = numbers[0]; day = numbers[1] }
                else if numbers[0] > 12 { day = numbers[0]; month = numbers[1] }
                else if numbers[1] > 12 { month = numbers[0]; day = numbers[1] }
                else if numbers[0] == numbers[1] { month = numbers[0]; day = numbers[1] }
                else { return nil }
            }
            let key = String(format: "%04d-%02d-%02d", year, month, day)
            guard let date = ShoppingEntryRules.date(for: key), HouseholdDay(date).key == key else { return nil }
            days.insert(key)
        }
        return days.count == 1 ? days.first : nil
    }
}
