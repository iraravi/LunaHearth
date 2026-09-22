import Foundation

struct PantryPhotoScan: Sendable {
    let names: [String]
    let explanation: String
}
protocol PantryPhotoScanning: Sendable {
    func scan(imageData: Data) async throws -> PantryPhotoScan
}
struct PantryPhotoItem: Identifiable {
    let id = UUID()
    var name: String
    var included = false
    var quantity = ""
    var hasExpiry = false
    var expiry = Date.now
}

enum PantryPhotoRules {
    static func names(_ values: [String]) -> [String] {
        var result: [String] = []
        for value in values.prefix(100) {
            let name = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty, name.count <= 100,
                  !name.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
                  !result.contains(where: { IngredientMatching.same($0, name) }) else { continue }
            result.append(name)
            if result.count == 50 { break }
        }
        return result
    }
    /// Whole product-label matches only: ingredient lists and brand prose are not evidence of separate packs.
    static func labelNames(_ lines: [String]) -> [String] {
        let catalog = PantryStyle.allCases.flatMap { $0.template.flatMap(\.names) }
        return names(lines.compactMap { line in
            let clean = line.trimmingCharacters(in: .whitespacesAndNewlines)
            return catalog.first { IngredientMatching.key($0) == IngredientMatching.key(clean) }
        })
    }
}
