import Foundation
import SwiftData
import Testing
@testable import LunaHearth

struct InventoryAttentionTests {
    @Test func expiryBoundariesUseCivilDays() {
        #expect(InventoryRules.expiryState(nil, today: "2026-09-13") == .unknown)
        #expect(InventoryRules.expiryState("invalid", today: "2026-09-13") == .unknown)
        #expect(InventoryRules.expiryState("2026-09-12", today: "2026-09-13") == .past)
        #expect(InventoryRules.expiryState("2026-09-13", today: "2026-09-13") == .today)
        #expect(InventoryRules.expiryState("2026-09-20", today: "2026-09-13") == .soon)
        #expect(InventoryRules.expiryState("2026-09-21", today: "2026-09-13") == .later)
        #expect(InventoryRules.expiryState("2027-01-03", today: "2026-12-28") == .soon)
        #expect(InventoryRules.expiryState("2026-03-10", today: "2026-03-07") == .soon)
    }
    @MainActor @Test func stockFlagRoundTripsAndLegacyPayloadDefaultsToUnknown() throws {
        let repository = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repository.createHousehold(name: "Home", owner: "", members: [])
        var draft = InventoryDraft(); draft.name = "Rice"; draft.isLowStock = true
        try repository.saveInventory(draft)
        let backup = try repository.makeBackup()
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(backup)
        #expect(restored.inventory.first?.isLowStock == true)
        let legacyRecords = try backup.records.map { record -> BackupRecord in
            guard record.kind == "InventoryItem" else { return record }
            var json = try #require(JSONSerialization.jsonObject(with: record.payload) as? [String: Any])
            json.removeValue(forKey: "isLowStock")
            return BackupRecord(id: record.id, householdID: record.householdID, kind: record.kind, createdAt: record.createdAt, modifiedAt: record.modifiedAt, payload: try JSONSerialization.data(withJSONObject: json))
        }
        let legacy = HouseholdBackup(version: backup.version, householdID: backup.householdID, name: backup.name, savedAt: backup.savedAt, records: legacyRecords)
        let old = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try old.restoreBackup(legacy)
        #expect(old.inventory.first?.isLowStock == nil)
        #expect(old.inventory.first?.name == "Rice")
    }
    @MainActor @Test func inventoryAndBackupAreHouseholdScopedNotStoreScoped() throws {
        let container = try LocalStoreConfiguration.makeContainer(inMemory: true)
        let repository = LocalHouseholdRepository(container: container)
        try repository.createHousehold(name: "First", owner: "", members: [])
        let first = try #require(repository.household?.id)
        var draft = InventoryDraft(); draft.name = "Rice"; draft.storeName = "DMart"
        try repository.saveInventory(draft)
        draft.name = "Milk"; draft.storeName = "Costco"; draft.isLowStock = true
        try repository.saveInventory(draft)
        #expect(repository.inventory.count == 2)
        let context = ModelContext(container)
        let second = Household(name: "Second")
        context.insert(second)
        context.insert(InventoryItem(householdID: second.id, name: "Private to second"))
        try context.save(); try repository.reload()
        try repository.activateHousehold(second.id)
        #expect(repository.inventory.map(\.name) == ["Private to second"])
        #expect(try repository.makeBackup().records.allSatisfy { $0.householdID == second.id })
        try repository.activateHousehold(first)
        #expect(Set(repository.inventory.map(\.name)) == ["Rice", "Milk"])
        #expect(repository.inventory.first { $0.name == "Milk" }?.isLowStock == true)
    }
}
