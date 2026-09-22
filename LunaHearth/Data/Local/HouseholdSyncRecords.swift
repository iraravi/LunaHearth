import Foundation
import SwiftData

@Model final class HouseholdSyncConfiguration {
    @Attribute(.unique) var householdID: UUID
    var zoneName: String
    var ownerName: String
    var accountID: String
    var isOwner: Bool
    var enabled: Bool
    var readOnly: Bool
    var recovery: Bool
    var changeToken: Data?
    var lastSyncedAt: Date?
    init(_ destination: SyncDestination) {
        householdID = destination.householdID; zoneName = destination.zoneName
        ownerName = destination.ownerName; accountID = destination.accountID; isOwner = destination.isOwner
        enabled = true; readOnly = false; recovery = false
    }
    var destination: SyncDestination {
        SyncDestination(householdID: householdID, zoneName: zoneName, ownerName: ownerName, accountID: accountID, isOwner: isOwner)
    }
}

/// One durable baseline per entity. Local differences, including deletions, remain
/// pending across relaunch without depending on an in-memory queue.
@Model final class HouseholdSyncBaseline {
    @Attribute(.unique) var entityID: UUID
    var householdID: UUID
    var remoteData: Data
    var conflict: Bool
    init(entityID: UUID, householdID: UUID, remoteData: Data, conflict: Bool = false) {
        self.entityID = entityID; self.householdID = householdID
        self.remoteData = remoteData; self.conflict = conflict
    }
}

@Model final class ActiveHouseholdSelection {
    @Attribute(.unique) var key: String
    var householdID: UUID
    init(householdID: UUID) { key = "active"; self.householdID = householdID }
}
