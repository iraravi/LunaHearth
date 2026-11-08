import Foundation
import UIKit
import ImageIO
import Testing
@testable import LunaHearth

struct ReceiptImageTests {
    @MainActor @Test func compressedImagesAreBoundedAndIsolatedByHousehold() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let storage = LocalReceiptImages(root: root)
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2000, height: 3000)).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 2000, height: 3000))
        }
        let input = try #require(image.jpegData(compressionQuality: 1))
        let compressed = try await storage.compress(input)
        #expect(compressed.count <= 1_000_000)
        let source = try #require(CGImageSourceCreateWithData(compressed as CFData, nil))
        let properties = try #require(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
        #expect((properties[kCGImagePropertyPixelHeight as String] as? Int) == 1600)
        #expect(properties[kCGImagePropertyGPSDictionary as String] == nil)
        let home = UUID(), purchase = UUID()
        try await storage.save([compressed], home: home, purchase: purchase)
        #expect(try await storage.load(home: home, purchase: purchase) == [compressed])
        #expect(try await storage.load(home: UUID(), purchase: purchase).isEmpty)
        try await storage.remove(home: home, purchase: purchase)
        #expect(try await storage.load(home: home, purchase: purchase).isEmpty)
        try await storage.save([compressed], home: home, purchase: purchase)
        try await storage.removeAll()
        #expect(try await storage.load(home: home, purchase: purchase).isEmpty)
    }
    @Test func invalidAndOversizedInputsFailWithoutWriting() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let storage = LocalReceiptImages(root: root)
        await #expect(throws: ReceiptImportError.self) { try await storage.compress(Data([1, 2, 3])) }
        await #expect(throws: ReceiptImportError.self) { try await storage.save([Data(repeating: 1, count: 1_000_001)], home: UUID(), purchase: UUID()) }
        #expect(!FileManager.default.fileExists(atPath: root.path))
    }
    @MainActor @Test func meatCategoryOverridesWrongAIHint() {
        for name in ["Mutton", "PREMIUM MUTTON LEG", "Chicken breast", "Salmon", "Prawns", "Butter chicken"] {
            #expect(PantryVisualRules.category(name) == .meat)
            let item = InventoryItem(householdID: UUID(), name: name)
            #expect(InventoryShelf.category(item, hints: [name: .chilled]) == .meat)
        }
        #expect(PantryVisualRules.category("Goat milk") == .chilled)
        #expect(PantryVisualRules.category("Chicken eggs") == .chilled)
        #expect(PantryVisualRules.category("Chicken masala") == .spices)
    }
    @Test func corruptSavedImageIsRejectedInsteadOfShowingBlankPreview() async throws {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let storage = LocalReceiptImages(root: root), home = UUID(), purchase = UUID()
        await #expect(throws: ReceiptImportError.self) {
            try await storage.save([Data([1, 2, 3])], home: home, purchase: purchase)
        }
        #expect(!FileManager.default.fileExists(atPath: root.path))
        let directory = root.appending(path: home.uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for pages in [[Data()], [Data([1, 2, 3])]] {
            try PropertyListEncoder().encode(pages).write(to: directory.appending(path: purchase.uuidString + ".plist"))
            await #expect(throws: ReceiptImportError.self) { try await storage.load(home: home, purchase: purchase) }
        }
    }

    @Test func preparedMeatProductsDoNotBecomeRawMeat() {
        for name in ["Chicken stock", "Beef broth", "Chicken bouillon"] {
            #expect(PantryVisualRules.category(name) == .essentials)
        }
        for name in ["Chicken seasoning", "Mutton masala", "Beef rub"] {
            #expect(PantryVisualRules.category(name) == .spices)
        }
        for name in ["Vegan chicken", "Plant based mutton", "Chicken style pieces"] {
            #expect(PantryVisualRules.category(name) != .meat)
        }
        #expect(PantryVisualRules.category("Premium mutton leg") == .meat)
    }

}
