import Foundation
import Observation

@MainActor @Observable
final class AppleConnections {
    private let service: any ApplePlanningService
    private let defaults: UserDefaults
    private(set) var calendarEnabled: Bool
    private(set) var remindersEnabled: Bool
    private(set) var calendarSources: [ApplePlanningSource] = []
    private(set) var reminderSources: [ApplePlanningSource] = []
    private(set) var calendarChoices: [String: CalendarPrivacy]
    private(set) var reminderChoices: Set<String>
    private(set) var shoppingListID: String?
    private(set) var shopping: [AppleReminder] = []
    private var shoppingRequest = UUID()
    private(set) var events: [AppleCalendarEvent] = []
    private(set) var reminders: [AppleReminder] = []
    private(set) var revision = 0
    private(set) var working = false
    private(set) var calendarError: String?
    private(set) var remindersError: String?
    private var eventRequest = UUID()
    private var reminderRequest = UUID()

    init(service: any ApplePlanningService = CalendarIntegrationService(), defaults: UserDefaults = .standard) {
        self.service = service; self.defaults = defaults
        calendarEnabled = defaults.bool(forKey: "apple.calendar.enabled")
        remindersEnabled = defaults.bool(forKey: "apple.reminders.enabled")
        calendarChoices = (defaults.dictionary(forKey: "apple.calendar.choices") as? [String: String] ?? [:]).compactMapValues(CalendarPrivacy.init(rawValue:))
        shoppingListID = defaults.string(forKey: "apple.shopping.list")
        reminderChoices = Set((defaults.stringArray(forKey: "apple.reminders.choices") ?? []).sorted().prefix(1))
    }
    func connect(_ access: PlanningAccess) async {
        guard !working else { return }
        working = true
        defer { working = false }
        do {
            try await service.requestAccess(access)
            if access == .calendar { calendarEnabled = true } else { remindersEnabled = true }
            persist()
            await refreshSources(access)
        } catch { fail(access, error) }
    }
    func disconnect(_ access: PlanningAccess) {
        if access == .calendar {
            calendarEnabled = false; calendarChoices = [:]; calendarSources = []; events = []; calendarError = nil
            eventRequest = UUID()
        } else {
            remindersEnabled = false; reminderChoices = []; reminderSources = []; reminders = []; shopping = []; shoppingListID = nil; shoppingRequest = UUID(); remindersError = nil
            reminderRequest = UUID()
        }
        persist()
    }
    func chooseCalendar(_ id: String, privacy: CalendarPrivacy) {
        calendarChoices[id] = privacy; events = []; eventRequest = UUID(); persist()
    }
    func chooseReminderList(_ id: String, enabled: Bool) {
        if enabled { reminderChoices.insert(id) } else { reminderChoices.remove(id) }
        reminders = []; reminderRequest = UUID(); persist()
    }
    var activeReminderList: ApplePlanningSource? {
        reminderSources.first { reminderChoices.contains($0.id) }
    }
    func list(for purpose: ReminderPurpose) -> ApplePlanningSource? {
        purpose == .reminders ? activeReminderList : reminderSources.first { $0.id == shoppingListID }
    }
    func items(for purpose: ReminderPurpose) -> [AppleReminder] { purpose == .shopping ? shopping : reminders }
    func selectReminderList(_ id: String, for purpose: ReminderPurpose = .reminders) {
        if purpose == .reminders { reminderChoices = [id]; reminders = []; reminderRequest = UUID() }
        else { shoppingListID = id; shopping = []; shoppingRequest = UUID() }
        persist()
    }
    func createStandardList(usingListID: String, for purpose: ReminderPurpose = .reminders) async throws {
        guard remindersEnabled, reminderSources.contains(where: { $0.id == usingListID && $0.writable }) else { throw ApplePlanningError.missingSource }
        let list = try await service.createStandardReminderList(usingListID: usingListID, title: purpose.standardTitle)
        if !reminderSources.contains(where: { $0.id == list.id }) { reminderSources.append(list) }
        selectReminderList(list.id, for: purpose)
    }
    func refreshSources(_ access: PlanningAccess) async {
        guard access == .calendar ? calendarEnabled : remindersEnabled else { return }
        let initialRevision = revision
        do {
            let values = try await service.sources(access)
            guard revision == initialRevision else { return }
            if access == .calendar { calendarSources = values; calendarError = nil }
            else { reminderSources = values; remindersError = nil }
        } catch {
            guard revision == initialRevision else { return }
            fail(access, error)
        }
    }
    func refreshEvents(on day: Date, calendar: Calendar = .current) async {
        let request = UUID(); eventRequest = request
        events = []; calendarError = nil
        guard calendarEnabled, let interval = calendar.dateInterval(of: .day, for: day) else { return }
        let choices = calendarChoices
        let ids = Set(choices.filter { $0.value != .hidden }.keys)
        guard !ids.isEmpty else { return }
        do {
            let values = try await service.events(in: interval, calendarIDs: ids)
            guard eventRequest == request, calendarEnabled else { return }
            events = values.compactMap { $0.visible(as: choices[$0.calendarID] ?? .hidden) }
        } catch {
            guard eventRequest == request else { return }
            fail(.calendar, error)
        }
    }
    func refreshReminders(includeCompleted: Bool, for purpose: ReminderPurpose = .reminders) async {
        if purpose == .shopping {
            let request = UUID(); shoppingRequest = request
            shopping = []
            guard remindersEnabled, let id = shoppingListID else { return }
            do {
                let values = try await service.reminders(listIDs: [id], includeCompleted: includeCompleted)
                guard shoppingRequest == request, remindersEnabled, shoppingListID == id else { return }
                shopping = values.filter { $0.listID == id && (includeCompleted || !$0.completed) }
            } catch {
                guard shoppingRequest == request else { return }
                fail(.reminders, error)
            }
            return
        }
        let request = UUID(); reminderRequest = request
        reminders = []; remindersError = nil
        guard remindersEnabled, !reminderChoices.isEmpty else { return }
        let choices = reminderChoices
        do {
            let values = try await service.reminders(listIDs: choices, includeCompleted: includeCompleted)
            guard reminderRequest == request, remindersEnabled else { return }
            reminders = values.filter { choices.contains($0.listID) && (includeCompleted || !$0.completed) }
        } catch {
            guard reminderRequest == request else { return }
            fail(.reminders, error)
        }
    }
    /// A dashboard read must not replace a list screen's completed-item filter.
    func snapshot(for purpose: ReminderPurpose) async throws -> [AppleReminder] {
        guard remindersEnabled, let id = list(for: purpose)?.id else { return [] }
        let values = try await service.reminders(listIDs: [id], includeCompleted: false)
        try Task.checkCancellation()
        guard remindersEnabled, list(for: purpose)?.id == id else { return [] }
        return values.filter { $0.listID == id && !$0.completed }
    }
    func setCompleted(_ reminder: AppleReminder, completed: Bool) async throws {
        guard remindersEnabled, (reminderChoices.contains(reminder.listID) || shoppingListID == reminder.listID) else { throw ApplePlanningError.missingSource }
        try await service.setCompleted(reminder, completed: completed)
        revision += 1
    }
    func exportReminder(_ draft: ReminderExportDraft, listID: String) async throws {
        guard reminderChoices.contains(listID) || shoppingListID == listID else { throw ApplePlanningError.missingSource }
        guard remindersEnabled, reminderSources.contains(where: { $0.id == listID && $0.writable }) else { throw ApplePlanningError.missingSource }
        try await service.createReminder(draft, listID: listID)
        revision += 1
    }
    /// Re-evaluate on foreground; views reload selected data and discard stale results.
    func foreground() { events = []; reminders = []; shopping = []; shoppingRequest = UUID(); eventRequest = UUID(); reminderRequest = UUID(); revision += 1 }
    private func persist() {
        defaults.set(calendarEnabled, forKey: "apple.calendar.enabled")
        defaults.set(remindersEnabled, forKey: "apple.reminders.enabled")
        defaults.set(calendarChoices.mapValues(\.rawValue), forKey: "apple.calendar.choices")
        defaults.set(shoppingListID, forKey: "apple.shopping.list")
        defaults.set(Array(reminderChoices), forKey: "apple.reminders.choices")
        revision += 1
    }
    private func fail(_ access: PlanningAccess, _ error: Error) {
        let message = (error as? ApplePlanningError)?.localizedDescription ?? "Apple couldn't complete this request. Refresh to try again. Your local household is unchanged."
        if access == .calendar { events = []; calendarSources = []; calendarError = message }
        else { reminders = []; shopping = []; reminderSources = []; remindersError = message }
    }
}
