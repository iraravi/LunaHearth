import Testing
@testable import LunaHearth

struct VirtualPantryTests {
    @Test func shelfContactsFollowArtworkAndStayWithinScene() {
        for zone in VirtualPantryZone.allCases {
            let levels = (0..<3).map { VirtualPantryRules.shelfSurface(row: $0, zone: zone) }
            #expect(levels == levels.sorted())
            #expect(levels.allSatisfy { $0 > 0 && $0 < 1 })
        }
        #expect(VirtualPantryRules.shelfSurface(row: 0, zone: .fridge) == 0.300)
        #expect(VirtualPantryRules.shelfSurface(row: 2, zone: .cupboard) == 0.729)
    }
    @Test func coldMistOnlyForRefrigeratedZones() {
        #expect(VirtualPantryRules.showsColdMist(zone: .fridge))
        #expect(VirtualPantryRules.showsColdMist(zone: .freezer))
        #expect(!VirtualPantryRules.showsColdMist(zone: .cupboard))
        #expect(!VirtualPantryRules.showsColdMist(zone: .other))
    }
    @Test func explicitPrimaryStorageChoicesOverrideAutomaticGrouping() {
        #expect(VirtualPantryRules.zone(name: "Milk", location: "Pantry") == .cupboard)
        #expect(VirtualPantryRules.zone(name: "Rice", location: "Fridge") == .fridge)
        #expect(VirtualPantryZone.cupboard.title == "Pantry")
    }
    @Test func savedLocationOverridesVisualCategory() {
        #expect(VirtualPantryRules.zone(name: "Rice", location: "Freezer drawer") == .freezer)
        #expect(VirtualPantryRules.zone(name: "Milk", location: "Garage shelf") == .other)
        #expect(VirtualPantryRules.zone(name: "Tomato", location: "Kitchen cupboard") == .cupboard)
        #expect(VirtualPantryRules.zone(name: "Milk", location: "Refrigerator door") == .fridge)
    }
    @Test func offlineGroupingSeparatesDryAndChilledGoods() {
        #expect(VirtualPantryRules.zone(name: "Tomato", location: nil) == .fridge)
        #expect(VirtualPantryRules.zone(name: "Milk", location: nil) == .fridge)
        #expect(VirtualPantryRules.zone(name: "Rice", location: nil) == .cupboard)
        #expect(VirtualPantryRules.zone(name: "Unknown product", location: nil) == .other)
    }
    @Test func foodIllustrationsKeepDairyProductsDistinct() {
        #expect(PantryVisualRules.icon("Paneer", category: .chilled) == "🧀")
        #expect(PantryVisualRules.icon("Yogurt", category: .chilled) == "🥣")
        #expect(PantryVisualRules.icon("Milk", category: .chilled) == "🥛")
    }
    @Test func pagesDoNotDropOrDuplicatePacksAndClampAfterRemoval() {
        for count in 0...150 {
            let pages = VirtualPantryRules.pageCount(itemCount: count)
            let indexes = (0..<pages).flatMap { Array(VirtualPantryRules.pageRange(page: $0, itemCount: count)) }
            #expect(indexes == Array(0..<count))
        }
        #expect(VirtualPantryRules.pageRange(page: 20, itemCount: 2) == 0..<2)
        #expect(VirtualPantryRules.pageRange(page: -1, itemCount: 0).isEmpty)
    }
}
