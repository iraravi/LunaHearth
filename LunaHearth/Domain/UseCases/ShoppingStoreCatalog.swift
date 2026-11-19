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
        /// How the chain's name is printed on receipts, when that differs from `name`.
        /// Data for recognizing a store only; never per-store parsing rules.
        var printedAs: [String] = []
        var id: String { name }
    }
    private static func us(_ name: String, _ printed: String...) -> Store { Store(name: name, region: .us, printedAs: printed) }
    private static func india(_ name: String, _ printed: String...) -> Store { Store(name: name, region: .india, printedAs: printed) }

    static let stores: [Store] = [
        // Grocery and warehouse
        us("Walmart", "Walmart Supercenter", "Wal-Mart"), us("Target"), us("Costco", "Costco Wholesale"),
        us("Sam’s Club"), us("Kroger"), us("ALDI"), us("Trader Joe’s"), us("Whole Foods Market"),
        us("Safeway"), us("Publix", "Publix Super Markets"), us("H-E-B"), us("Meijer"), us("Wegmans"),
        us("Sprouts Farmers Market"), us("Food Lion"), us("Lidl"), us("Albertsons"), us("Tom Thumb"),
        us("Ralphs"), us("Fred Meyer"), us("Giant Food"), us("Stop & Shop"), us("Winn-Dixie"),
        us("BJ’s Wholesale Club", "BJ's Wholesale"),
        // Home improvement, pharmacy and general merchandise
        us("The Home Depot", "Home Depot"), us("Lowe’s", "Lowe's Home Centers", "Lowes Home Improvement"),
        us("CVS Pharmacy", "CVS"), us("Walgreens"), us("Best Buy"), us("IKEA"),
        us("Dollar General"), us("Dollar Tree"),
        // Indian grocers in the US
        us("Patel Brothers", "Patel Bros"), us("India Bazaar"), us("Apna Bazar")
    ] + [
        india("DMart", "Avenue Supermarts", "D-Mart", "D Mart"), india("DMart Ready"),
        india("Reliance SMART", "Reliance Smart"), india("SMART Bazaar", "Reliance Smart Bazaar"),
        india("Smart Point"), india("Reliance Fresh"), india("JioMart"), india("BigBasket", "bigbasket"),
        india("Blinkit"), india("Zepto"), india("Swiggy Instamart", "Instamart"),
        india("Spencer’s", "Spencer's Retail"), india("More", "More Retail", "More Supermarket"),
        india("Star Bazaar"), india("Nature’s Basket"), india("Lulu Hypermarket"),
        india("Ratnadeep", "Ratnadeep Supermarket"), india("Nilgiris", "The Nilgiri Dairy Farm"),
        india("Vishal Mega Mart"), india("SPAR Hypermarket", "SPAR"), india("Big Bazaar")
    ]

    /// Every printed spelling mapped to the chain's display name (display name included).
    static var receiptNames: [(printed: String, name: String)] {
        stores.flatMap { store in ([store.name] + store.printedAs).map { ($0, store.name) } }
    }

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
