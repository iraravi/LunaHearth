#if DEBUG
import Foundation

/// Isolated UI-test fixture. It never accesses EventKit or a real account.
actor UITestPlanningService: ApplePlanningService, ReminderDeliveryService {
    private var standardLists: [String: ApplePlanningSource] = [:]
    private var items: [UUID: AppleReminder] = [:]
    func requestAccess(_ access: PlanningAccess) {}
    func sources(_ access: PlanningAccess) -> [ApplePlanningSource] {
        access == .reminders ? [ApplePlanningSource(id: "test-list", title: "Test household", account: "Test account", writable: true)] + Array(standardLists.values) : []
    }
    func createStandardReminderList(usingListID: String, title: String) -> ApplePlanningSource {
        let list = ApplePlanningSource(id: title, title: title, account: "Test account", writable: true)
        standardLists[title] = list
        return list
    }
    func events(in interval: DateInterval, calendarIDs: Set<String>) -> [AppleCalendarEvent] { [] }
    func reminders(listIDs: Set<String>, includeCompleted: Bool) -> [AppleReminder] {
        items.values.filter { listIDs.contains($0.listID) && (includeCompleted || !$0.completed) }
    }
    func setCompleted(_ reminder: AppleReminder, completed: Bool) {
        guard let id = UUID(uuidString: reminder.id) else { return }
        items[id] = AppleReminder(id: reminder.id, listID: reminder.listID, title: reminder.title, due: reminder.due, completed: completed, notes: reminder.notes)
    }
    func createReminder(_ draft: ReminderExportDraft, listID: String) {
        items[draft.id] = AppleReminder(id: draft.id.uuidString, listID: listID, title: draft.title, due: draft.due, completed: false, notes: draft.notes)
    }
    func deliver(_ job: ReminderDeliveryJob) -> String {
        let id = job.taskID.uuidString
        items[job.taskID] = AppleReminder(id: id, listID: job.listID, title: job.title, due: job.due, completed: job.completed)
        return id
    }
}
#endif
