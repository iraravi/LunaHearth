import Foundation

/// Platform-neutral snapshot. Apple account identifiers and device permissions are excluded.
struct PortableBackup: Codable, Sendable {
    let formatVersion: Int
    let household: HouseholdBackup
    let documents: [PortableDocument]
    let files: [PortableBackupFile]
}

struct PortableDocument: Codable, Sendable {
    let id: UUID
    let assetID: UUID?
    let title: String
    let kind: String
    let createdAt: Date
    let modifiedAt: Date
}

struct PortableBackupFile: Codable, Sendable {
    enum Owner: String, Codable, Sendable { case document, roomScan }
    let owner: Owner
    let recordID: UUID
    let filenameExtension: String
    let bytes: Data
}

struct BackupFileSource: Sendable {
    let owner: PortableBackupFile.Owner
    let recordID: UUID
    let relativePath: String
}

protocol BackupEncryptionService: Sendable {
    func encrypt(_ plaintext: Data, password: String) async throws -> Data
    func decrypt(_ encrypted: Data, password: String) async throws -> Data
}

enum PortableBackupError: LocalizedError {
    case invalid, password, unlock, tooLarge, missingFile
    var errorDescription: String? {
        switch self {
        case .invalid: "This file is damaged or uses an unsupported backup format. Nothing was restored."
        case .password: "Use a password of at least 12 characters (up to 1,024 UTF-8 bytes). Keep it somewhere safe; it cannot be recovered."
        case .unlock: "The password is incorrect or the backup has been damaged. Nothing was restored."
        case .tooLarge: "This backup exceeds the current size limit. Nothing was exported or restored."
        case .missingFile: "A saved attachment is missing, inaccessible or invalid. No incomplete backup was exported."
        }
    }
}

protocol BackupFileService: Sendable {
    func collect(_ sources: [BackupFileSource]) async throws -> [PortableBackupFile]
    func readBackup(at url: URL) async throws -> Data
}
