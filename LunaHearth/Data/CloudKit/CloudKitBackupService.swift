import CloudKit
import Foundation

/// Manual private backups, isolated from the future CKShare collaboration transport.
actor CloudKitBackupService: HouseholdBackupService {
    private enum Schema {
        static let container = "iCloud.com.neuralluna.lunahearth"
        static let catalogZone = "LHPrivateBackupCatalog"
        static let latest = "LatestBackup"
        static let manifestType = "LHBackupManifest"
        static let entityType = "LHBackupEntity"
        static let payload = "payload"
        static let zone = "snapshotZone"
        static let ids = "recordNames"
        static let household = "householdID"
        static let name = "householdName"
        static let saved = "savedAt"
        static let version = "schemaVersion"
        static let kind = "entityKind"
        static let created = "createdAt"
        static let modified = "modifiedAt"
    }

    private func readyContainer() async throws -> CKContainer {
        // Avoid constructing CloudKit in unsigned previews/tests. Signing and container
        // provisioning must be configured together before enabling this integration.
        guard let team = Bundle.main.object(forInfoDictionaryKey: "CloudKitDevelopmentTeam") as? String,
              !team.isEmpty, !team.contains("$("),
              !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { throw BackupError.unavailable }
        let container = CKContainer(identifier: Schema.container)
        guard try await container.accountStatus() == .available else { throw BackupError.noAccount }
        return container
    }

    func upload(_ backup: HouseholdBackup) async throws {
        try backup.validateEnvelope()
        let container = try await readyContainer()
        let account = try await container.userRecordID()
        let database = container.privateCloudDatabase
        let catalogID = CKRecordZone.ID(zoneName: Schema.catalogZone)
        _ = try await database.save(CKRecordZone(zoneID: catalogID))
        let latestID = CKRecord.ID(recordName: Schema.latest, zoneID: catalogID)
        let manifest: CKRecord
        do { manifest = try await database.record(for: latestID) }
        catch let error as CKError where error.code == .unknownItem {
            manifest = CKRecord(recordType: Schema.manifestType, recordID: latestID)
        }
        let previousZone = manifest[Schema.zone] as? String
        let zoneID = CKRecordZone.ID(zoneName: "LHBackup-\(backup.householdID.uuidString)-\(UUID().uuidString)")
        _ = try await database.save(CKRecordZone(zoneID: zoneID))
        var publicationAttempted = false
        do {
            // A fresh immutable generation allows bounded batches without exposing a partial backup.
            for batch in BackupBatches.make(backup.records) {
                try Task.checkCancellation()
                let records = batch.map { value in
                    let record = CKRecord(recordType: Schema.entityType, recordID: CKRecord.ID(recordName: value.id.uuidString, zoneID: zoneID))
                    record[Schema.payload] = value.payload as NSData
                    record[Schema.household] = value.householdID.uuidString as NSString
                    record[Schema.kind] = value.kind as NSString
                    record[Schema.created] = value.createdAt as NSDate
                    record[Schema.modified] = value.modifiedAt as NSDate
                    record[Schema.version] = 1 as NSNumber
                    return record
                }
                let results = try await database.modifyRecords(saving: records, deleting: [], savePolicy: .ifServerRecordUnchanged, atomically: true)
                for result in results.saveResults.values { _ = try result.get() }
                guard results.saveResults.count == records.count else { throw BackupError.invalidBackup }
            }
            guard try await container.userRecordID() == account else { throw BackupError.accountChanged }
            manifest[Schema.zone] = zoneID.zoneName as NSString
            manifest[Schema.ids] = backup.records.map { $0.id.uuidString } as NSArray
            manifest[Schema.household] = backup.householdID.uuidString as NSString
            manifest[Schema.name] = backup.name as NSString
            manifest[Schema.saved] = backup.savedAt as NSDate
            manifest[Schema.version] = backup.version as NSNumber
            // A concurrent backup changes this record's tag and rejects this publication.
            publicationAttempted = true
            let result = try await database.modifyRecords(saving: [manifest], deleting: [], savePolicy: .ifServerRecordUnchanged, atomically: true)
            guard let saved = result.saveResults[latestID] else { throw BackupError.invalidBackup }
            _ = try saved.get()
            // Only an acknowledged publication permits retiring the previous generation.
            if let previousZone, previousZone.hasPrefix("LHBackup-"), previousZone != zoneID.zoneName {
                _ = try? await database.deleteRecordZone(withID: CKRecordZone.ID(zoneName: previousZone))
            }
        } catch {
            // Before publication this generation cannot be referenced by a valid backup.
            // After an ambiguous publication error, keep it: the server may have committed.
            if !publicationAttempted, (try? await container.userRecordID()) == account {
                _ = try? await database.deleteRecordZone(withID: zoneID)
            }
            throw error
        }
    }

    func download() async throws -> HouseholdBackup {
        let container = try await readyContainer()
        let account = try await container.userRecordID()
        let database = container.privateCloudDatabase
        let manifest: CKRecord
        do {
            manifest = try await database.record(for: CKRecord.ID(recordName: Schema.latest, zoneID: CKRecordZone.ID(zoneName: Schema.catalogZone)))
        } catch let error as CKError where error.code == .unknownItem || error.code == .zoneNotFound {
            throw BackupError.noBackup
        }
        guard let version = manifest[Schema.version] as? Int, version == 1,
              let zone = manifest[Schema.zone] as? String, zone.hasPrefix("LHBackup-"),
              let names = manifest[Schema.ids] as? [String], !names.isEmpty, names.count <= 10_000,
              let home = manifest[Schema.household] as? String, let householdID = UUID(uuidString: home),
              let name = manifest[Schema.name] as? String, let date = manifest[Schema.saved] as? Date
        else { throw BackupError.invalidBackup }
        var records: [BackupRecord] = []
        for start in stride(from: 0, to: names.count, by: 100) {
            try Task.checkCancellation()
            let ids = names[start..<min(start + 100, names.count)].map { CKRecord.ID(recordName: $0, zoneID: CKRecordZone.ID(zoneName: zone)) }
            let results = try await database.records(for: ids)
            for id in ids {
                guard let result = results[id] else { throw BackupError.invalidBackup }
                let record = try result.get()
                guard let uuid = UUID(uuidString: id.recordName),
                      let payload = record[Schema.payload] as? Data,
                      let kind = record[Schema.kind] as? String,
                      let created = record[Schema.created] as? Date,
                      let modified = record[Schema.modified] as? Date,
                      record[Schema.household] as? String == home,
                      record[Schema.version] as? Int == 1 else { throw BackupError.invalidBackup }
                records.append(BackupRecord(id: uuid, householdID: householdID, kind: kind, createdAt: created, modifiedAt: modified, payload: payload))
            }
        }
        guard try await container.userRecordID() == account else { throw BackupError.accountChanged }
        let backup = HouseholdBackup(version: version, householdID: householdID, name: name, savedAt: date, records: records)
        try backup.validateEnvelope()
        return backup
    }
}
