import CloudKit
import Foundation

/// Explicit private/shared custom zones. No public database or automatic SwiftData mirroring.
actor CloudKitHouseholdService: HouseholdSharingService, HouseholdPushService, HouseholdInvitationLookupService, NamedHouseholdInvitationService {
    nonisolated let linksCurrentMemberAutomatically = true
    private var subscribedDestinations: [SyncDestination] = []

    func enableChangeNotifications(in destination: SyncDestination) async throws {
        let (container, _) = try await ready(destination)
        guard !subscribedDestinations.contains(destination) else { return }
        let subscription = CKDatabaseSubscription(subscriptionID: "LHShoppingChanges-v1")
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        _ = try await database(container, destination).save(subscription)
        subscribedDestinations.append(destination)
    }
    static let containerIdentifier = "iCloud.com.neuralluna.lunahearth"
    private var invitations: [UUID: CKShare.Metadata] = [:]
    private var tickets: [UUID: (CKShare, SyncDestination)] = [:]

    private func ready(_ destination: SyncDestination? = nil) async throws -> (CKContainer, String) {
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing"),
              let team = Bundle.main.object(forInfoDictionaryKey: "CloudKitDevelopmentTeam") as? String,
              !team.isEmpty, !team.contains("$(") else { throw HouseholdSharingError.unavailable }
        let container = CKContainer(identifier: Self.containerIdentifier)
        guard try await container.accountStatus() == .available else { throw HouseholdSharingError.noAccount }
        let account = try await container.userRecordID().recordName
        if let destination, destination.accountID != account { throw HouseholdSharingError.accountChanged }
        return (container, account)
    }

    private func zoneID(_ destination: SyncDestination) throws -> CKRecordZone.ID {
        guard destination.zoneName == "LHHousehold-\(destination.householdID.uuidString)", !destination.ownerName.isEmpty else { throw HouseholdSharingError.invalidData }
        return CKRecordZone.ID(zoneName: destination.zoneName, ownerName: destination.ownerName)
    }
    private func database(_ container: CKContainer, _ destination: SyncDestination) -> CKDatabase {
        destination.isOwner ? container.privateCloudDatabase : container.sharedCloudDatabase
    }

    func deleteHome(in destination: SyncDestination) async throws {
        guard destination.isOwner, destination.ownerName == CKCurrentUserDefaultName else { throw HouseholdSharingError.readOnly }
        let (container, account) = try await ready(destination)
        let zone = try zoneID(destination)
        do { try await container.privateCloudDatabase.deleteRecordZone(withID: zone) }
        catch let error as CKError where error.code == .zoneNotFound || error.code == .unknownItem { /* Already deleted: safe retry. */ }
        guard try await container.userRecordID().recordName == account else { throw HouseholdSharingError.accountChanged }
        tickets = tickets.filter { $0.value.1 != destination }
    }

    func createHome(householdID: UUID) async throws -> SyncDestination {
        let (container, account) = try await ready()
        let id = CKRecordZone.ID(zoneName: "LHHousehold-\(householdID.uuidString)")
        // Zone creation is only performed by this explicit owner enable action.
        _ = try await container.privateCloudDatabase.save(CKRecordZone(zoneID: id))
        return SyncDestination(householdID: householdID, zoneName: id.zoneName, ownerName: id.ownerName, accountID: account, isOwner: true)
    }

    func availableHomes() async throws -> [CloudHome] {
        let (container, account) = try await ready()
        var homes: [CloudHome] = []
        for isOwner in [true, false] {
            let database = isOwner ? container.privateCloudDatabase : container.sharedCloudDatabase
            let zones = try await database.allRecordZones()
            for zone in zones.filter({ $0.zoneID.zoneName.hasPrefix("LHHousehold-") }).prefix(50) {
                guard let id = UUID(uuidString: String(zone.zoneID.zoneName.dropFirst("LHHousehold-".count))) else { continue }
                do {
                    let record = try await database.record(for: CKRecord.ID(recordName: id.uuidString, zoneID: zone.zoneID))
                    let value = try HouseholdCloudMapper.decode(record, householdID: id)
                    struct Title: Decodable { let name: String }
                    let title = try JSONDecoder().decode(Title.self, from: value.entity.record.payload).name
                    let destination = SyncDestination(householdID: id, zoneName: zone.zoneID.zoneName, ownerName: zone.zoneID.ownerName, accountID: account, isOwner: isOwner)
                    homes.append(CloudHome(destination: destination, name: title))
                } catch let error as CKError where error.code == .unknownItem || error.code == .zoneNotFound { continue }
            }
        }
        guard try await container.userRecordID().recordName == account else { throw HouseholdSharingError.accountChanged }
        return homes
    }

    func changes(in destination: SyncDestination, since token: Data?) async throws -> HouseholdChanges {
        let (container, account) = try await ready(destination)
        let database = database(container, destination), zone = try zoneID(destination)
        let writable: Bool
        if destination.isOwner { writable = true }
        else {
            guard let share = try await database.record(for: CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zone)) as? CKShare,
                  let participant = share.currentUserParticipant, participant.acceptanceStatus == .accepted else { throw HouseholdSharingError.accessLost }
            writable = participant.permission == .readWrite
        }
        var cursor = try token.map { try NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: $0) } ?? nil
        var reset = token == nil
        var records: [UUID: RemoteHouseholdRecord] = [:]
        var totalBytes = 0
        var pages = 0
        while true {
            try Task.checkCancellation()
            do {
                let result = try await database.recordZoneChanges(inZoneWith: zone, since: cursor, resultsLimit: 200)
                // The app uses tombstone records. Unexpected physical removal needs recovery,
                // never recreation of records from an obsolete local snapshot.
                guard result.deletions.allSatisfy({ $0.recordType == CKRecord.SystemType.share }) else { throw HouseholdSharingError.accessLost }
                for modification in result.modificationResultsByID.values {
                    let record = try modification.get().record
                    if record.recordType == CKRecord.SystemType.share { continue }
                    let value = try HouseholdCloudMapper.decode(record, householdID: destination.householdID)
                    totalBytes += value.entity.record.payload.count
                    records[value.entity.record.id] = value
                }
                pages += 1
                guard records.count <= 10_000, totalBytes <= 25_000_000, pages <= 100 else { throw HouseholdSharingError.invalidData }
                cursor = result.changeToken
                if !result.moreComing { break }
            } catch let error as CKError where error.code == .changeTokenExpired && !reset {
                cursor = nil; reset = true; records = [:]; totalBytes = 0; pages = 0
            }
        }
        guard let cursor, try await container.userRecordID().recordName == account else { throw HouseholdSharingError.accountChanged }
        let data = try NSKeyedArchiver.archivedData(withRootObject: cursor, requiringSecureCoding: true)
        return HouseholdChanges(records: Array(records.values), token: data, reset: reset, writable: writable)
    }

    func save(_ changes: [HouseholdSyncWrite], in destination: SyncDestination) async throws -> HouseholdWriteResult {
        if changes.isEmpty { return HouseholdWriteResult(saved: [], needsRetry: false) }
        let (container, account) = try await ready(destination)
        let database = database(container, destination), zone = try zoneID(destination)
        var saved: [RemoteHouseholdRecord] = []
        var needsRetry = false
        // Bounded batches remain optimistic; a rejected record never acknowledges its local edit.
        let byID = Dictionary(uniqueKeysWithValues: changes.map { ($0.entity.record.id, $0) })
        for values in BackupBatches.make(changes.map { $0.entity.record }) {
            try Task.checkCancellation()
            let batch = values.compactMap { byID[$0.id] }
            guard batch.reduce(0, { $0 + $1.entity.record.payload.count }) <= 4_000_000 else { throw HouseholdSharingError.invalidData }
            let records = try batch.map { try HouseholdCloudMapper.encode($0, zone: zone) }
            do {
                let results = try await database.modifyRecords(saving: records, deleting: [], savePolicy: .ifServerRecordUnchanged, atomically: true)
                for record in records {
                    guard let result = results.saveResults[record.recordID] else { needsRetry = true; continue }
                    switch result {
                    case .success(let value): saved.append(try HouseholdCloudMapper.decode(value, householdID: destination.householdID))
                    case .failure(let error):
                        if let ck = error as? CKError, ck.code == .serverRecordChanged || ck.code == .batchRequestFailed { needsRetry = true }
                        else { throw error }
                    }
                }
            } catch let error as CKError where error.code == .serverRecordChanged || error.code == .batchRequestFailed { needsRetry = true }
            if needsRetry { break }
        }
        guard try await container.userRecordID().recordName == account else { throw HouseholdSharingError.accountChanged }
        return HouseholdWriteResult(saved: saved, needsRetry: needsRetry)
    }

    func prepareShare(in destination: SyncDestination, title: String) async throws -> HouseholdShareTicket {
        let (container, _) = try await ready(destination)
        let database = database(container, destination), zone = try zoneID(destination)
        let share: CKShare
        do {
            guard let existing = try await database.record(for: CKRecord.ID(recordName: CKRecordNameZoneWideShare, zoneID: zone)) as? CKShare else { throw HouseholdSharingError.invalidData }
            share = existing
        } catch let error as CKError where error.code == .unknownItem && destination.isOwner {
            let newShare = CKShare(recordZoneID: zone)
            newShare.publicPermission = .none
            newShare[CKShare.SystemFieldKey.title] = title as NSString
            guard let saved = try await database.save(newShare) as? CKShare else { throw HouseholdSharingError.invalidData }
            share = saved
        }
        let ticket = HouseholdShareTicket(id: UUID())
        tickets = [ticket.id: (share, destination)]
        return ticket
    }

    func resolveRecipient(email: String, in destination: SyncDestination) async throws -> String {
        guard destination.isOwner else { throw HouseholdSharingError.readOnly }
        let (container, account) = try await ready(destination)
        let participant = try await container.shareParticipant(forEmailAddress: email.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let recipient = participant.userIdentity.userRecordID?.recordName,
              !recipient.isEmpty, recipient != account else { throw NamedInvitationError.recipientUnavailable }
        return recipient
    }

    func inviteRecipient(accountID: String, in destination: SyncDestination, title: String) async throws -> URL {
        guard destination.isOwner, accountID != destination.accountID else { throw HouseholdSharingError.readOnly }
        let ticket = try await prepareShare(in: destination, title: title)
        guard let (share, _) = tickets[ticket.id] else { throw HouseholdSharingError.notReady }
        let (container, _) = try await ready(destination)
        if !share.participants.contains(where: { $0.userIdentity.userRecordID?.recordName == accountID }) {
            let participant = try await container.shareParticipant(forUserRecordID: CKRecord.ID(recordName: accountID))
            participant.permission = .readWrite
            share.addParticipant(participant)
        }
        guard let saved = try await database(container, destination).save(share) as? CKShare,
              let url = saved.url else { throw HouseholdSharingError.notReady }
        tickets = [ticket.id: (saved, destination)]
        return url
    }

    func presentation(for ticket: HouseholdShareTicket) async throws -> (CKShare, CKContainer) {
        guard let (share, destination) = tickets[ticket.id] else { throw HouseholdSharingError.notReady }
        let (container, _) = try await ready(destination)
        return (share, container)
    }

    func invitation(for url: URL) async throws -> HouseholdInvitation {
        guard HouseholdInvitationLink.url(from: url.absoluteString) != nil else { throw HouseholdSharingError.invalidData }
        let (container, _) = try await ready()
        return try register(await container.shareMetadata(for: url))
    }

    func register(_ metadata: CKShare.Metadata) throws -> HouseholdInvitation {
        guard metadata.containerIdentifier == Self.containerIdentifier,
              metadata.share.recordID.zoneID.zoneName.hasPrefix("LHHousehold-"),
              UUID(uuidString: String(metadata.share.recordID.zoneID.zoneName.dropFirst("LHHousehold-".count))) != nil else { throw HouseholdSharingError.invalidData }
        let invitation = HouseholdInvitation(id: UUID(), title: metadata.share[CKShare.SystemFieldKey.title] as? String ?? "Shared home")
        invitations = [invitation.id: metadata]
        return invitation
    }

    func accept(_ invitation: HouseholdInvitation) async throws -> SyncDestination {
        guard let metadata = invitations[invitation.id] else { throw HouseholdSharingError.notReady }
        let (container, account) = try await ready()
        let accepted = try await container.accept(metadata)
        let zone = accepted.recordID.zoneID
        guard let home = UUID(uuidString: String(zone.zoneName.dropFirst("LHHousehold-".count))),
              try await container.userRecordID().recordName == account else { throw HouseholdSharingError.accountChanged }
        let owned = accepted.currentUserParticipant?.role == .owner
        return SyncDestination(householdID: home, zoneName: zone.zoneName, ownerName: owned ? CKCurrentUserDefaultName : zone.ownerName, accountID: account, isOwner: owned)
    }
}

enum HouseholdCloudMapper {
    static let recordType = "LHHouseholdEntity"
    private enum Key {
        static let payload = "payload", household = "householdID", kind = "entityKind"
        static let created = "createdAt", modified = "modifiedAt", version = "schemaVersion", deleted = "isDeleted"
    }
    static func decode(_ record: CKRecord, householdID: UUID) throws -> RemoteHouseholdRecord {
        guard record.recordType == recordType, let id = UUID(uuidString: record.recordID.recordName),
              record[Key.household] as? String == householdID.uuidString,
              record[Key.version] as? Int == 1, let kind = record[Key.kind] as? String,
              let created = record[Key.created] as? Date, let modified = record[Key.modified] as? Date,
              let deleted = record[Key.deleted] as? Int, deleted == 0 || deleted == 1,
              let payload = record[Key.payload] as? Data, payload.count <= 500_000 else { throw HouseholdSharingError.invalidData }
        let allowed = ["Household", "HouseholdMember", "FamilyEvent", "HouseholdTask", "GroceryItem", "InventoryItem", "HouseholdExpense", "PurchaseEntry", "ShoppingStore", "MealPlanEntry", "HomeFloor", "Room", "HomeAsset", "Warranty", "MaintenancePlan", "MaintenanceHistory"]
        guard allowed.contains(kind), deleted == 0 || ["HouseholdTask", "GroceryItem", "InventoryItem", "HouseholdExpense", "PurchaseEntry", "FamilyEvent", "MealPlanEntry"].contains(kind) else { throw HouseholdSharingError.invalidData }
        let archiver = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: archiver); archiver.finishEncoding()
        let value = BackupRecord(id: id, householdID: householdID, kind: kind, createdAt: created, modifiedAt: modified, payload: payload)
        return RemoteHouseholdRecord(entity: SyncEntity(record: value, deleted: deleted == 1), systemFields: archiver.encodedData)
    }
    static func encode(_ write: HouseholdSyncWrite, zone: CKRecordZone.ID) throws -> CKRecord {
        let value = write.entity.record
        let id = CKRecord.ID(recordName: value.id.uuidString, zoneID: zone)
        let record: CKRecord
        if let fields = write.systemFields {
            let decoder = try NSKeyedUnarchiver(forReadingFrom: fields)
            decoder.requiresSecureCoding = true
            guard let existing = CKRecord(coder: decoder), existing.recordID == id, existing.recordType == recordType else { throw HouseholdSharingError.invalidData }
            decoder.finishDecoding(); record = existing
        } else { record = CKRecord(recordType: recordType, recordID: id) }
        record[Key.payload] = value.payload as NSData
        record[Key.household] = value.householdID.uuidString as NSString
        record[Key.kind] = value.kind as NSString
        record[Key.created] = value.createdAt as NSDate
        record[Key.modified] = value.modifiedAt as NSDate
        record[Key.version] = 1 as NSNumber
        record[Key.deleted] = (write.entity.deleted ? 1 : 0) as NSNumber
        return record
    }
}

struct HouseholdSharingFailure {
    let message: String
    let recovery: Bool
    let retryAfter: TimeInterval
    init(_ error: Error) {
        if let layout = error as? LayoutError, case .overlap = layout {
            message = "Room layouts from the two devices overlap. Review the incoming rooms below, adjust your local layout, then sync again. Neither layout has been overwritten."
            recovery = false; retryAfter = 60
        } else if let known = error as? HouseholdSharingError {
            message = known.localizedDescription
            recovery = known == .accessLost || known == .accountChanged
            retryAfter = 60
        } else if let ck = error as? CKError {
            recovery = [.zoneNotFound, .userDeletedZone, .permissionFailure, .unknownItem].contains(ck.code)
            retryAfter = max(15, ck.retryAfterSeconds ?? 30)
            switch ck.code {
            case .quotaExceeded: message = "The owner’s iCloud storage is full. Changes are saved locally; free up iCloud space to resume sharing."
            case .notAuthenticated: message = HouseholdSharingError.noAccount.localizedDescription
            case .zoneNotFound, .userDeletedZone, .permissionFailure, .unknownItem: message = HouseholdSharingError.accessLost.localizedDescription
            case .networkFailure, .networkUnavailable: message = "Offline. Your edits are saved here and will sync when iCloud is available."
            case .serverRecordChanged, .batchRequestFailed, .partialFailure: message = "Changes arrived while syncing. Your edits are safe; sync will retry."
            default: message = "iCloud could not finish syncing. Your changes are saved on this device and will retry."
            }
        } else {
            message = "Could not safely finish syncing. Your local home is preserved. Try again."
            recovery = false; retryAfter = 30
        }
    }
}
