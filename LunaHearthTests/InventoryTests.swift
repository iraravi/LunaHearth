import Foundation
import SwiftData
import Testing
@testable import LunaHearth

@MainActor struct InventoryTests {
    private func repo() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        return repo
    }
    @Test func addingInventoryTablePreservesExistingShoppingOnDisk() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("home.store")
        func writePreviousStore() throws -> UUID {
            let schema = Schema([Household.self, HouseholdMember.self, FamilyEvent.self, HouseholdTask.self,
                GroceryItem.self, ShoppingStore.self, MealPlanEntry.self, HomeFloor.self, Room.self, HomeAsset.self,
                Warranty.self, MaintenancePlan.self, MaintenanceHistory.self, DocumentRecord.self,
                ReminderDeliverySettings.self, ReminderDeliveryLink.self,
                HouseholdSyncConfiguration.self, HouseholdSyncBaseline.self, ActiveHouseholdSelection.self])
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            let home = Household(name: "Existing home")
            context.insert(home)
            context.insert(GroceryItem(householdID: home.id, name: "Already checked rice", isCompleted: true))
            try context.save()
            return home.id
        }
        let home = try writePreviousStore()
        let schema = LocalStoreConfiguration.schema
        let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
        let reopened = LocalHouseholdRepository(container: container)
        try reopened.reload()
        #expect(reopened.household?.id == home)
        #expect(reopened.groceries.first?.isCompleted == true)
        #expect(reopened.inventory.isEmpty)
        var draft = InventoryDraft(); draft.name = "New pack"
        try reopened.saveInventory(draft)
        let reread = LocalHouseholdRepository(container: container); try reread.reload()
        #expect(reread.inventory.first?.name == "New pack")
    }

    @Test func shoppingTransferRequiresExistingOrSeparatePackChoice() throws {
        let repo = try repo()
        var draft = InventoryDraft(); draft.name = "Milk"; draft.quantity = "1 carton"
        draft.hasExpiryDate = true; draft.expiryDate = Date.now.addingTimeInterval(86400 * 30)
        let id = try repo.saveInventory(draft)
        try repo.add(EntryDraft(kind: .grocery, title: "milk", quantity: "2 cartons"))
        let grocery = try #require(repo.groceries.first)
        #expect(throws: InventoryError.self) { try repo.recordPurchase(grocery, addToInventory: true) }
        #expect(repo.inventory.count == 1 && !grocery.isCompleted)
        #expect(throws: HouseholdValidation.self) { try repo.recordPurchase(grocery, addToInventory: true, keeping: UUID()) }
        try repo.recordPurchase(grocery, addToInventory: true, keeping: id)
        #expect(repo.inventory.count == 1 && grocery.isCompleted && grocery.purchaseDisposition == "inventory")
        #expect(repo.inventory.first?.quantityText == "3 cartons" && repo.inventory.first?.expiryDay == HouseholdDay(draft.expiryDate).key)
        try repo.toggle(grocery)
        try repo.recordPurchase(grocery, addToInventory: true)
        #expect(repo.inventory.count == 1)
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", quantity: "1 carton"))
        let next = try #require(repo.groceries.first { !$0.isCompleted })
        try repo.recordPurchase(next, addToInventory: true, allowSeparatePack: true)
        #expect(repo.inventory.count == 2)
    }

    @Test func existingCurdPurchaseClearsLowStockOnceAndPreservesPackDetails() throws {
        let repo = try repo()
        var draft = InventoryDraft(); draft.name = "Curd"; draft.isLowStock = true
        draft.quantity = "200 g"; draft.hasExpiryDate = true
        draft.expiryDate = Date.now.addingTimeInterval(86400 * 30)
        let id = try repo.saveInventory(draft)
        try repo.add(EntryDraft(kind: .grocery, title: "curd", quantity: "1 kg"))
        let grocery = try #require(repo.groceries.first)
        try repo.recordPurchase(grocery, addToInventory: true, keeping: id)
        try repo.reload()
        let item = try #require(repo.inventory.first)
        #expect(repo.inventory.count == 1 && item.id == id && item.isLowStock == false)
        #expect(item.quantityText == "1200 g" && item.expiryDay == HouseholdDay(draft.expiryDate).key)
        let copy = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try copy.restoreBackup(repo.makeBackup())
        #expect(copy.inventory.first?.isLowStock == false)
        // Stock can become low again after the purchase; reopening history must not replenish it.
        var lowAgain = InventoryDraft(item); lowAgain.isLowStock = true
        try repo.saveInventory(lowAgain, editing: id)
        try repo.toggle(grocery)
        try repo.recordPurchase(grocery, addToInventory: false)
        try repo.recordPurchase(grocery, addToInventory: true, keeping: id)
        #expect(item.isLowStock == true && repo.inventory.count == 1)
    }

    @Test func purchaseForSomeoneElseDoesNotClearLowStock() throws {
        let repo = try repo()
        var draft = InventoryDraft(); draft.name = "Curd"; draft.isLowStock = true
        try repo.saveInventory(draft)
        try repo.add(EntryDraft(kind: .grocery, title: "Curd"))
        try repo.recordPurchase(try #require(repo.groceries.first), addToInventory: false)
        #expect(repo.inventory.count == 1 && repo.inventory.first?.isLowStock == true)
    }

    @Test func separatePurchaseKeepsOldPackLowAndNewPackInStock() throws {
        let repo = try repo()
        var draft = InventoryDraft(); draft.name = "Curd"; draft.isLowStock = true
        let oldID = try repo.saveInventory(draft)
        try repo.add(EntryDraft(kind: .grocery, title: "Curd"))
        try repo.recordPurchase(try #require(repo.groceries.first), addToInventory: true, allowSeparatePack: true)
        #expect(repo.inventory.count == 2)
        #expect(repo.inventory.first(where: { $0.id == oldID })?.isLowStock == true)
        #expect(repo.inventory.first(where: { $0.id != oldID })?.isLowStock != true)
    }

    @Test func onlyNameIsRequiredAndDetailsSurviveBackup() throws {
        let repo = try repo()
        #expect(throws: HouseholdValidation.self) { try repo.saveInventory(InventoryDraft()) }
        var draft = InventoryDraft(); draft.name = "Rice"
        let id = try repo.saveInventory(draft)
        #expect(repo.inventory.first?.expiryDay == nil)
        #expect(repo.inventory.first?.quantityText == nil)
        draft.quantity = "2 kg"; draft.packDetails = "1 sealed pack"; draft.storeName = "DMart"; draft.location = "Pantry"
        draft.hasPackedDate = true; draft.packedDate = try #require(ShoppingEntryRules.date(for: "2026-09-01"))
        draft.hasExpiryDate = true; draft.expiryDate = try #require(ShoppingEntryRules.date(for: "2027-03-01"))
        try repo.saveInventory(draft, editing: id)
        let copy = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try copy.restoreBackup(repo.makeBackup())
        let item = try #require(copy.inventory.first)
        #expect(item.id == id && item.name == "Rice")
        #expect(item.packDetails == "1 sealed pack" && item.quantityText == "2 kg")
        #expect(item.expiryDay == "2027-03-01" && item.packedDay == "2026-09-01")
        #expect(item.storeID == copy.stores.first?.id && item.location == "Pantry")
    }
    @Test func purchaseIsOneAtomicRecordPairAndRetryNeverDuplicatesOrRestocks() throws {
        let repo = try repo()
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", quantity: "2 cartons", storeName: "Walmart"))
        let grocery = try #require(repo.groceries.first)
        try repo.recordPurchase(grocery, addToInventory: true)
        let pack = try #require(repo.inventory.first)
        #expect(grocery.isCompleted && grocery.purchaseDisposition == "inventory")
        #expect(pack.name == "Milk" && pack.quantityText == "2 cartons")
        #expect(pack.storeID == grocery.storeID && pack.sourceGroceryID == grocery.id)
        #expect(pack.expiryDay == nil && pack.packedDay == nil)
        try repo.setInventoryUsedUp(pack, usedUp: true)
        try repo.recordPurchase(grocery, addToInventory: true)
        #expect(repo.inventory.count == 1 && pack.isUsedUp)
        try repo.toggle(grocery)
        #expect(repo.inventory.count == 1)
        try repo.recordPurchase(grocery, addToInventory: false)
        #expect(repo.inventory.count == 1 && grocery.purchaseDisposition == "inventory")
        #expect(repo.tasks.isEmpty)
    }
    @Test func friendsAndLegacyCompletionNeverPopulateInventory() throws {
        let repo = try repo()
        try repo.add(EntryDraft(kind: .grocery, title: "Gift chocolates"))
        let item = try #require(repo.groceries.first)
        try repo.recordPurchase(item, addToInventory: false)
        #expect(item.isCompleted && repo.inventory.isEmpty)
        try repo.toggle(item); try repo.toggle(item); try repo.reload()
        #expect(repo.inventory.isEmpty)
    }
    @Test func purchaseIdentityIsStableAcrossDevicesAndHouseholdScoped() throws {
        let a = try repo()
        try a.add(EntryDraft(kind: .grocery, title: "Rice"))
        let b = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try b.restoreBackup(a.makeBackup())
        try a.recordPurchase(try #require(a.groceries.first), addToInventory: true)
        try b.recordPurchase(try #require(b.groceries.first), addToInventory: true)
        #expect(a.inventory.first?.id == b.inventory.first?.id)
        #expect(InventoryRules.purchaseID(householdID: UUID(), groceryID: a.groceries[0].id) != a.inventory[0].id)
        let another = try repo()
        #expect(throws: HouseholdValidation.self) { try another.recordPurchase(a.groceries[0], addToInventory: true) }
        #expect(another.inventory.isEmpty)
    }
    @Test func invalidDatesAreRejectedWithoutPartialChanges() throws {
        let repo = try repo()
        var draft = InventoryDraft(); draft.name = "Rice"; draft.storeName = "New shop"
        draft.hasPackedDate = true; draft.packedDate = try #require(ShoppingEntryRules.date(for: "2026-10-01"))
        draft.hasExpiryDate = true; draft.expiryDate = try #require(ShoppingEntryRules.date(for: "2026-09-01"))
        #expect(throws: InventoryError.self) { try repo.saveInventory(draft) }
        #expect(repo.inventory.isEmpty && repo.stores.isEmpty)
        for name in ["Asia/Kolkata", "America/Chicago"] {
            let zone = try #require(TimeZone(identifier: name))
            let date = try #require(ShoppingEntryRules.date(for: "2026-11-01", timeZone: zone))
            #expect(HouseholdDay(date, timeZone: zone).key == "2026-11-01")
        }
        #expect(!InventoryRules.needsDateAttention(nil))
        #expect(InventoryRules.expiryLabel(nil, today: "2026-09-13") == "No expiry date")
    }
    @Test func separatePacksRemainSeparateAndRestockDoesNotDoubleShopping() throws {
        let repo = try repo()
        var draft = InventoryDraft(); draft.name = "Rice"
        try repo.saveInventory(draft); try repo.saveInventory(draft, allowSeparatePack: true)
        #expect(repo.inventory.count == 2)
        let item = try #require(repo.inventory.first)
        try repo.restockInventory(item)
        #expect(throws: InventoryError.self) { try repo.restockInventory(item) }
        #expect(repo.groceries.count == 1 && repo.inventory.count == 2)
        #expect(repo.groceries.first?.quantityText == "")
    }
    @Test func kitchenTemplatesSupportHundredItemReviewAndAtomicAdd() throws {
        #expect(IngredientMatching.same("Rajma", "Kidney beans"))
        #expect(!IngredientMatching.same("Moong dal", "Whole mung beans"))
        for style in [PantryStyle.southIndian, .indian, .american] {
            let names = PantrySuggestionRules.reviewed(style.starters, existing: [])
            #expect(names.count >= 100)
            #expect(names.count <= 150)
            #expect(Set(names.map(IngredientMatching.key)).count == names.count)
            let repo = try repo(), home = try #require(repo.household?.id)
            #expect(repo.inventory.isEmpty)
            try repo.addPantryIdeas(names, householdID: home)
            #expect(repo.inventory.count == names.count)
            #expect(repo.inventory.allSatisfy { $0.quantityText == nil && $0.expiryDay == nil && $0.storeID == nil })
            try repo.addPantryIdeas(names, householdID: home)
            #expect(repo.inventory.count == names.count)
            #expect(PantrySuggestionRules.reviewed(style.starters, existing: repo.inventory.map(\.name)).isEmpty)
        }
    }

    @Test func pantryIdeaOutcomesDoNotMislabelFailuresAsGenerated() {
        for outcome in [PantryIdeasOutcome.unavailable, .notEnabled, .modelNotReady, .failed] {
            let ideas = PantryIdeas(names: ["Rice"], outcome: outcome)
            #expect(!ideas.usedModel)
            #expect(outcome.explanation.contains("starter ideas"))
            #expect(outcome.explanation.contains("custom instructions were not applied"))
        }
        #expect(PantryIdeas(names: [], outcome: .noNewIdeas).usedModel)
        #expect(PantryIdeasOutcome.noNewIdeas.explanation.contains("Nothing was added"))
        #expect(PantryIdeas(names: ["Rice"], outcome: .generated).usedModel)
        #expect(PantrySuggestionRules.reviewed(["Rice", "Cumin seeds"], existing: ["rice"]) == ["Cumin seeds"])
    }

    @Test func suggestionsRequireSelectionExcludeExistingAndDoNotInventDates() throws {
        let repo = try repo()
        let home = try #require(repo.household?.id)
        let ideas = PantrySuggestionRules.reviewed(PantryStyle.southIndian.starters + ["RICE", "", "Toor Dal"], existing: ["rice"])
        #expect(!ideas.contains("Rice") && ideas.contains("Urad dal"))
        #expect(repo.inventory.isEmpty)
        try repo.addPantryIdeas(["Toor dal", "toor dal", "Urad dal"], householdID: home)
        #expect(repo.inventory.count == 2)
        #expect(repo.inventory.allSatisfy { $0.expiryDay == nil && $0.quantityText == nil && $0.storeID == nil })
        try repo.addPantryIdeas(["Toor dal"], householdID: home)
        #expect(repo.inventory.count == 2)
        #expect(throws: HouseholdValidation.self) { try repo.addPantryIdeas(["Rice"], householdID: UUID()) }
    }
    @Test func readOnlyPurchaseDoesNotChangeEitherSide() throws {
        let repo = try repo()
        try repo.add(EntryDraft(kind: .grocery, title: "Milk"))
        let home = try #require(repo.household?.id)
        try repo.configureSharing(SyncDestination(householdID: home, zoneName: "LHHousehold-\(home)", ownerName: "owner", accountID: "account", isOwner: false))
        repo.syncConfiguration?.readOnly = true
        #expect(throws: HouseholdSharingError.self) { try repo.recordPurchase(repo.groceries[0], addToInventory: true) }
        #expect(!repo.groceries[0].isCompleted && repo.inventory.isEmpty)
    }
    @Test func inventorySurvivesShoppingDeletionAndBackupValidatesReferences() throws {
        let repo = try repo()
        try repo.add(EntryDraft(kind: .grocery, title: "Rice", storeName: "DMart"))
        let item = try #require(repo.groceries.first)
        try repo.recordPurchase(item, addToInventory: true)
        try repo.deletePlanningEntry(id: item.id, kind: .grocery)
        let backup = try repo.makeBackup()
        try BackupCodec.validate(backup)
        #expect(repo.inventory.count == 1)
        let broken = HouseholdBackup(version: 1, householdID: backup.householdID, name: backup.name, savedAt: backup.savedAt, records: backup.records.filter { $0.kind != "ShoppingStore" })
        #expect(throws: BackupError.self) { try BackupCodec.validate(broken) }
        let reopened = LocalHouseholdRepository(container: repo.context.container)
        try reopened.reload()
        #expect(reopened.inventory.first?.sourceGroceryID == item.id)
    }
}
