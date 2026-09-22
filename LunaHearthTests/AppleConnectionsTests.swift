import Foundation
import Testing
@testable import LunaHearth

private actor PlanningFake: ApplePlanningService {
    var reject = false
    var delayed = false
    var eventFetches = 0
    var reminderFetches = 0
    var writes = 0
    var pending: CheckedContinuation<[AppleCalendarEvent], Never>?
    var started: CheckedContinuation<Void, Never>?
    let event = AppleCalendarEvent(id: "event", calendarID: "cal", title: "Private appointment", start: Date(timeIntervalSince1970: 1000), end: Date(timeIntervalSince1970: 2000), allDay: false)
    func createStandardReminderList(usingListID: String, title: String) throws -> ApplePlanningSource {
        if reject { throw ApplePlanningError.permission }
        guard usingListID == "list" else { throw ApplePlanningError.missingSource }
        return ApplePlanningSource(id: "standard", title: title, account: "iCloud", writable: true)
    }
    func setRejected(_ value: Bool) { reject = value }
    func setDelayed() { delayed = true }
    func requestAccess(_ access: PlanningAccess) throws { if reject { throw ApplePlanningError.permission } }
    func sources(_ access: PlanningAccess) throws -> [ApplePlanningSource] {
        if reject { throw ApplePlanningError.permission }
        return [ApplePlanningSource(id: access == .calendar ? "cal" : "list", title: "Personal", account: "iCloud", writable: true)]
    }
    func events(in interval: DateInterval, calendarIDs: Set<String>) async throws -> [AppleCalendarEvent] {
        eventFetches += 1
        if reject { throw ApplePlanningError.permission }
        if delayed {
            return await withCheckedContinuation { continuation in
                pending = continuation
                started?.resume(); started = nil
            }
        }
        return [event]
    }
    func waitForFetch() async {
        if pending != nil { return }
        await withCheckedContinuation { started = $0 }
    }
    func releaseFetch() { pending?.resume(returning: [event]); pending = nil }
    func reminders(listIDs: Set<String>, includeCompleted: Bool) throws -> [AppleReminder] {
        reminderFetches += 1
        if reject { throw ApplePlanningError.permission }
        return [AppleReminder(id: "reminder", listID: "list", title: "Call the plumber", due: nil, completed: false),
                AppleReminder(id: "unselected", listID: "other", title: "Never show", due: nil, completed: false)]
    }
    func setCompleted(_ reminder: AppleReminder, completed: Bool) throws { if reject { throw ApplePlanningError.permission }; writes += 1 }
    func createReminder(_ draft: ReminderExportDraft, listID: String) { writes += 1 }
}

@MainActor struct AppleConnectionsTests {
    private func preferences() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "AppleConnectionsTests.\(UUID().uuidString)"))
    }
    @Test func connectionRequiresOptInAndIndividualCalendarSelection() async throws {
        let fake = PlanningFake()
        let model = AppleConnections(service: fake, defaults: try preferences())
        await model.refreshEvents(on: .now)
        #expect(await fake.eventFetches == 0)
        await model.connect(.calendar)
        #expect(model.calendarEnabled)
        await model.refreshEvents(on: .now)
        #expect(await fake.eventFetches == 0)
        model.chooseCalendar("cal", privacy: .busyOnly)
        await model.refreshEvents(on: .now)
        #expect(model.events.first?.title == "Busy")
        model.chooseCalendar("cal", privacy: .details)
        #expect(model.events.isEmpty)
        await model.refreshEvents(on: .now)
        #expect(model.events.first?.title == "Private appointment")
        model.chooseCalendar("cal", privacy: .hidden)
        await model.refreshEvents(on: .now)
        #expect(model.events.isEmpty)
    }
    @Test func disconnectDiscardsAnInFlightPrivateResult() async throws {
        let fake = PlanningFake()
        let defaults = try preferences()
        let model = AppleConnections(service: fake, defaults: defaults)
        await model.connect(.calendar)
        model.chooseCalendar("cal", privacy: .details)
        await fake.setDelayed()
        let read = Task { await model.refreshEvents(on: .now) }
        await fake.waitForFetch()
        model.disconnect(.calendar)
        await fake.releaseFetch()
        await read.value
        #expect(model.events.isEmpty)
        let reloaded = AppleConnections(service: fake, defaults: defaults)
        #expect(!reloaded.calendarEnabled)
        #expect(reloaded.calendarChoices.isEmpty)
    }
    @Test func remindersStaySelectedAndRevokedAccessClearsPrivateData() async throws {
        let fake = PlanningFake()
        let model = AppleConnections(service: fake, defaults: try preferences())
        await model.connect(.reminders)
        await model.refreshReminders(includeCompleted: false)
        #expect(await fake.reminderFetches == 0)
        model.chooseReminderList("list", enabled: true)
        await model.refreshReminders(includeCompleted: false)
        #expect(model.reminders.count == 1)
        let reminder = try #require(model.reminders.first)
        try await model.setCompleted(reminder, completed: true)
        #expect(await fake.writes == 1)
        await fake.setRejected(true)
        await model.refreshReminders(includeCompleted: false)
        #expect(model.reminders.isEmpty)
        #expect(model.remindersError != nil)
        model.disconnect(.reminders)
        await #expect(throws: ApplePlanningError.self) { try await model.setCompleted(reminder, completed: false) }
        #expect(await fake.writes == 1)
    }
    @Test func permissionDenialDoesNotEnableConnections() async throws {
        let fake = PlanningFake()
        await fake.setRejected(true)
        let model = AppleConnections(service: fake, defaults: try preferences())
        await model.connect(.calendar)
        await model.connect(.reminders)
        #expect(!model.calendarEnabled && !model.remindersEnabled)
        #expect(model.calendarError != nil && model.remindersError != nil)
    }
    @Test func privateAppleEventsDoNotEnterHouseholdBackup() async throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        let model = AppleConnections(service: PlanningFake(), defaults: try preferences())
        await model.connect(.calendar)
        model.chooseCalendar("cal", privacy: .details)
        await model.refreshEvents(on: .now)
        #expect(!model.events.isEmpty)
        let backup = try repo.makeBackup()
        #expect(backup.records.count == 1)
        #expect(!backup.records.contains { String(data: $0.payload, encoding: .utf8)?.contains("Private appointment") == true })
    }
    @Test func reminderExportPreservesCivilDayWithoutAddingATime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let date = try #require(ISO8601DateFormatter().date(from: "2026-11-01T06:30:00Z"))
        let draft = ReminderExportDraft(id: UUID(), title: "Task", due: date)
        let parts = try #require(draft.dueComponents(calendar: calendar))
        #expect(parts.year == 2026 && parts.month == 11 && parts.day == 1)
        #expect(parts.hour == nil && parts.minute == nil)
        #expect(ReminderExportDraft(id: UUID(), title: "Task", due: nil).dueComponents() == nil)
    }
    @Test func taskLinksAreStableAndRejectOtherRoutes() throws {
        let id = UUID()
        let draft = ReminderExportDraft(id: id, title: "Task", due: nil)
        #expect(HouseholdLink.taskID(try #require(draft.link)) == id)
        #expect(draft.link == ReminderExportDraft(id: id, title: "Renamed", due: .now).link)
        #expect(HouseholdLink.taskID(try #require(URL(string: "https://task/\(id)"))) == nil)
        #expect(HouseholdLink.taskID(try #require(URL(string: "lunahearth://task/not-a-uuid"))) == nil)
    }
}

@MainActor struct AppleOnlyReminderTests {
    @Test func selectedListIsExclusiveAndNewRemindersHaveNoLocalTaskLink() async throws {
        let defaults = try #require(UserDefaults(suiteName: "AppleOnly.\(UUID())"))
        let fake = PlanningFake()
        let connections = AppleConnections(service: fake, defaults: defaults)
        await connections.connect(.reminders)
        connections.selectReminderList("list")
        try await connections.exportReminder(ReminderExportDraft(id: UUID(), title: "Direct", due: nil, appleOnly: true), listID: "list")
        #expect(await fake.writes == 1)
        try await connections.createStandardList(usingListID: "list")
        #expect(connections.reminderChoices == ["standard"])
        #expect(connections.activeReminderList?.title == "LunaHearth Reminders")
        let draft = ReminderExportDraft(id: UUID(), title: "Direct", due: nil, appleOnly: true)
        #expect(draft.link?.host == "reminders")
        #expect(HouseholdLink.taskID(try #require(draft.link)) == nil)
        await fake.setRejected(true)
        do { try await connections.createStandardList(usingListID: "list"); Issue.record("Expected failure") } catch {}
        #expect(connections.reminderChoices == ["standard"])
    }
}

@MainActor struct ListConnectionSetupTests {
    @Test func shoppingSelectionDoesNotReplaceReminderSelection() async throws {
        let defaults = try #require(UserDefaults(suiteName: "ListSetup.\(UUID())"))
        let fake = PlanningFake()
        let connections = AppleConnections(service: fake, defaults: defaults)
        await connections.connect(.reminders)
        do {
            try await connections.exportReminder(ReminderExportDraft(id: UUID(), title: "Unselected", due: nil, appleOnly: true), listID: "list")
            Issue.record("An unselected destination must not be writable")
        } catch {}
        #expect(await fake.writes == 0)
        connections.selectReminderList("list")
        connections.selectReminderList("shopping", for: .shopping)
        #expect(connections.reminderChoices == ["list"])
        #expect(connections.shoppingListID == "shopping")
        await connections.refreshReminders(includeCompleted: true, for: .shopping)
        #expect(connections.shopping.isEmpty) // Fake's unrelated list contents must not leak.
        await connections.refreshReminders(includeCompleted: true)
        let displayed = connections.reminders
        _ = try await connections.snapshot(for: .shopping)
        #expect(connections.reminders == displayed)
        let shoppingDraft = ReminderExportDraft(id: UUID(), title: "Milk", due: nil, purpose: .shopping, appleOnly: true, notes: "Quantity: 2")
        #expect(shoppingDraft.link?.host == "shopping")
        #expect(shoppingDraft.notes == "Quantity: 2")
        let reloaded = AppleConnections(service: fake, defaults: defaults)
        #expect(reloaded.shoppingListID == "shopping")
        #expect(reloaded.reminderChoices == ["list"])
        connections.disconnect(.reminders)
        #expect(connections.shoppingListID == nil)
        #expect(connections.shopping.isEmpty)
    }
    @Test func dueFiltersPreserveUndatedItemsAndCivilDayBoundaries() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 12)))
        let tomorrow = try #require(calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)))
        let undated = AppleReminder(id: "a", listID: "list", title: "Milk", due: nil, completed: false)
        let upcoming = AppleReminder(id: "b", listID: "list", title: "Filter", due: tomorrow, completed: false)
        let overdue = AppleReminder(id: "c", listID: "list", title: "Call", due: now.addingTimeInterval(-172800), completed: false)
        #expect(ReminderScope.all.includes(undated, now: now, calendar: calendar))
        #expect(!ReminderScope.today.includes(undated, now: now, calendar: calendar))
        #expect(!ReminderScope.today.includes(upcoming, now: now, calendar: calendar))
        #expect(ReminderScope.upcoming.includes(upcoming, now: now, calendar: calendar))
        #expect(ReminderScope.today.includes(overdue, now: now, calendar: calendar))
    }
}
