import Foundation

enum VirtualPantryZone: String, CaseIterable, Identifiable, Sendable {
    case fridge, freezer, cupboard, other
    var id: String { rawValue }
    var title: String {
        switch self { case .fridge: "Fridge"; case .freezer: "Freezer"; case .cupboard: "Pantry"; case .other: "Other" }
    }
}

/// Visual grouping only. Never changes saved locations or supplies food-storage advice.
enum VirtualPantryRules {
    static func zone(name: String, location: String?) -> VirtualPantryZone {
        let place = (location ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !place.isEmpty {
            if place.contains("freezer") { return .freezer }
            if place.contains("fridge") || place.contains("refrigerator") { return .fridge }
            if place.contains("pantry") || place.contains("cupboard") || place.contains("cabinet") { return .cupboard }
            return .other
        }
        switch PantryVisualRules.category(name) {
        case .produce, .chilled, .meat: return .fridge
        case .grains, .pulses, .spices, .essentials: return .cupboard
        case .household, .other: return .other
        }
    }
    /// Top contact surfaces measured from the bundled artwork, not item center positions.
    static func shelfSurface(row: Int, zone: VirtualPantryZone) -> Double {
        let surfaces: [Double]
        switch zone {
        case .fridge, .freezer: surfaces = [0.300, 0.488, 0.672]
        case .cupboard: surfaces = [0.314, 0.517, 0.729]
        case .other: surfaces = [0.31, 0.48, 0.65]
        }
        return surfaces[min(2, max(0, row))]
    }
    static func showsColdMist(zone: VirtualPantryZone) -> Bool {
        zone == .fridge || zone == .freezer
    }
    static func pageCount(itemCount: Int) -> Int { max(1, (max(0, itemCount) + 8) / 9) }
    static func pageRange(page: Int, itemCount: Int) -> Range<Int> {
        let count = max(0, itemCount)
        let start = min(max(0, page), pageCount(itemCount: count) - 1) * 9
        return min(start, count)..<min(start + 9, count)
    }
}
