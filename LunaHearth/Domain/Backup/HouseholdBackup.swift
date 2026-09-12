import Foundation

struct BackupRecord: Codable, Sendable, Equatable {
    let id: UUID
    let householdID: UUID
    let kind: String
    let createdAt: Date
    let modifiedAt: Date
    let payload: Data
}

struct HouseholdBackup: Codable, Sendable {
    let version: Int
    let householdID: UUID
    let name: String
    let savedAt: Date
    let records: [BackupRecord]

    func validateEnvelope() throws {
        guard version == 1, !records.isEmpty, records.count <= 10_000,
              Set(records.map(\.id)).count == records.count,
              records.reduce(0, { $0 + $1.payload.count }) <= 25_000_000,
              records.allSatisfy({ $0.householdID == householdID && $0.payload.count <= 500_000 }),
              records.filter({ $0.kind == "Household" && $0.id == householdID }).count == 1
        else { throw BackupError.invalidBackup }
    }
}

protocol HouseholdBackupService: Sendable {
    func upload(_ backup: HouseholdBackup) async throws
    func download() async throws -> HouseholdBackup
}

enum BackupError: LocalizedError {
    case unavailable, noAccount, noBackup, invalidBackup, existingHome, attachmentsUnsupported, accountChanged
    var errorDescription: String? {
        switch self {
        case .unavailable: "iCloud is unavailable in this build. Your home remains saved on this device."
        case .noAccount: "Sign in to iCloud in Settings, then try again. Your local home is safe."
        case .noBackup: "No LunaHearth backup was found in this Apple Account."
        case .invalidBackup: "This backup is incomplete, too large, or uses an unsupported format. Nothing was restored."
        case .existingHome: "Restore is available before creating a home. Your existing home has not been replaced."
        case .attachmentsUnsupported: "This version cannot back up document or room-scan files. No backup was uploaded."
        case .accountChanged: "Your iCloud account changed. Please try again with the intended Apple Account."
        }
    }
}

/// Stay comfortably below CloudKit operation limits, including record metadata.
enum BackupBatches {
    static func make(_ records: [BackupRecord]) -> [[BackupRecord]] {
        var batches: [[BackupRecord]] = []
        var batch: [BackupRecord] = []
        var bytes = 0
        for record in records {
            if !batch.isEmpty && (batch.count == 100 || bytes + record.payload.count > 4_000_000) {
                batches.append(batch); batch = []; bytes = 0
            }
            batch.append(record); bytes += record.payload.count
        }
        if !batch.isEmpty { batches.append(batch) }
        return batches
    }
}
