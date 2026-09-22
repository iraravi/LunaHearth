import Foundation

extension LocalHouseholdRepository {
    /// ADR-011: preserve past delivery metadata, but never resume automatic Apple writes.
    func retireAutomaticReminderDelivery() throws {
        guard let settings = reminderDeliverySettings, settings.enabled else { return }
        try commit(allowReadOnly: true) { settings.enabled = false }
    }

    func configureReminderDelivery(enabled: Bool, listID: String) throws {
        guard let household, !enabled || !listID.isEmpty else { throw HouseholdValidation.invalidReference }
        try commit {
            if let settings = reminderDeliverySettings {
                settings.enabled = enabled; settings.listID = listID
            } else {
                context.insert(ReminderDeliverySettings(householdID: household.id, enabled: enabled, listID: listID))
            }
        }
    }

    func pendingReminderJobs(now: Date = .now, force: Bool = false) -> [ReminderDeliveryJob] {
        guard reminderDeliverySettings?.enabled == true else { return [] }
        return reminderDeliveryLinks.compactMap { link in
            guard let task = tasks.first(where: { $0.id == link.taskID }), task.modifiedAt != link.sentRevision else { return nil }
            if !force, link.attemptedRevision == task.modifiedAt,
               let attemptedAt = link.attemptedAt, now.timeIntervalSince(attemptedAt) < 60 { return nil }
            return ReminderDeliveryJob(taskID: task.id, listID: link.listID, externalID: link.externalID,
                                       title: task.title, due: task.dueAt, completed: task.isCompleted, revision: task.modifiedAt)
        }
    }

    func recordReminderDelivery(_ job: ReminderDeliveryJob, externalID: String?, error: String?, now: Date = .now) throws {
        guard let link = reminderDeliveryLinks.first(where: { $0.taskID == job.taskID && $0.listID == job.listID }) else { return }
        try commit(notifyDelivery: false) {
            link.attemptedRevision = job.revision; link.attemptedAt = now; link.error = error
            if let externalID { link.externalID = externalID; link.sentRevision = job.revision }
        }
    }

    func stopReminderDelivery(taskID: UUID) throws {
        try commit {
            for link in reminderDeliveryLinks where link.taskID == taskID { context.delete(link) }
        }
    }

    func reminderDeliveryStatus(taskID: UUID) -> String? {
        guard let link = reminderDeliveryLinks.first(where: { $0.taskID == taskID }),
              let task = tasks.first(where: { $0.id == taskID }) else { return nil }
        if reminderDeliverySettings?.enabled != true { return "Apple Reminders sync paused" }
        if let error = link.error { return error }
        return link.sentRevision == task.modifiedAt ? "Sent to Apple Reminders" : "Saved locally · waiting for Apple Reminders"
    }
}
