import Foundation
import UserNotifications

actor SystemAppointmentAlerts: AppointmentAlertService {
    func requestPermission() async throws -> Bool { try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) }
    func replace(_ alerts: [AppointmentAlert]) async throws {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let prefix = "appointment."
        let capacity = max(0, min(24, 60 - pending.filter { !$0.identifier.hasPrefix(prefix) }.count))
        let desired = Array(alerts.filter { $0.date > .now }.sorted { $0.date < $1.date }.prefix(capacity))
        func key(_ alert: AppointmentAlert) -> String { "appointment.\(alert.householdID).\(alert.id)" }
        let keys = Set(desired.map(key))
        let validKeys = Set(alerts.map(key))
        let removed = pending.filter { $0.identifier.hasPrefix(prefix) && !keys.contains($0.identifier) }.map(\.identifier)
        center.removePendingNotificationRequests(withIdentifiers: removed)
        let delivered = await center.deliveredNotifications()
        center.removeDeliveredNotifications(withIdentifiers: delivered.filter { $0.request.identifier.hasPrefix(prefix) && !validKeys.contains($0.request.identifier) }.map { $0.request.identifier })
        for alert in desired {
            if let request = pending.first(where: { $0.identifier == key(alert) }), let trigger = request.trigger as? UNCalendarNotificationTrigger,
               let date = trigger.nextTriggerDate(), abs(date.timeIntervalSince(alert.date)) < 1 { continue }
            let content = UNMutableNotificationContent()
            content.title = "Upcoming family appointment"
            content.body = "Open LunaHearth to see the details."
            content.sound = .default
            content.userInfo = ["appointmentID": alert.id.uuidString, "householdID": alert.householdID.uuidString]
            var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: alert.date)
            components.timeZone = calendar.timeZone
            try await center.add(UNNotificationRequest(identifier: key(alert), content: content, trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)))
        }
    }
}
