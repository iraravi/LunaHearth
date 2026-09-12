import Foundation

actor DocumentStorageService {
    enum StorageError: Error { case applicationSupportUnavailable }

    func documentsDirectory() throws -> URL {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw StorageError.applicationSupportUnavailable
        }
        let url = base.appending(path: "LunaHearthDocuments", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
