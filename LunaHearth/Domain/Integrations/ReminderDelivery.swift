import Foundation

/// One-way delivery of an explicitly enrolled household task. No permission prompts here.
protocol ReminderDeliveryService: Sendable {
    func deliver(_ job: ReminderDeliveryJob) async throws -> String
}

struct ReminderDeliveryJob: Sendable {
    let taskID: UUID
    let listID: String
    let externalID: String?
    let title: String
    let due: Date?
    let completed: Bool
    let revision: Date
    var draft: ReminderExportDraft { ReminderExportDraft(id: taskID, title: title, due: due) }
}

enum ReminderDeliveryError: LocalizedError {
    case missingReminder, ambiguous, readFailed
    var errorDescription: String? {
        switch self {
        case .missingReminder: "The linked reminder was removed, moved, or its task link changed. Restore it in the original Apple list, or stop syncing this task."
        case .ambiguous: "More than one reminder has this task link. Keep one in the destination list, then retry."
        case .readFailed: "Apple Reminders could not be read. Your task is saved locally. Try again later."
        }
    }
}
