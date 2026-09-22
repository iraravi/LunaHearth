import Foundation
import Testing
@testable import LunaHearth

@MainActor struct PrivateFoundationTests {
    @Test func shoppingDetailsSurviveEditReopenAndLegacyBackupRestore() throws {
        let container = try LocalStoreConfiguration.makeContainer(inMemory: true)
        let repo = LocalHouseholdRepository(container: container)
        try repo.createHousehold(name: "Home", owner: "Ravi", members: [])
        let buyer = try #require(repo.members.first?.id)
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", memberID: buyer, quantity: "2 litres", storeName: "  Market  ", neededLater: true))
        let milk = try #require(repo.groceries.first)
        #expect(milk.storeName == "Market")
        var edit = EntryDraft.editing(milk)
        edit.quantity = "3 litres"
        try repo.add(edit)
        let reopened = LocalHouseholdRepository(container: container)
        try reopened.reload()
        #expect(reopened.groceries.first?.assignedMemberID == buyer)
        #expect(reopened.groceries.first?.storeName == "Market")
        #expect(reopened.groceries.first?.neededLater == true)
        #expect(reopened.groceries.first?.quantityText == "3 litres")
        let backup = try reopened.makeBackup()
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(backup)
        #expect(restored.groceries.first?.assignedMemberID == buyer)
        #expect(restored.groceries.first?.storeName == "Market")
        #expect(restored.groceries.first?.neededLater == true)
        #expect(throws: HouseholdValidation.self) { try repo.add(EntryDraft(kind: .grocery, title: "Bread", memberID: UUID())) }
        let legacyRecords = try backup.records.map { record -> BackupRecord in
            guard record.kind == "GroceryItem" else { return record }
            var object = try #require(JSONSerialization.jsonObject(with: record.payload) as? [String: Any])
            object.removeValue(forKey: "neededLater"); object.removeValue(forKey: "storeName"); object.removeValue(forKey: "assignedMemberID")
            return BackupRecord(id: record.id, householdID: record.householdID, kind: record.kind, createdAt: record.createdAt, modifiedAt: record.modifiedAt, payload: try JSONSerialization.data(withJSONObject: object))
        }
        let legacy = HouseholdBackup(version: backup.version, householdID: backup.householdID, name: backup.name, savedAt: backup.savedAt, records: legacyRecords)
        let older = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try older.restoreBackup(legacy)
        #expect(older.groceries.first?.name == "Milk")
        #expect(older.groceries.first?.storeName == nil)
        #expect(older.groceries.first?.neededLater != true)
        #expect(older.groceries.first?.assignedMemberID == nil)
    }

    @Test func retirementPreservesHistoryAndPreventsNewAutomaticCopies() throws {
        let container = try LocalStoreConfiguration.makeContainer(inMemory: true)
        let repo = LocalHouseholdRepository(container: container)
        try repo.createHousehold(name: "My Home", owner: "Ravi", members: [], firstRoom: "Kitchen")
        try repo.configureReminderDelivery(enabled: true, listID: "old-apple-list")
        try repo.add(EntryDraft(kind: .task, title: "Existing reminder"))
        let oldLink = try #require(repo.reminderDeliveryLinks.first)
        let oldID = oldLink.taskID
        try repo.retireAutomaticReminderDelivery()
        try repo.retireAutomaticReminderDelivery()
        try repo.add(EntryDraft(kind: .task, title: "New household reminder"))
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", quantity: "2 cartons"))
        let reopened = LocalHouseholdRepository(container: container)
        try reopened.reload()
        #expect(reopened.reminderDeliverySettings?.enabled == false)
        #expect(reopened.pendingReminderJobs().isEmpty)
        #expect(reopened.reminderDeliveryLinks.map(\.taskID) == [oldID])
        #expect(reopened.tasks.count == 2)
        #expect(reopened.groceries.first?.quantityText == "2 cartons")
        let backup = try reopened.makeBackup()
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(backup)
        #expect(restored.tasks.count == 2)
        #expect(restored.groceries.first?.name == "Milk")
        #expect(restored.rooms.first?.name == "Kitchen")
        #expect(restored.members.first?.displayName == "Ravi")
        #expect(restored.reminderDeliveryLinks.isEmpty)
    }

    @Test func replacementDraftPreservesAssetLinkAndRejectsUnknownAsset() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        try repo.add(EntryDraft(kind: .asset, title: "Fridge"))
        let assetID = try #require(repo.assets.first?.id)
        try repo.add(EntryDraft(kind: .grocery, title: "Filter", parentID: assetID))
        #expect(repo.groceries.first?.relatedAssetID == assetID)
        #expect(throws: HouseholdValidation.self) {
            try repo.add(EntryDraft(kind: .grocery, title: "Unknown filter", parentID: UUID()))
        }
        #expect(repo.groceries.count == 1)
    }

    @Test func invalidSetupDoesNotLeavePartialHousehold() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        #expect(throws: HouseholdValidation.self) {
            try repo.createHousehold(name: "Our Home", owner: "Ravi", members: [("   ", .adult)], firstRoom: "Kitchen")
        }
        try repo.reload()
        #expect(repo.household == nil)
        #expect(repo.rooms.isEmpty)
        try repo.createHousehold(name: "My Home", owner: "", members: [], firstRoom: nil)
        let originalID = try #require(repo.household?.id)
        #expect(throws: HouseholdValidation.self) {
            try repo.createHousehold(name: "Another Home", owner: "", members: [])
        }
        #expect(repo.household?.id == originalID)
    }
}
