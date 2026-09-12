import CloudKit
import Foundation

/// Phase 2 implementation point for explicit CloudKit record-zone sharing.
/// Do not replace this with SwiftData automatic CloudKit mirroring without an ADR.
actor CloudKitSyncCoordinator {
    private let container: CKContainer

    init(containerIdentifier: String = "iCloud.com.neuralluna.lunahearth") {
        self.container = CKContainer(identifier: containerIdentifier)
    }

    func accountStatus() async throws -> CKAccountStatus {
        try await container.accountStatus()
    }
}
