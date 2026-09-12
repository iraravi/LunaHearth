import Foundation
import SwiftData
import Testing
@testable import LunaHearth

@MainActor struct BackupTests {
    private func repository() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.reload()
        return repo
    }

    @Test func uploadBatchesRespectCountAndSize() {
        let home = UUID()
        let records = (0..<215).map { _ in
            BackupRecord(id: UUID(), householdID: home, kind: "Room", createdAt: .now, modifiedAt: .now, payload: Data(repeating: 0, count: 100_000))
        }
        let batches = BackupBatches.make(records)
        #expect(batches.flatMap { $0 } == records)
        #expect(batches.allSatisfy { $0.count <= 100 && $0.reduce(0) { $0 + $1.payload.count } <= 4_000_000 })
        #expect(BackupBatches.make([]).isEmpty)
    }

    @Test func setupCreatesFirstRoomAtomically() throws {
        let repo = try repository()
        #expect(throws: HouseholdValidation.self) {
            try repo.createHousehold(name: "Home", owner: "", members: [], firstRoom: " ")
        }
        #expect(repo.household == nil)
        try repo.createHousehold(name: "Home", owner: "Alex", members: [], firstRoom: " Kitchen ")
        #expect(repo.rooms.first?.name == "Kitchen")
        #expect(repo.rooms.first?.householdID == repo.household?.id)
        #expect(repo.members.first?.householdID == repo.household?.id)
    }

    @Test func completeHouseholdBackupRestoresIntoAnotherStore() throws {
        let repo = try repository()
        try repo.createHousehold(name: "Home", owner: "Alex", members: [("Sam", .child)], firstRoom: "Kitchen")
        try repo.add(EntryDraft(kind: .floor, title: "Ground floor"))
        let room = try #require(repo.rooms.first)
        room.floorID = repo.floors.first?.id
        room.layoutX = 0; room.layoutZ = 0; room.layoutWidth = 5; room.layoutDepth = 4; room.layoutHeight = 2.7
        try repo.add(EntryDraft(kind: .asset, title: "Fridge", parentID: room.id, manufacturer: "Acme"))
        let asset = try #require(repo.assets.first)
        asset.purchasePriceMinorUnits = 12345
        asset.currencyCode = "USD"
        asset.serialNumber = "Serial 123"
        try repo.add(EntryDraft(kind: .warranty, title: "Cover", parentID: asset.id))
        try repo.add(EntryDraft(kind: .maintenance, title: "Filter", parentID: asset.id, intervalDays: 30, repeats: true, shoppingItem: "Filter"))
        let plan = try #require(repo.maintenance.first)
        try repo.completeMaintenance(plan)
        try repo.addReplacementToShopping(plan)
        for kind: EntryKind in [.event, .task, .meal] { try repo.add(EntryDraft(kind: kind, title: kind.rawValue)) }
        let backup = try repo.makeBackup()
        let restored = try repository()
        try restored.restoreBackup(backup)
        let after = try restored.makeBackup()
        #expect(Dictionary(uniqueKeysWithValues: backup.records.map { ($0.id, $0) }) == Dictionary(uniqueKeysWithValues: after.records.map { ($0.id, $0) }))
        #expect(restored.assets.first?.purchasePriceMinorUnits == 12345)
        #expect(restored.rooms.first?.layoutWidth == 5)
        #expect(restored.history.first?.planID == plan.id)
        #expect(restored.meals.first?.dateKey == repo.meals.first?.dateKey)
        #expect(throws: BackupError.self) { try restored.restoreBackup(backup) }
        #expect(restored.assets.count == 1)
    }

    @Test func corruptOrIncompleteBackupNeverCreatesPartialHome() throws {
        let repo = try repository()
        try repo.createHousehold(name: "Home", owner: "", members: [], firstRoom: "Kitchen")
        try repo.add(EntryDraft(kind: .asset, title: "Fridge", parentID: repo.rooms.first?.id))
        let snapshot = try repo.makeBackup()
        let target = try repository()
        let missingRoom = HouseholdBackup(version: 1, householdID: snapshot.householdID, name: snapshot.name,
                                         savedAt: snapshot.savedAt, records: snapshot.records.filter { $0.kind != "Room" })
        #expect(throws: BackupError.self) { try target.restoreBackup(missingRoom) }
        #expect(target.household == nil)
        let duplicate = HouseholdBackup(version: 1, householdID: snapshot.householdID, name: snapshot.name,
                                       savedAt: snapshot.savedAt, records: snapshot.records + snapshot.records)
        #expect(throws: BackupError.self) { try target.restoreBackup(duplicate) }
        let corrupt = snapshot.records.map { BackupRecord(id: $0.id, householdID: $0.householdID, kind: $0.kind,
                                                          createdAt: $0.createdAt, modifiedAt: $0.modifiedAt, payload: Data("bad".utf8)) }
        #expect(throws: (any Error).self) {
            try target.restoreBackup(HouseholdBackup(version: 1, householdID: snapshot.householdID, name: snapshot.name, savedAt: snapshot.savedAt, records: corrupt))
        }
        try target.reload()
        #expect(target.household == nil)
        #expect(target.assets.isEmpty)
    }

    @Test func invalidRemoteRoomGeometryIsRejectedBeforeRestore() throws {
        let repo = try repository()
        try repo.createHousehold(name: "Home", owner: "", members: [], firstRoom: "Kitchen")
        let backup = try repo.makeBackup()
        let records = try backup.records.map { record in
            guard record.kind == "Room" else { return record }
            var fields = try #require(JSONSerialization.jsonObject(with: record.payload) as? [String: Any])
            fields["layoutX"] = -1; fields["layoutZ"] = 0
            fields["layoutWidth"] = 5; fields["layoutDepth"] = 4; fields["layoutHeight"] = 2.7
            return BackupRecord(id: record.id, householdID: record.householdID, kind: record.kind,
                                createdAt: record.createdAt, modifiedAt: record.modifiedAt,
                                payload: try JSONSerialization.data(withJSONObject: fields))
        }
        let target = try repository()
        #expect(throws: LayoutError.self) {
            try target.restoreBackup(HouseholdBackup(version: 1, householdID: backup.householdID,
                                                    name: backup.name, savedAt: backup.savedAt, records: records))
        }
        #expect(target.household == nil)
    }

    @Test func localFileReferencesAreNotSilentlyBackedUp() throws {
        let repo = try repository()
        try repo.createHousehold(name: "Home", owner: "", members: [], firstRoom: "Kitchen")
        repo.rooms.first?.roomPlanAssetPath = "private/scan.usdz"
        // Commit the existing room via a normal repository write.
        try repo.add(EntryDraft(kind: .task, title: "Task"))
        #expect(throws: BackupError.self) { try repo.makeBackup() }
    }
}
