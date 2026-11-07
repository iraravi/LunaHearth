import Foundation
import SwiftData
import CryptoKit

extension LocalHouseholdRepository {
    func portableBackupSources() throws -> (HouseholdBackup, [PortableDocument], [BackupFileSource]) {
        let backup = try makeRecordBackup(includingFiles: true)
        let metadata = documents.map { PortableDocument(id: $0.id, assetID: $0.assetID, title: $0.title,
            kind: $0.kindRawValue, createdAt: $0.createdAt, modifiedAt: $0.modifiedAt) }
        let sources = documents.map { BackupFileSource(owner: .document, recordID: $0.id, relativePath: $0.localRelativePath) }
            + rooms.compactMap { room in room.roomPlanAssetPath.map { BackupFileSource(owner: .roomScan, recordID: room.id, relativePath: $0) } }
        return (backup, metadata, sources)
    }

    func validatePortableBackup(_ backup: PortableBackup) throws {
        guard backup.formatVersion == 1, backup.documents.count <= 10_000, backup.files.count <= 10_000 else { throw PortableBackupError.invalid }
        try BackupCodec.validate(backup.household)
        let records = Dictionary(uniqueKeysWithValues: backup.household.records.map { ($0.id, $0.kind) })
        let documentIDs = Set(backup.documents.map(\.id))
        guard documentIDs.count == backup.documents.count,
              documentIDs.isDisjoint(with: Set(records.keys)),
              Set(backup.files.map { $0.owner.rawValue + $0.recordID.uuidString }).count == backup.files.count,
              backup.files.reduce(0, { $0 + $1.bytes.count }) <= PortableBackupFiles.attachmentLimit,
              Set(backup.files.filter { $0.owner == .document }.map(\.recordID)) == documentIDs else { throw PortableBackupError.invalid }
        for document in backup.documents {
            guard DocumentKind(rawValue: document.kind) != nil, !document.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  document.title.utf8.count <= 10_000,
                  document.createdAt.timeIntervalSince1970.isFinite, document.modifiedAt.timeIntervalSince1970.isFinite,
                  document.assetID.map({ records[$0] == "HomeAsset" }) ?? true else { throw PortableBackupError.invalid }
        }
        for file in backup.files {
            guard (1...16).contains(file.filenameExtension.utf8.count), file.filenameExtension.utf8.allSatisfy({ (48...57).contains($0) || (65...90).contains($0) || (97...122).contains($0) }) else { throw PortableBackupError.invalid }
        }
        for file in backup.files where file.owner == .roomScan {
            guard records[file.recordID] == "Room" else { throw PortableBackupError.invalid }
        }
    }

    /// Caller installs attachments first. Validation and a single save precede publishing UI state.
    /// Does not restore device links or CloudKit ownership; restored home starts local-only.
    func restorePortableBackup(_ backup: PortableBackup, directory: String) throws {
        guard try context.fetchCount(FetchDescriptor<Household>()) == 0 else { throw BackupError.existingHome }
        try validatePortableBackup(backup)
        guard directory.hasPrefix("restore-"), UUID(uuidString: String(directory.dropFirst(8))) != nil else { throw PortableBackupError.invalid }
        do {
            for record in backup.household.records { try BackupCodec.insert(record, into: context) }
            for document in backup.documents {
                guard let file = backup.files.first(where: { $0.owner == .document && $0.recordID == document.id }),
                      let kind = DocumentKind(rawValue: document.kind) else { throw PortableBackupError.invalid }
                context.insert(DocumentRecord(id: document.id, householdID: backup.household.householdID,
                    assetID: document.assetID, title: document.title, kind: kind,
                    localRelativePath: directory + "/" + PortableBackupFiles.filename(file),
                    sha256: SHA256.hash(data: file.bytes).map { String(format: "%02x", $0) }.joined(),
                    createdAt: document.createdAt, modifiedAt: document.modifiedAt))
            }
            let restoredRooms = try context.fetch(FetchDescriptor<Room>())
            for file in backup.files where file.owner == .roomScan {
                guard let room = restoredRooms.first(where: { $0.id == file.recordID }) else { throw PortableBackupError.invalid }
                room.roomPlanAssetPath = directory + "/" + PortableBackupFiles.filename(file)
            }
            try context.save()
        } catch { context.rollback(); throw error }
        // A post-save UI reload failure must not cause the caller to delete committed attachments.
        try? reload()
    }
}
