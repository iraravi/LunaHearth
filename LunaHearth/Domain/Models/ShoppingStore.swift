import Foundation
import SwiftData
import CryptoKit

@Model final class ShoppingStore {
    @Attribute(.unique) var id: UUID
    var householdID: UUID
    var name: String
    var branch: String?
    var createdAt: Date
    var modifiedAt: Date

    init(id: UUID, householdID: UUID, name: String, branch: String? = nil, createdAt: Date = .now, modifiedAt: Date = .now) {
        self.id = id; self.householdID = householdID; self.name = name; self.branch = branch
        self.createdAt = createdAt; self.modifiedAt = modifiedAt
    }
    var displayName: String { Self.label(name: name, branch: branch) }
    static func label(name: String, branch: String?) -> String {
        guard let branch, !branch.isEmpty else { return name }
        return "\(name) · \(branch)"
    }
    /// Same normalized label in one household gets the same local UUID even offline
    /// on two devices. No server-generated ID or global/public store directory.
    static func stableID(householdID: UUID, label: String) -> UUID {
        var bytes = Array(SHA256.hash(data: Data("LunaHearth.store.v1|\(householdID.uuidString)|\(ShoppingStoreCatalog.key(label))".utf8)).prefix(16))
        bytes[6] = (bytes[6] & 0x0f) | 0x80
        bytes[8] = (bytes[8] & 0x3f) | 0x80
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7], bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
