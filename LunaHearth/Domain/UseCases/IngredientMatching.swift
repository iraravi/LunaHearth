import Foundation

/// Ingredient identity, not pack identity. Never strips meaningful form/variety words.
enum IngredientMatching {
    static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }.joined(separator: " ")
    }
    private static let groups: [[String]] = [
        ["cumin", "cumin seed", "cumin seeds", "whole cumin", "jeera", "jeeragam", "seeragam"],
        ["cumin powder", "ground cumin", "jeera powder", "jeeragam powder"],
        ["coriander seeds", "coriander seed", "whole coriander", "dhania seeds", "dhaniya seeds"],
        ["coriander powder", "ground coriander", "dhania powder", "dhaniya powder"],
        ["cilantro", "coriander leaves", "fresh coriander"],
        ["fenugreek seeds", "fenugreek seed", "methi seeds", "vendhayam"],
        ["mustard seeds", "mustard seed", "kadugu"],
        ["toor dal", "tuvar dal", "tur dal", "arhar dal", "thuvaram paruppu", "split pigeon peas"],
        ["urad dal", "ulundhu", "ulundu"], ["moong dal", "mung dal", "paasi paruppu"],
        ["chana dal", "split bengal gram", "kadalai paruppu"],
        ["rajma", "kidney beans", "kidney bean"],
        ["cornstarch", "corn starch"],
        ["green gram", "whole mung beans", "whole moong"],
        ["rava", "ravai", "sooji", "suji", "semolina"],
        ["poha", "aval", "flattened rice", "beaten rice"],
        ["besan", "gram flour", "chickpea flour"],
        ["groundnut oil", "peanut oil"], ["turmeric", "turmeric powder", "haldi", "manjal powder"],
        ["curry leaves", "curry leaf", "karuveppilai", "kariveppilai"],
        ["tomato", "tomatoes"], ["potato", "potatoes"], ["onion", "onions"],
        ["egg", "eggs"], ["chickpea", "chickpeas", "garbanzo beans"],
        ["dried red chillies", "dried red chilies", "dried red chilli", "dried red chili"],
        ["chilli powder", "chili powder"]
    ]
    private static let aliases: [String: String] = {
        var result: [String: String] = [:]
        for group in groups { guard let first = group.first else { continue }; for alias in group { result[alias] = first } }
        return result
    }()
    static func key(_ name: String) -> String { let value = normalized(name); return aliases[value] ?? value }
    static func same(_ lhs: String, _ rhs: String) -> Bool { !key(lhs).isEmpty && key(lhs) == key(rhs) }
    /// Name-only search. Aliases broaden discovery, never ingredient/pack identity.
    static func matchesSearch(_ name: String, query: String) -> Bool {
        let queryWords = normalized(query).split(separator: " ")
        guard !queryWords.isEmpty else { return true }
        let value = normalized(name)
        var labels = [value, key(name)]
        // Prefer a specific form (cumin powder) over the shorter ingredient (cumin).
        let matches = groups.flatMap { group in
            group.compactMap { alias -> (String, [String])? in
                (" " + value + " ").contains(" " + alias + " ") ? (alias, group) : nil
            }
        }
        if let match = matches.max(by: { $0.0.count < $1.0.count }) {
            labels += match.1.map { alias in
                (" " + value + " ").replacingOccurrences(of: " " + match.0 + " ", with: " " + alias + " ")
            }
        }
        return labels.contains { label in
            let words = label.split(separator: " ")
            return queryWords.allSatisfy { queryWord in words.contains { $0.hasPrefix(queryWord) } }
        }
    }
    /// Typo matches only request review. They never suppress suggestions or merge records.
    static func possibleTypo(_ lhs: String, _ rhs: String) -> Bool {
        let a = Array(key(lhs)), b = Array(key(rhs))
        guard a.count >= 5, b.count >= 5, a.count <= 200, b.count <= 200,
              abs(a.count - b.count) <= 1,
              key(lhs).split(separator: " ").count == key(rhs).split(separator: " ").count else { return false }
        var previous = Array(0...b.count)
        for (i, x) in a.enumerated() {
            var row = [i + 1]
            for (j, y) in b.enumerated() { row.append(min(row[j] + 1, previous[j + 1] + 1, previous[j] + (x == y ? 0 : 1))) }
            previous = row
        }
        return previous[b.count] == 1
    }
}

struct IngredientComparison: Sendable {
    let matchingIndices: [Int]
    let usedModel: Bool
    static func validated(_ indices: [Int], count: Int) -> [Int] { Array(Set(indices.filter { $0 >= 0 && $0 < count })).sorted() }
}
protocol IngredientComparisonService: Sendable {
    func compare(name: String, candidates: [String]) async throws -> IngredientComparison
}
