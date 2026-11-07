import Foundation

actor PortableBackupFiles: BackupFileService {
    private let root: URL
    static let attachmentLimit = 32_000_000

    init(root: URL? = nil) {
        self.root = root ?? URL.applicationSupportDirectory.appending(path: "LunaHearthDocuments", directoryHint: .isDirectory)
    }

    func collect(_ sources: [BackupFileSource]) throws -> [PortableBackupFile] {
        var total = 0
        return try sources.map { source in
            let parts = source.relativePath.split(separator: "/", omittingEmptySubsequences: false)
            guard !parts.isEmpty, parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." }),
                  !source.relativePath.contains("\\") else { throw PortableBackupError.missingFile }
            var url = root
            // Reject symlinks at every component rather than trusting imported/local path text.
            for part in parts {
                url.appendPathComponent(String(part))
                guard try url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else { throw PortableBackupError.missingFile }
            }
            let data = try readBounded(url, limit: Self.attachmentLimit - total)
            total += data.count
            return PortableBackupFile(owner: source.owner, recordID: source.recordID, filenameExtension: url.pathExtension.isEmpty ? "bin" : url.pathExtension, bytes: data)
        }
    }

    func readBackup(at url: URL) throws -> Data {
        let granted = url.startAccessingSecurityScopedResource()
        defer { if granted { url.stopAccessingSecurityScopedResource() } }
        return try readBounded(url, limit: BackupEncryption.maximumBytes)
    }

    private func readBounded(_ url: URL, limit: Int) throws -> Data {
        let metadata = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard limit >= 0, metadata.isRegularFile == true else { throw PortableBackupError.missingFile }
        guard let size = metadata.fileSize, size <= limit else { throw PortableBackupError.tooLarge }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        var result = Data()
        while let chunk = try handle.read(upToCount: min(65_536, limit - result.count + 1)), !chunk.isEmpty {
            guard chunk.count <= limit - result.count else { throw PortableBackupError.tooLarge }
            result.append(chunk)
        }
        return result
    }

    /// New random directory; imported names are never used as file paths.
    func install(_ files: [PortableBackupFile]) throws -> String {
        let name = "restore-" + UUID().uuidString
        let directory = root.appendingPathComponent(name, isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true,
                attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
            for file in files {
                try file.bytes.write(to: directory.appendingPathComponent(Self.filename(file)), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
            }
            return name
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    func discardInstallation(_ name: String) throws {
        guard name.hasPrefix("restore-"), UUID(uuidString: String(name.dropFirst(8))) != nil else { throw PortableBackupError.invalid }
        try FileManager.default.removeItem(at: root.appendingPathComponent(name, isDirectory: true))
    }

    nonisolated static func filename(_ file: PortableBackupFile) -> String {
        file.owner.rawValue + "-" + file.recordID.uuidString + "." + file.filenameExtension
    }
}
