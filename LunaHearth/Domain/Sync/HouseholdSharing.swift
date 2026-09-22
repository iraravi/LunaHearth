import Foundation

struct SyncDestination: Codable, Sendable, Equatable, Identifiable {
    var id: UUID { householdID }
    let householdID: UUID
    let zoneName: String
    let ownerName: String
    let accountID: String
    let isOwner: Bool
}

struct SyncEntity: Codable, Sendable, Equatable {
    let record: BackupRecord
    let deleted: Bool
    func hasSameContent(as other: Self?) -> Bool {
        guard let other else { return false }
        guard record.id == other.record.id, record.householdID == other.record.householdID,
              record.kind == other.record.kind else { return false }
        // CloudKit date fields can have lower precision than the payload's dates.
        // Canonical per-entity payloads determine equality, avoiding endless reuploads.
        return deleted && other.deleted || (deleted == other.deleted && record.payload == other.record.payload)
    }
    static func tombstone(_ record: BackupRecord, now: Date) -> Self {
        Self(record: BackupRecord(id: record.id, householdID: record.householdID, kind: record.kind,
                                  createdAt: record.createdAt, modifiedAt: now, payload: Data()), deleted: true)
    }
}

struct RemoteHouseholdRecord: Codable, Sendable, Equatable {
    let entity: SyncEntity
    let systemFields: Data
}
struct HouseholdChanges: Sendable {
    let records: [RemoteHouseholdRecord]
    let token: Data
    let reset: Bool
    let writable: Bool
}
struct HouseholdSyncWrite: Sendable {
    let entity: SyncEntity
    let systemFields: Data?
}
struct HouseholdWriteResult: Sendable {
    let saved: [RemoteHouseholdRecord]
    let needsRetry: Bool
}
struct CloudHome: Sendable, Identifiable {
    var id: UUID { destination.householdID }
    let destination: SyncDestination
    let name: String
}
struct HouseholdInvitation: Identifiable, Sendable {
    let id: UUID
    let title: String
}
struct HouseholdShareTicket: Identifiable, Sendable { let id: UUID }

protocol HouseholdSharingService: Sendable {
    var linksCurrentMemberAutomatically: Bool { get }
    func deleteHome(in destination: SyncDestination) async throws
    func createHome(householdID: UUID) async throws -> SyncDestination
    func availableHomes() async throws -> [CloudHome]
    func changes(in destination: SyncDestination, since token: Data?) async throws -> HouseholdChanges
    func save(_ changes: [HouseholdSyncWrite], in destination: SyncDestination) async throws -> HouseholdWriteResult
    func prepareShare(in destination: SyncDestination, title: String) async throws -> HouseholdShareTicket
    func accept(_ invitation: HouseholdInvitation) async throws -> SyncDestination
}

enum HouseholdSharingError: LocalizedError, Sendable, Equatable {
    case unavailable, noAccount, accountChanged, accessLost, invalidData, readOnly, conflicts, notReady, resetBlocked
    var errorDescription: String? {
        switch self {
        case .unavailable: "iCloud sharing is unavailable in this build. Your local home is safe."
        case .noAccount: "iCloud is unavailable. Sign in to iCloud in Settings. Changes remain saved on this device."
        case .accountChanged: "The iCloud account changed. This home is in recovery mode; sign in with its original account to reconnect."
        case .accessLost: "Access to this shared home is unavailable. Its local data is preserved in recovery mode."
        case .invalidData: "The shared changes could not be safely read. Nothing on this device was replaced. Try syncing again."
        case .readOnly: "This home is read only. Your existing data and any unsynced edits are preserved."
        case .conflicts: "Review changes made on both devices before syncing continues."
        case .notReady: "Finish syncing this home before inviting people."
        case .resetBlocked: "A home with iCloud sharing cannot be reset here. Its local recovery data must be preserved."
        }
    }
}

/// Three-way record merge: independent records merge automatically; simultaneous edits
/// to the same record are reviewed. Completion/reopen and critical asset fields cannot be lost silently.
enum HouseholdSyncMerge {
    struct Plan: Sendable {
        var apply: [SyncEntity] = []
        var upload: [HouseholdSyncWrite] = []
        var conflicts: Set<UUID> = []
    }
    static func plan(local: [BackupRecord], baseline: [RemoteHouseholdRecord], remote: [RemoteHouseholdRecord], now: Date = .now) -> Plan {
        let localByID = Dictionary(uniqueKeysWithValues: local.map { ($0.id, SyncEntity(record: $0, deleted: false)) })
        let baseByID = Dictionary(uniqueKeysWithValues: baseline.map { ($0.entity.record.id, $0) })
        let remoteByID = Dictionary(uniqueKeysWithValues: remote.map { ($0.entity.record.id, $0) })
        var plan = Plan()
        for id in Set(localByID.keys).union(baseByID.keys).union(remoteByID.keys) {
            let base = baseByID[id]?.entity
            let cloud = remoteByID[id]
            let localValue = localByID[id] ?? base.map { SyncEntity.tombstone($0.record, now: now) }
            let localChanged = localValue.map { !$0.hasSameContent(as: base) } ?? false
            let remoteChanged = cloud.map { !$0.entity.hasSameContent(as: base) } ?? false
            if let localValue, let cloud, localValue.hasSameContent(as: cloud.entity) { continue }
            if localChanged && remoteChanged { plan.conflicts.insert(id) }
            else if remoteChanged, let cloud { plan.apply.append(cloud.entity) }
            else if localChanged, let localValue { plan.upload.append(HouseholdSyncWrite(entity: localValue, systemFields: cloud?.systemFields)) }
        }
        return plan
    }
}

extension HouseholdSharingService {
    var linksCurrentMemberAutomatically: Bool { false }
}
