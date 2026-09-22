import Foundation
import SwiftData

/// Device-local opt-in; excluded from household backup and sharing.
@Model final class ReminderDeliverySettings {
    @Attribute(.unique) var householdID: UUID
    var enabled: Bool
    var listID: String
    init(householdID: UUID, enabled: Bool, listID: String) {
        self.householdID = householdID; self.enabled = enabled; self.listID = listID
    }
}

/// Durable outbox link. The task remains the source of truth for pending content.
@Model final class ReminderDeliveryLink {
    @Attribute(.unique) var taskID: UUID
    var householdID: UUID
    var listID: String
    var externalID: String?
    var sentRevision: Date?
    var attemptedRevision: Date?
    var attemptedAt: Date?
    var error: String?
    init(taskID: UUID, householdID: UUID, listID: String) {
        self.taskID = taskID; self.householdID = householdID; self.listID = listID
    }
}
