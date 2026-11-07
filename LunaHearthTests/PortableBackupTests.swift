import Foundation
import SwiftData
import Testing
@testable import LunaHearth

struct PortableBackupCryptoTests {
    @Test func independentPythonFixtureDecryptsWithUnicodePassword() async throws {
        let data = try #require(Data(base64Encoded: "TkxIQkswMDEAAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobAAknwNbdrdA2xmpB3ZiNjM033cdZoe2HT1+4dbTMy/KcMrpYBwI6iK0pisDDY30q4a7V5Q=="))
        let plaintext = try await BackupEncryption().decrypt(data, password: "Tamil தமிழ் backup")
        #expect(String(decoding: plaintext, as: UTF8.self) == "Portable backup interoperability")
    }

    @Test func randomEncryptionRoundTripsAndRejectsWrongPasswordOrTampering() async throws {
        let crypto = BackupEncryption()
        let source = Data("private household details".utf8)
        let first = try await crypto.encrypt(source, password: "correct long password")
        let second = try await crypto.encrypt(source, password: "correct long password")
        #expect(first != second)
        #expect(first.range(of: source) == nil)
        #expect(try await crypto.decrypt(first, password: "correct long password") == source)
        await #expect(throws: PortableBackupError.self) { try await crypto.decrypt(first, password: "wrong password") }
        for index in [8, 24, 40, first.count - 1] {
            var corrupt = first; corrupt[index] ^= 1
            await #expect(throws: PortableBackupError.self) { try await crypto.decrypt(corrupt, password: "correct long password") }
        }
        var unsupported = first; unsupported[7] = 50
        await #expect(throws: PortableBackupError.self) { try await crypto.decrypt(unsupported, password: "correct long password") }
        var rounds = first; rounds[36] = 255
        await #expect(throws: PortableBackupError.self) { try await crypto.decrypt(rounds, password: "correct long password") }
        await #expect(throws: PortableBackupError.self) { try await crypto.decrypt(Data(first.prefix(20)), password: "correct long password") }
        await #expect(throws: PortableBackupError.self) { try await crypto.encrypt(source, password: "short") }
    }
}

@MainActor struct PortableBackupTests {
    func repository() throws -> LocalHouseholdRepository {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.reload(); return repo
    }

    @Test func filesAndRecordsSurviveEncryptedExportRestoreWithoutCloud() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let bytes = Data("fictional receipt attachment".utf8)
        try bytes.write(to: root.appendingPathComponent("receipt.pdf"))
        try Data([1, 2, 3]).write(to: root.appendingPathComponent("scan.usdz"))
        let source = try repository()
        try source.createHousehold(name: "Test home", owner: "Alex", members: [], firstRoom: "Kitchen")
        let home = try #require(source.household)
        let doc = DocumentRecord(householdID: home.id, title: "Receipt", kind: .receipt, localRelativePath: "receipt.pdf")
        try source.commit {
            source.context.insert(doc)
            source.rooms.first?.roomPlanAssetPath = "scan.usdz"
        }
        #expect(throws: BackupError.self) { try source.makeBackup() } // Cloud behavior unchanged.
        let (records, metadata, sources) = try source.portableBackupSources()
        let storage = PortableBackupFiles(root: root)
        let files = try await storage.collect(sources)
        let payload = PortableBackup(formatVersion: 1, household: records, documents: metadata, files: files)
        try source.validatePortableBackup(payload)
        let crypto = BackupEncryption()
        let encrypted = try await crypto.encrypt(JSONEncoder().encode(payload), password: "a long private password")
        let restored = try JSONDecoder().decode(PortableBackup.self, from: await crypto.decrypt(encrypted, password: "a long private password"))
        let target = try repository()
        let directory = try await storage.install(restored.files)
        try target.restorePortableBackup(restored, directory: directory)
        #expect(target.household?.id == home.id)
        #expect(target.documents.first?.id == doc.id)
        #expect(target.documents.first?.sha256?.count == 64)
        let path = try #require(target.documents.first?.localRelativePath)
        #expect(try Data(contentsOf: root.appendingPathComponent(path)) == bytes)
        #expect(target.rooms.first?.roomPlanAssetPath?.hasSuffix(".usdz") == true)
        #expect(target.syncConfiguration == nil)
        #expect(throws: BackupError.self) { try target.restorePortableBackup(restored, directory: directory) }
        #expect(target.documents.count == 1)
    }

    @Test func incompleteAndUnsafeArchivesNeverMutateStore() throws {
        let source = try repository()
        try source.createHousehold(name: "Home", owner: "", members: [])
        let records = try source.makeBackup()
        let doc = PortableDocument(id: UUID(), assetID: nil, title: "Receipt", kind: "receipt", createdAt: .now, modifiedAt: .now)
        let target = try repository()
        let missing = PortableBackup(formatVersion: 1, household: records, documents: [doc], files: [])
        #expect(throws: PortableBackupError.self) { try target.restorePortableBackup(missing, directory: "restore-" + UUID().uuidString) }
        let file = PortableBackupFile(owner: .document, recordID: doc.id, filenameExtension: "../evil", bytes: Data())
        let unsafe = PortableBackup(formatVersion: 1, household: records, documents: [doc], files: [file])
        #expect(throws: PortableBackupError.self) { try target.validatePortableBackup(unsafe) }
        let duplicate = PortableBackup(formatVersion: 1, household: records, documents: [doc, doc], files: [file])
        #expect(throws: PortableBackupError.self) { try target.validatePortableBackup(duplicate) }
        #expect(target.household == nil)
        #expect(target.documents.isEmpty)
    }

    @Test func exportRejectsTraversalSymlinksAndMissingAttachments() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data([1]).write(to: root.appendingPathComponent("real"))
        try FileManager.default.createSymbolicLink(at: root.appendingPathComponent("link"), withDestinationURL: root.appendingPathComponent("real"))
        let large = root.appendingPathComponent("large")
        FileManager.default.createFile(atPath: large.path, contents: nil)
        let handle = try FileHandle(forWritingTo: large)
        try handle.truncate(atOffset: UInt64(BackupEncryption.maximumBytes + 1))
        try handle.close()
        let files = PortableBackupFiles(root: root)
        await #expect(throws: PortableBackupError.self) { try await files.readBackup(at: large) }
        for path in ["../outside", "/absolute", "link", "missing"] {
            await #expect(throws: (any Error).self) {
                try await files.collect([BackupFileSource(owner: .document, recordID: UUID(), relativePath: path)])
            }
        }
    }
}
