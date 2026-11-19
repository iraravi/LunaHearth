import Foundation

/// Learns from the store names and item names a person confirms when saving a receipt,
/// so the next receipt from the same store reads right. Stored on this phone only;
/// never sent anywhere and never changes saved household records.
enum ReceiptCorrectionMemory {
    static let storageKey = "receipt.corrections.v1"
    static let maximumStores = 300
    static let maximumItems = 1_000

    struct State: Codable, Equatable {
        /// Store fingerprint ("tel:9723120114", "web:indiabazaardfw", "addr:14339 eldorado pkwy") → store name.
        var stores: [String: String] = [:]
        /// Normalised printed label → the name the person chose.
        var items: [String: String] = [:]
    }

    static func decode(_ stored: String) -> State {
        (try? JSONDecoder().decode(State.self, from: Data(stored.utf8))) ?? State()
    }
    static func encode(_ state: State) -> String {
        guard let data = try? JSONEncoder().encode(state) else { return "" }
        return String(decoding: data, as: UTF8.self)
    }

    // MARK: Store fingerprints

    /// Details that stay the same on every receipt from one store: its phone, website and street address.
    static func storeKeys(_ text: String) -> [String] {
        let rows = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        let header = rows.prefix(14)
        var keys: [String] = []
        // Phone numbers in the header (10–12 digits, with or without separators). Card masks never qualify.
        if let phone = try? NSRegularExpression(pattern: #"(?<![\d*])(?:\+?\d{1,3}[\s.-]?)?\(?\d{3,5}\)?[\s.-]?\d{3,4}[\s.-]?\d{3,4}(?![\d*])"#) {
            for row in header where !row.contains("*") {
                for match in phone.matches(in: row, range: NSRange(row.startIndex..., in: row)) {
                    guard let range = Range(match.range, in: row) else { continue }
                    let digits = row[range].filter(\.isNumber)
                    if (10...12).contains(digits.count) { keys.append("tel:" + String(digits.suffix(10))) }
                }
            }
        }
        // Website printed anywhere on the receipt.
        if let web = try? NSRegularExpression(pattern: #"(?i)(?:www\.|https?://)([a-z0-9-]{4,})\.[a-z]{2,4}"#) {
            for match in web.matches(in: text, range: NSRange(text.startIndex..., in: text)) {
                if let range = Range(match.range(at: 1), in: text) {
                    let label = text[range].lowercased().filter(\.isLetter)
                    if label.count >= 4 { keys.append("web:" + label) }
                }
            }
        }
        // Street address: a header row starting with a building number and a street word.
        for row in header where row.range(of: #"^\d{1,6}\s+[A-Za-z]"#, options: .regularExpression) != nil
            && row.range(of: #"\d[.,]\d{2}\b"#, options: .regularExpression) == nil {
            let address = IngredientMatching.normalized(row)
            if address.count >= 8 { keys.append("addr:" + address) }
        }
        var seen = Set<String>()
        return keys.filter { seen.insert($0).inserted }
    }

    static func rememberedStore(_ text: String, state: State) -> String? {
        for key in storeKeys(text) { if let name = state.stores[key] { return name } }
        return nil
    }

    // MARK: Item names

    static func itemKey(_ printed: String) -> String { IngredientMatching.normalized(printed) }

    static func rememberedName(_ printed: String, state: State) -> String? {
        let key = itemKey(printed)
        guard !key.isEmpty, let name = state.items[key], name.caseInsensitiveCompare(printed) != .orderedSame else { return nil }
        return name
    }

    // MARK: Learning

    /// Called when a receipt is saved. Remembers the saved store for this receipt's fingerprints,
    /// and every item the person renamed from its printed label.
    static func learn(text: String, savedStore: String, renamed: [(printed: String, saved: String)], state: State) -> State {
        var next = state
        let store = savedStore.trimmingCharacters(in: .whitespacesAndNewlines)
        if (2...80).contains(store.count), store.contains(where: \.isLetter) {
            for key in storeKeys(text) { next.stores[key] = store }
        }
        for (printed, saved) in renamed {
            let name = saved.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = itemKey(printed)
            guard !key.isEmpty, (2...100).contains(name.count), name.contains(where: \.isLetter),
                  name.caseInsensitiveCompare(printed.trimmingCharacters(in: .whitespacesAndNewlines)) != .orderedSame else { continue }
            next.items[key] = name
        }
        if next.stores.count > maximumStores { next.stores = Dictionary(uniqueKeysWithValues: next.stores.sorted { $0.key < $1.key }.suffix(maximumStores).map { ($0.key, $0.value) }) }
        if next.items.count > maximumItems { next.items = Dictionary(uniqueKeysWithValues: next.items.sorted { $0.key < $1.key }.suffix(maximumItems).map { ($0.key, $0.value) }) }
        return next
    }
}
