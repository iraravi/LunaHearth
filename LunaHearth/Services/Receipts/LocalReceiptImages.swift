import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Local-only sidecars. No startup scan, CloudKit upload, or SwiftData image blobs.
actor LocalReceiptImages: ReceiptImageStorage {
    private let root: URL
    init(root: URL = URL.applicationSupportDirectory.appending(path: "ReceiptImages")) { self.root = root }
    func compress(_ data: Data) throws -> Data {
        try Task.checkCancellation()
        guard data.count <= 20_000_000,
              let source = CGImageSourceCreateWithData(data as CFData, [kCGImageSourceShouldCache: false] as CFDictionary),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1600
              ] as CFDictionary) else { throw ReceiptImportError.unreadable }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil) else { throw ReceiptImportError.unreadable }
        // A fresh JPEG omits source metadata such as GPS coordinates.
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.65] as CFDictionary)
        guard CGImageDestinationFinalize(destination), output.length <= 1_000_000 else { throw ReceiptImportError.tooLarge }
        return output as Data
    }
    private func url(home: UUID, purchase: UUID) -> URL {
        root.appending(path: home.uuidString, directoryHint: .isDirectory).appending(path: purchase.uuidString + ".plist")
    }
    func save(_ pages: [Data], home: UUID, purchase: UUID) throws {
        guard (1...4).contains(pages.count), pages.allSatisfy({ !$0.isEmpty && $0.count <= 1_000_000 }) else { throw ReceiptImportError.tooLarge }
        let target = url(home: home, purchase: purchase)
        try FileManager.default.createDirectory(at: target.deletingLastPathComponent(), withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication])
        let encoder = PropertyListEncoder(); encoder.outputFormat = .binary
        try encoder.encode(pages).write(to: target, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
    func load(home: UUID, purchase: UUID) throws -> [Data] {
        let target = url(home: home, purchase: purchase)
        guard FileManager.default.fileExists(atPath: target.path) else { return [] }
        let values = try target.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        guard values.isRegularFile == true, let size = values.fileSize, size <= 4_100_000 else { throw ReceiptImportError.tooLarge }
        let pages = try PropertyListDecoder().decode([Data].self, from: Data(contentsOf: target))
        guard (1...4).contains(pages.count), pages.allSatisfy({ $0.count <= 1_000_000 }) else { throw ReceiptImportError.tooLarge }
        return pages
    }
    func removeAll() throws {
        if FileManager.default.fileExists(atPath: root.path) { try FileManager.default.removeItem(at: root) }
    }
    func remove(home: UUID, purchase: UUID) throws {
        let target = url(home: home, purchase: purchase)
        if FileManager.default.fileExists(atPath: target.path) { try FileManager.default.removeItem(at: target) }
    }
}
