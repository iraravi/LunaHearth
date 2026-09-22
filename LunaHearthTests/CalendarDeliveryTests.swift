import Foundation
import Testing
@testable import LunaHearth

@MainActor struct CalendarDeliveryTests {
    private func repository() throws -> LocalHouseholdRepository {
        let value = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try value.createHousehold(name: "Home", owner: "Ravi", members: [])
        return value
    }
    @Test func explicitOptInIsDurableAndExcludedFromBackup() throws {
        let repo = try repository(); let home = try #require(repo.household?.id)
        let ids = try repo.saveAppointment(.init(title: "School", frequency: .weekly, count: 3), householdID: home, appleCalendarID: "apple", appleCalendarName: "Family")
        #expect(repo.calendarDeliveryLinks.count == 3)
        #expect(Set(repo.pendingCalendarJobs().map(\.eventID)) == Set(ids))
        try repo.reload(); #expect(repo.calendarDeliveryLinks.count == 3)
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(repo.makeBackup())
        #expect(restored.events.count == 3); #expect(restored.calendarDeliveryLinks.isEmpty)
    }
    @Test func laterEditsReuseIDAndPausingPreservesAppleCopy() async throws {
        let repo = try repository(); let home = try #require(repo.household?.id)
        let ids = try repo.saveAppointment(.init(title: "Class"), householdID: home, appleCalendarID: "apple")
        let service = CalendarTestProvider(); let coordinator = CalendarDeliveryCoordinator(service: service)
        await coordinator.run(repo)
        let original = try #require(repo.calendarDeliveryLinks.first?.externalID)
        let event = try #require(repo.events.first { $0.id == ids[0] })
        try repo.saveAppointment(.init(title: "Changed class", start: event.startAt, end: event.endAt, recordID: event.id, expectedModified: event.modifiedAt), householdID: home)
        await coordinator.run(repo)
        #expect(repo.calendarDeliveryLinks.first?.externalID == original)
        #expect(await service.writes.count == 2)
        #expect(await service.writes.last?.title == "Changed class")
        try repo.pauseCalendarDelivery(event.id)
        #expect(repo.pendingCalendarJobs(force: true).isEmpty)
        #expect(repo.calendarDeliveryLinks.first?.externalID == original)
    }
    @Test func deleteOnlyHereDoesNotDeleteAppleAndExplicitBothQueuesRemoval() async throws {
        let repo = try repository(); let home = try #require(repo.household?.id)
        let ids = try repo.saveAppointment(.init(title: "Class", frequency: .weekly, count: 2), householdID: home, appleCalendarID: "apple")
        let service = CalendarTestProvider(); let coordinator = CalendarDeliveryCoordinator(service: service)
        await coordinator.run(repo)
        try repo.deletePlanningEntry(id: ids[0], kind: .event)
        #expect(repo.pendingCalendarJobs(force: true).isEmpty)
        try repo.deletePlanningEntry(id: ids[1], kind: .event, removeAppleEvent: true)
        #expect(repo.pendingCalendarJobs(force: true).map(\.eventID) == [ids[1]])
        await coordinator.run(repo, force: true)
        #expect(repo.calendarDeliveryLinks.count == 1)
        #expect(await service.deletions == [ids[1]])
    }
    @Test func uncertainWriteKeepsOutboxForRecoveryInsteadOfBlindCreate() async throws {
        let repo = try repository(); let home = try #require(repo.household?.id)
        _ = try repo.saveAppointment(.init(title: "Class"), householdID: home, appleCalendarID: "apple")
        let service = CalendarTestProvider(); await service.failNextWrite()
        let coordinator = CalendarDeliveryCoordinator(service: service)
        await coordinator.run(repo)
        #expect(repo.calendarDeliveryLinks.first?.attempted == true)
        #expect(repo.calendarDeliveryLinks.first?.error != nil)
        #expect(repo.pendingCalendarJobs().isEmpty)
        await coordinator.run(repo, force: true)
        #expect(await service.writes.last?.attempted == true)
        #expect(repo.calendarDeliveryLinks.first?.externalID != nil)
        #expect(await service.createdCount == 1)
        #expect(coordinator.syncMessage == nil)
    }
    @Test func changedSourceIsRejectedAtomicallyAndForeignHouseCannotEnqueue() throws {
        let repo = try repository(); let home = try #require(repo.household?.id)
        _ = try repo.saveAppointment(.init(title: "Original"), householdID: home, appleCalendarID: "one")
        let event = try #require(repo.events.first)
        let draft = AppointmentDraft(title: "Should roll back", start: event.startAt, end: event.endAt, recordID: event.id, expectedModified: event.modifiedAt)
        #expect(throws: CalendarDeliveryError.self) { try repo.saveAppointment(draft, householdID: home, appleCalendarID: "two") }
        #expect(repo.events.first?.title == "Original"); #expect(repo.calendarDeliveryLinks.first?.calendarID == "one")
        #expect(throws: AppointmentError.self) { try repo.saveAppointment(.init(title: "Foreign"), householdID: UUID(), appleCalendarID: "one") }
    }
    @Test func resolverNeverRecreatesMissingOrUncertainCopiesAndRejectsForeignEvents() throws {
        let home = UUID(), id = UUID(), token = UUID(), start = Date.now
        func job(attempted: Bool = false, external: String? = nil) -> CalendarDeliveryJob {
            CalendarDeliveryJob(eventID: id, householdID: home, token: token, calendarID: "one", externalID: external, title: "Class", start: start, end: start.addingTimeInterval(3600), notes: nil, revision: start, lookupStart: start, lookupEnd: start.addingTimeInterval(3600), attempted: attempted, deleting: false)
        }
        #expect(try CalendarDeliveryRules.resolve(job(), candidates: []) == .create)
        #expect(throws: CalendarDeliveryError.self) { try CalendarDeliveryRules.resolve(job(attempted: true), candidates: []) }
        #expect(throws: CalendarDeliveryError.self) { try CalendarDeliveryRules.resolve(job(external: "missing"), candidates: []) }
        let known = CalendarDeliveryCandidate(id: "recovered", calendarID: "one", marker: job().marker, recurring: false, writable: true)
        #expect(try CalendarDeliveryRules.resolve(job(attempted: true), candidates: [known]) == .update("recovered"))
        #expect(throws: CalendarDeliveryError.self) { try CalendarDeliveryRules.resolve(job(), candidates: [known, known]) }
        let foreign = CalendarDeliveryCandidate(id: "foreign", calendarID: "one", marker: "unrelated", recurring: false, writable: true)
        #expect(throws: CalendarDeliveryError.self) { try CalendarDeliveryRules.resolve(job(external: "foreign"), candidates: [foreign]) }
    }
    @Test func noAutomaticExportWithoutCheckbox() async throws {
        let repo = try repository(); let home = try #require(repo.household?.id)
        _ = try repo.saveAppointment(.init(title: "Private plan"), householdID: home)
        let service = CalendarTestProvider(); await CalendarDeliveryCoordinator(service: service).run(repo)
        #expect(await service.writes.isEmpty); #expect(repo.calendarDeliveryLinks.isEmpty)
    }
}
private actor CalendarTestProvider: CalendarDeliveryService {
    var writes: [CalendarDeliveryJob] = []
    var deletions: [UUID] = []
    var createdCount = 0
    private var ids: [UUID: String] = [:]
    private var fail = false
    func failNextWrite() { fail = true }
    func requestCalendars() async throws -> [ApplePlanningSource] { [] }
    func deliver(_ job: CalendarDeliveryJob) async throws -> String? {
        if job.deleting { deletions.append(job.eventID); ids[job.eventID] = nil; return nil }
        writes.append(job)
        if ids[job.eventID] == nil { ids[job.eventID] = UUID().uuidString; createdCount += 1 }
        if fail { fail = false; throw CalendarDeliveryError.uncertain }
        return ids[job.eventID]
    }
}
