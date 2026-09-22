import EventKit
import Foundation
import Testing
@testable import LunaHearth

/// Explicit opt-in only. Creates/removes its own local simulator calendar; no user's calendar is edited.
@MainActor struct SystemCalendarIntegrationTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_SYSTEM_CALENDAR_DENIED_TESTS"] == "1"))
    func revokedCalendarAccessKeepsLocalAppointmentAndRetryState() async throws {
        #if targetEnvironment(simulator)
        try #require(EKEventStore.authorizationStatus(for: .event) != .fullAccess)
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Permission test", owner: "", members: [])
        _ = try repo.saveAppointment(.init(title: "Keep this appointment"), householdID: try #require(repo.household?.id), appleCalendarID: "synthetic-unavailable-calendar")
        let coordinator = CalendarDeliveryCoordinator(service: SystemCalendarDelivery())
        await coordinator.run(repo)
        #expect(repo.events.count == 1 && repo.events.first?.title == "Keep this appointment")
        #expect(repo.calendarDeliveryLinks.first?.externalID == nil)
        #expect(repo.calendarDeliveryLinks.first?.attempted == false)
        #expect(coordinator.syncMessage == ApplePlanningError.permission.errorDescription)
        #expect(repo.pendingCalendarJobs(force: true).count == 1)
        #else
        Issue.record("This opt-in test is restricted to a simulator.")
        #endif
    }

    @Test(.enabled(if: ProcessInfo.processInfo.environment["RUN_SYSTEM_CALENDAR_TESTS"] == "1"))
    func actualEventKitCreateUpdateDeleteUsesOneLinkedEvent() async throws {
        #if targetEnvironment(simulator)
        try #require(EKEventStore.authorizationStatus(for: .event) == .fullAccess)
        let store = EKEventStore()
        let source = try #require(store.sources.first { $0.sourceType == .local })
        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = "LunaHearth release test \(UUID().uuidString)"
        calendar.source = source
        try store.saveCalendar(calendar, commit: true)
        let calendarID = calendar.calendarIdentifier
        defer {
            if let saved = store.calendar(withIdentifier: calendarID) { try? store.removeCalendar(saved, commit: true) }
        }
        let service = SystemCalendarDelivery()
        let listed = try await service.requestCalendars()
        #expect(listed.contains { $0.id == calendarID })
        let home = UUID(), event = UUID(), token = UUID(), start = Date.now.addingTimeInterval(3600)
        func job(title: String, external: String? = nil, deleting: Bool = false) -> CalendarDeliveryJob {
            CalendarDeliveryJob(eventID: event, householdID: home, token: token,
                calendarID: calendarID, externalID: external, title: title,
                start: start, end: start.addingTimeInterval(1800), notes: "Synthetic release test",
                revision: start, lookupStart: start, lookupEnd: start.addingTimeInterval(1800),
                attempted: external != nil, deleting: deleting)
        }
        let id = try #require(try await service.deliver(job(title: "Release test")))
        let secondID = try await service.deliver(job(title: "Updated release test", external: id))
        #expect(secondID == id)
        func savedEvents() throws -> [EKEvent] {
            store.reset()
            let saved = try #require(store.calendar(withIdentifier: calendarID))
            let predicate = store.predicateForEvents(withStart: start.addingTimeInterval(-60), end: start.addingTimeInterval(3600), calendars: [saved])
            return store.events(matching: predicate)
        }
        let events = try savedEvents()
        #expect(events.count == 1 && events.first?.title == "Updated release test")
        #expect(events.first?.url?.absoluteString == job(title: "").marker)
        let removed = try await service.deliver(job(title: "", external: id, deleting: true))
        #expect(removed == nil)
        #expect(try savedEvents().isEmpty)
        try store.removeCalendar(try #require(store.calendar(withIdentifier: calendarID)), commit: true)
        #expect(store.calendar(withIdentifier: calendarID) == nil)
        #else
        Issue.record("This opt-in test is restricted to a local simulator calendar.")
        #endif
    }
}
