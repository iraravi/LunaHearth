import Foundation

/// Offline name suggestions, not a directory of individual branches.
enum ShoppingStoreCatalog {
    enum Region: String, CaseIterable, Identifiable {
        case all = "All", us = "US", india = "India"
        var id: String { rawValue }
    }
    struct Store: Identifiable {
        let name: String
        let region: Region
        var id: String { name }
    }
    static let stores: [Store] = [
        "Walmart", "Target", "Costco", "Sam’s Club", "Kroger", "ALDI", "Trader Joe’s",
        "Whole Foods Market", "Safeway", "Publix", "H-E-B", "Meijer", "Wegmans",
        "Sprouts Farmers Market", "Food Lion", "Lidl", "Albertsons", "Patel Brothers"
    ].map { Store(name: $0, region: .us) } + [
        "DMart", "DMart Ready", "Reliance SMART", "SMART Bazaar", "Smart Point",
        "JioMart", "BigBasket", "Blinkit", "Zepto", "Spencer’s", "More", "Star Bazaar",
        "Nature’s Basket", "Lulu Hypermarket"
    ].map { Store(name: $0, region: .india) }

    static func key(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .unicodeScalars.filter { CharacterSet.alphanumerics.union(.nonBaseCharacters).contains($0) }.map(String.init).joined()
    }
    private static func clean(_ name: String) -> String {
        name.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }
    static func canonicalName(_ input: String, saved: [String] = []) -> String {
        let name = clean(input), normalized = key(name)
        guard !normalized.isEmpty else { return name }
        let aliases = ["wholefoods": "Whole Foods Market", "reliancesmartbazaar": "SMART Bazaar", "reliancesmartpoint": "Smart Point"]
        if let alias = aliases[normalized] { return alias }
        if let store = stores.first(where: { key($0.name) == normalized }) { return store.name }
        // Deterministic spelling for custom stores; keep branch names distinct.
        return saved.map(clean).filter { key($0) == normalized }.sorted().first ?? name
    }
    static func savedNames(_ saved: [String]) -> [String] {
        Array(Set(saved.map { canonicalName($0, saved: saved) }.filter { !$0.isEmpty })).sorted()
    }
    static func matches(_ name: String, query: String) -> Bool {
        let queryKey = key(query)
        return queryKey.isEmpty || key(name).contains(queryKey) || key(name).contains(key(canonicalName(query)))
    }
    static func suggestions(query: String, region: Region, excluding saved: [String]) -> [Store] {
        let existing = Set(savedNames(saved).map(key))
        return stores.filter { (region == .all || $0.region == region) && !existing.contains(key($0.name)) && matches($0.name, query: query) }
            .sorted { $0.name < $1.name }
    }
}
