import CryptoKit
import Foundation

/// A household-scoped profile ID, not an authentication credential.
enum SharedMemberIdentity {
    static func memberID(householdID: UUID, accountID: String) -> UUID {
        let bytes = Array(SHA256.hash(data: Data("LunaHearth.member.v1|\(householdID.uuidString)|\(accountID)".utf8)).prefix(16))
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5],
                           (bytes[6] & 0x0f) | 0x50, bytes[7], (bytes[8] & 0x3f) | 0x80,
                           bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}

protocol NamedHouseholdInvitationService: Sendable {
    func resolveRecipient(email: String, in destination: SyncDestination) async throws -> String
    func inviteRecipient(accountID: String, in destination: SyncDestination, title: String) async throws -> URL
}

enum NamedInvitationError: LocalizedError {
    case recipientUnavailable
    var errorDescription: String? {
        "Use the email signed into iCloud on the other person’s device. This address could not be linked to a different iCloud account."
    }
}
