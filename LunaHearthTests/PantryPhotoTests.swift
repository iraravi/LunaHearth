import Foundation
import SwiftData
import Testing
import UIKit
@testable import LunaHearth

struct PantryPhotoRulesTests {
    @Test func namesAreBoundedAndAliasesCollapse() {
        #expect(PantryPhotoRules.names([" Milk ", "milk", "Cumin", "Cumin seeds", "", "bad\nname", String(repeating: "a", count: 101)]) == ["Milk", "Cumin"])
        #expect(PantryPhotoRules.names((0..<70).map { "Item \($0)" }).count == 50)
    }
    @Test func labelsDoNotInventItemsFromIngredientsOrBrandProse() {
        let result = PantryPhotoRules.labelNames(["RICE", "Cumin seeds", "Ingredients: milk, sugar, rice", "Best brand rice", "Nutrition Facts"])
        #expect(result.count == 2)
        #expect(result.contains { IngredientMatching.same($0, "Rice") })
        #expect(!result.contains { IngredientMatching.same($0, "Milk") })
    }
}

@MainActor struct PantryPhotoPersistenceTests {
    private func repo() throws -> LocalHouseholdRepository {
        let result = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try result.createHousehold(name: "Photo test", owner: "", members: [])
        return result
    }
    @Test func confirmationSkipsExistingAndRepeatedNamesWithoutRestocking() throws {
        let repository = try repo()
        let home = try #require(repository.household?.id)
        var draft = InventoryDraft(); draft.name = "Milk"; draft.quantity = "1 carton"; draft.isLowStock = true
        try repository.saveInventory(draft)
        let rows = [PantryPhotoItem(name: "milk", included: true, quantity: "5 cartons"), PantryPhotoItem(name: "Rice", included: true), PantryPhotoItem(name: "rice", included: true), PantryPhotoItem(name: "Beans")]
        #expect(try repository.importPantryPhoto(rows, householdID: home) == 1)
        #expect(repository.inventory.count == 2)
        #expect(repository.inventory.first { $0.name == "Milk" }?.quantityText == "1 carton")
        #expect(repository.inventory.first { $0.name == "Milk" }?.isLowStock == true)
        #expect(repository.inventory.first { $0.name == "Rice" }?.expiryDay == nil)
        #expect(repository.groceries.isEmpty && repository.purchases.isEmpty && repository.expenses.isEmpty)
        #expect(try repository.importPantryPhoto(rows, householdID: home) == 0)
    }
    @Test func invalidBatchAndHouseholdDoNotPartiallySave() throws {
        let repository = try repo(); let home = try #require(repository.household?.id)
        #expect(throws: (any Error).self) { try repository.importPantryPhoto([PantryPhotoItem(name: "Rice", included: true), PantryPhotoItem(name: "", included: true)], householdID: home) }
        #expect(repository.inventory.isEmpty)
        #expect(throws: (any Error).self) { try repository.importPantryPhoto([PantryPhotoItem(name: "Rice", included: true)], householdID: UUID()) }
        #expect(repository.inventory.isEmpty)
    }
    @Test func explicitAmountAndDateAreSaved() throws {
        let repository = try repo(); let home = try #require(repository.household?.id)
        let expiry = Date(timeIntervalSince1970: 1_900_000_000)
        try repository.importPantryPhoto([PantryPhotoItem(name: "Rice", included: true, quantity: "500 g", hasExpiry: true, expiry: expiry)], householdID: home)
        #expect(repository.inventory.first?.quantityText == "500 g")
        #expect(repository.inventory.first?.expiryDay == HouseholdDay(expiry).key)
    }
    @Test func realVisionLabelFallbackReadsSyntheticPhoto() async throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 700, height: 500)).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 700, height: 500))
            ("RICE\nMILK" as NSString).draw(in: CGRect(x: 70, y: 50, width: 500, height: 400), withAttributes: [.font: UIFont.systemFont(ofSize: 65), .foregroundColor: UIColor.black])
        }
        let data = try #require(image.pngData())
        let result = try await OnDevicePantryPhotoScanner(allowsImageModel: false).scan(imageData: data)
        #expect(result.names.contains { IngredientMatching.same($0, "Rice") })
        #expect(result.names.contains { IngredientMatching.same($0, "Milk") })
    }
}
