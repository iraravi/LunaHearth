import CloudKit
import Foundation
import SwiftData
import Testing
@testable import LunaHearth

@MainActor struct PrivateShoppingStoreTests {
    private func repository() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        return repo
    }
    @Test func savedStoreSurvivesItemDeletionAndIsReused() throws {
        let repo = try repository()
        let store = try repo.addStore(name: "Anand Stores", branch: "Adyar")
        #expect(try repo.addStore(name: "anand stores", branch: "adyar").id == store.id)
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", storeName: store.displayName))
        let milk = try #require(repo.groceries.first)
        #expect(milk.storeID == store.id)
        try repo.deletePlanningEntry(id: milk.id, kind: .grocery)
        let reopened = LocalHouseholdRepository(container: repo.context.container)
        try reopened.reload()
        #expect(reopened.groceries.isEmpty)
        #expect(reopened.stores.first?.id == store.id)
        #expect(reopened.shoppingStoreNames == ["Anand Stores · Adyar"])
        #expect(try repo.addStore(name: "Anand Stores", branch: "Mylapore").id != store.id)
    }
    @Test func storeIdentityIsHouseholdScopedAndOfflineDeterministic() throws {
        let a = try repository(), b = try repository()
        let first = try a.addStore(name: "Wal Mart")
        #expect(try a.addStore(name: "Walmart").id == first.id)
        #expect(try b.addStore(name: "Walmart").id != first.id)
        let copy = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try copy.restoreBackup(a.makeBackup())
        #expect(try copy.addStore(name: "WALMART").id == first.id)
    }
    @Test func backupRoundTripAndInvalidStoreReference() throws {
        let repo = try repository()
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", storeName: "DMart"))
        let backup = try repo.makeBackup()
        #expect(backup.records.filter { $0.kind == "ShoppingStore" }.count == 1)
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(backup)
        #expect(restored.groceries.first?.storeID == restored.stores.first?.id)
        let incomplete = HouseholdBackup(version: backup.version, householdID: backup.householdID, name: backup.name, savedAt: backup.savedAt, records: backup.records.filter { $0.kind != "ShoppingStore" })
        #expect(throws: BackupError.self) { try BackupCodec.validate(incomplete) }
    }
    @Test func legacyNamesBackfillOnceWithoutLosingItems() throws {
        let repo = try repository()
        let id = try #require(repo.household?.id)
        let milk = GroceryItem(householdID: id, name: "Milk", storeName: "Wal Mart")
        let bread = GroceryItem(householdID: id, name: "Bread", storeName: "Walmart")
        repo.context.insert(milk); repo.context.insert(bread); try repo.context.save()
        try repo.reload()
        #expect(repo.stores.count == 1)
        #expect(milk.storeID == bread.storeID)
        #expect(milk.storeName == "Wal Mart")
        let modified = milk.modifiedAt
        try repo.reload()
        #expect(milk.modifiedAt == modified)
        #expect(repo.groceries.count == 2)
    }
    @Test func cloudMapperAcceptsPrivateStoreRecords() throws {
        let repo = try repository()
        let store = try repo.addStore(name: "Anand Stores")
        let record = try BackupCodec.record(store)
        let write = HouseholdSyncWrite(entity: SyncEntity(record: record, deleted: false), systemFields: nil)
        let zone = CKRecordZone.ID(zoneName: "LHHousehold-\(record.householdID.uuidString)")
        let cloud = try HouseholdCloudMapper.encode(write, zone: zone)
        let restored = try HouseholdCloudMapper.decode(cloud, householdID: record.householdID)
        #expect(restored.entity.record.id == store.id)
        #expect(restored.entity.record.payload == record.payload)
        #expect(throws: HouseholdSharingError.self) { try HouseholdCloudMapper.decode(cloud, householdID: UUID()) }
    }
    @Test func oldBackupWithoutStoreIDStillRestores() throws {
        let repo = try repository()
        try repo.add(EntryDraft(kind: .grocery, title: "Milk", storeName: "Corner Shop"))
        let backup = try repo.makeBackup()
        let records = try backup.records.filter { $0.kind != "ShoppingStore" }.map { record in
            guard record.kind == "GroceryItem" else { return record }
            var json = try #require(JSONSerialization.jsonObject(with: record.payload) as? [String: Any])
            json.removeValue(forKey: "storeID")
            return BackupRecord(id: record.id, householdID: record.householdID, kind: record.kind, createdAt: record.createdAt, modifiedAt: record.modifiedAt, payload: try JSONSerialization.data(withJSONObject: json))
        }
        let old = HouseholdBackup(version: 1, householdID: backup.householdID, name: backup.name, savedAt: backup.savedAt, records: records)
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(old)
        #expect(restored.groceries.first?.name == "Milk")
        #expect(restored.stores.first?.name == "Corner Shop")
        #expect(restored.groceries.first?.storeID == restored.stores.first?.id)
    }

    @Test func diskUpgradeAddsStoreTableAndKeepsShopping() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("upgrade.store")
        func legacy() throws {
            let schema = Schema([Household.self, GroceryItem.self])
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let context = ModelContext(container)
            let home = Household(name: "Existing home")
            context.insert(home); context.insert(GroceryItem(householdID: home.id, name: "Milk", storeName: "Corner Shop"))
            try context.save()
        }
        try legacy()
        let schema = LocalStoreConfiguration.schema
        func upgrade() throws -> UUID {
            let container = try ModelContainer(for: schema, configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)])
            let repo = LocalHouseholdRepository(container: container); try repo.reload()
            #expect(repo.groceries.first?.name == "Milk")
            return try #require(repo.stores.first?.id)
        }
        let id = try upgrade()
        #expect(try upgrade() == id)
    }
}
