import Foundation
import UserNotifications

actor MealPrepReminder: MealPrepReminderService {
    /// "Mark done" and "Snooze" buttons on the reminder; they also appear on Apple Watch.
    static let category = "meal.prep"
    static let doneAction = "meal.prep.done"
    static let snoozeAction = "meal.prep.snooze"
    static let snoozeMinutes = 10
    /// A snoozed reminder keeps the task's identifier with this suffix.
    static let snoozedSuffix = ".snoozed"

    static var notificationCategory: UNNotificationCategory {
        UNNotificationCategory(identifier: category, actions: [
            UNNotificationAction(identifier: doneAction, title: "Mark done", options: [], icon: UNNotificationActionIcon(systemImageName: "checkmark")),
            UNNotificationAction(identifier: snoozeAction, title: "Snooze \(snoozeMinutes) min", options: [], icon: UNNotificationActionIcon(systemImageName: "clock"))
        ], intentIdentifiers: [])
    }

    /// The task ID inside a reminder identifier, snoozed or not.
    static func taskID(in identifier: String) -> UUID? {
        let base = identifier.hasSuffix(snoozedSuffix) ? String(identifier.dropLast(snoozedSuffix.count)) : identifier
        return base.split(separator: ".").last.flatMap { UUID(uuidString: String($0)) }
    }

    /// Shows the same reminder again in a few minutes.
    static func snooze(_ identifier: String) async {
        let base = identifier.hasSuffix(snoozedSuffix) ? String(identifier.dropLast(snoozedSuffix.count)) : identifier
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(
            identifier: base + snoozedSuffix, content: content(),
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(snoozeMinutes * 60), repeats: false)))
    }

    private static func content() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent(); content.title = "Time for meal preparation"; content.body = "Open Nam Illam to see your preparation tasks."
        content.sound = .default; content.categoryIdentifier = category
        return content
    }

    private func key(_ home: UUID, _ id: UUID) -> String { "meal.prep.\(home).\(id)" }
    func schedule(id: UUID, householdID: UUID, due: Date) async throws {
        let center = UNUserNotificationCenter.current()
        guard try await center.requestAuthorization(options: [.alert, .sound]) else { throw PrepError.denied }
        try await post(identifier: key(householdID, id), due: due)
    }
    private func post(identifier: String, due: Date) async throws {
        guard due > .now else { return }
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, due.timeIntervalSinceNow), repeats: false)
        try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: Self.content(), trigger: trigger))
    }
    func reconcile(householdID: UUID, tasks: [MealPrepReminderInput]) async {
        let center = UNUserNotificationCenter.current()
        let prefix = "meal.prep.\(householdID)."
        let pending = await center.pendingNotificationRequests()
        let delivered = await center.deliveredNotifications()
        for identifier in Set(pending.map(\.identifier) + delivered.map { $0.request.identifier }) where identifier.hasPrefix(prefix) {
            let snoozed = identifier.hasSuffix(Self.snoozedSuffix)
            let base = snoozed ? String(identifier.dropLast(Self.snoozedSuffix.count)) : identifier
            guard let task = tasks.first(where: { key(householdID, $0.id) == base }), !task.completed, let due = task.due else {
                center.removePendingNotificationRequests(withIdentifiers: [identifier]); center.removeDeliveredNotifications(withIdentifiers: [identifier]); continue
            }
            // A snoozed reminder keeps its own time.
            if snoozed { continue }
            if let request = pending.first(where: { $0.identifier == identifier }),
               let scheduled = (request.trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate(), abs(scheduled.timeIntervalSince(due)) > 2 {
                center.removePendingNotificationRequests(withIdentifiers: [identifier]); try? await post(identifier: identifier, due: due)
            }
        }
    }
    private enum PrepError: LocalizedError { case denied; var errorDescription: String? { "Preparation task saved. Notifications are off; enable them in Settings to receive an alert on this device." } }
}
