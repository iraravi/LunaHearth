import Foundation
import Testing
@testable import LunaHearth

@MainActor struct AppointmentTests {
    private func repository() throws -> LocalHouseholdRepository {
        let repository = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repository.createHousehold(name: "Home", owner: "Ravi", members: [("Kira", .adult)])
        return repository
    }
    @Test func weeklyRepeatsKeepLocalTimeAcrossDST() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = try #require(TimeZone(identifier: "America/Chicago"))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 25, hour: 9)))
        let draft = AppointmentDraft(title: "Class", start: start, end: start.addingTimeInterval(3600), frequency: .weekly, count: 3)
        let slots = try AppointmentRules.slots(draft, calendar: calendar)
        #expect(slots.count == 3)
        #expect(slots.allSatisfy { calendar.component(.hour, from: $0.start) == 9 })
        #expect(slots[1].start.timeIntervalSince(slots[0].start) == 7 * 86400 + 3600)
        #expect(!AppointmentRules.overlaps(slots[0], .init(start: slots[0].end, end: slots[0].end.addingTimeInterval(60))))
    }
    @Test func monthlyRepeatUsesOriginalAnchorAndClampsMonthEnd() throws {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let start = try #require(calendar.date(from: DateComponents(year: 2026, month: 1, day: 31, hour: 9)))
        let slots = try AppointmentRules.slots(.init(title: "Monthly", start: start, end: start.addingTimeInterval(3600), frequency: .monthly, count: 3), calendar: calendar)
        #expect(slots.map { calendar.component(.day, from: $0.start) } == [31, 28, 31])
    }
    @Test func savesAtomicallyChecksConflictsAndPreservesBackupFields() throws {
        let repo = try repository(); let home = try #require(repo.household?.id); let member = try #require(repo.members.first?.id)
        var draft = AppointmentDraft(title: "School", memberID: member, kind: .school, reminderMinutes: 15, frequency: .weekly, count: 3)
        let ids = try repo.saveAppointment(draft, householdID: home)
        #expect(ids.count == 3); #expect(repo.events.count == 3)
        #expect(throws: AppointmentError.self) { try repo.saveAppointment(draft, householdID: home) }
        #expect(repo.events.count == 3)
        let backup = try repo.makeBackup()
        let restored = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try restored.restoreBackup(backup)
        #expect(restored.events.allSatisfy { $0.appointmentKind == "School" && $0.reminderMinutes == 15 })
        let event = try #require(repo.events.first { $0.id == ids[0] })
        draft.recordID = event.id; draft.expectedModified = event.modifiedAt.addingTimeInterval(-1)
        #expect(throws: AppointmentError.self) { try repo.saveAppointment(draft, householdID: home, allowConflict: true) }
        #expect(repo.events.count == 3)
    }
    @Test func invalidRepeatAndForeignMemberCannotPartiallySave() throws {
        let repo = try repository(); let home = try #require(repo.household?.id)
        #expect(throws: AppointmentError.self) { try repo.saveAppointment(.init(title: "Plan", memberID: UUID()), householdID: home) }
        #expect(throws: AppointmentError.self) { try repo.saveAppointment(.init(title: "Plan", frequency: .daily, count: 100), householdID: home) }
        #expect(repo.events.isEmpty)
    }
    @Test func siriLinksRoundTripSafelyAndRejectInvalidDates() throws {
        let date = Date(timeIntervalSince1970: 1800000000)
        let url = try AppointmentLink.url(title: "Doctor & school?", date: date, member: "Kira", create: true)
        let link = try #require(AppointmentLink(url: url))
        #expect(link.title == "Doctor & school?"); #expect(link.date == date); #expect(link.member == "Kira"); #expect(link.create)
        let invalid = try #require(URL(string: "lunahearth://calendar?date=nan&create=1"))
        #expect(AppointmentLink(url: invalid) == nil)
    }
    @Test func alertRefreshReconcilesChangesMadeDuringAnEarlierRefresh() async throws {
        let repo = try repository()
        let home = try #require(repo.household?.id)
        let member = try #require(repo.members.first?.id)
        let suite = "AppointmentRefreshTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "calendar.alertsEnabled")
        defaults.set(member.uuidString, forKey: "calendar.alertMember")
        _ = try repo.saveAppointment(.init(title: "Plan", reminderMinutes: 15), householdID: home)
        let service = SuspendedAppointmentAlerts()
        let coordinator = AppointmentAlertCoordinator(service: service, defaults: defaults)
        let first = Task { await coordinator.refresh(repo) }
        await service.waitUntilStarted()
        defaults.set(false, forKey: "calendar.alertsEnabled")
        await coordinator.refresh(repo)
        await service.release()
        await first.value
        #expect(await service.calls == 2)
        #expect(await service.values.isEmpty)
    }

    @Test func alertsTargetSelectedPersonAndDisableClears() async throws {
        let repo = try repository(); let home = try #require(repo.household?.id)
        let ravi = try #require(repo.members.first { $0.displayName == "Ravi" }?.id)
        let kira = try #require(repo.members.first { $0.displayName == "Kira" }?.id)
        let defaults = try #require(UserDefaults(suiteName: "AppointmentTests.\(UUID())"))
        defaults.set(true, forKey: "calendar.alertsEnabled"); defaults.set(kira.uuidString, forKey: "calendar.alertMember")
        let service = TestAppointmentAlerts(); let coordinator = AppointmentAlertCoordinator(service: service, defaults: defaults)
        _ = try repo.saveAppointment(.init(title: "Ravi", memberID: ravi, reminderMinutes: 15), householdID: home)
        let ids = try repo.saveAppointment(.init(title: "Kira", memberID: kira, reminderMinutes: 60), householdID: home)
        await coordinator.refresh(repo)
        #expect(await service.values.map(\.id) == ids)
        defaults.set(false, forKey: "calendar.alertsEnabled")
        await coordinator.refresh(repo)
        #expect(await service.values.isEmpty)
    }
}
private actor TestAppointmentAlerts: AppointmentAlertService {
    var values: [AppointmentAlert] = []
    func requestPermission() async throws -> Bool { true }
    func replace(_ alerts: [AppointmentAlert]) async throws { values = alerts }
}

private actor SuspendedAppointmentAlerts: AppointmentAlertService {
    private var started: CheckedContinuation<Void, Never>?
    private var blocked: CheckedContinuation<Void, Never>?
    var calls = 0
    var values: [AppointmentAlert] = []
    func requestPermission() async throws -> Bool { true }
    func waitUntilStarted() async {
        if calls > 0 { return }
        await withCheckedContinuation { started = $0 }
    }
    func release() { blocked?.resume(); blocked = nil }
    func replace(_ alerts: [AppointmentAlert]) async throws {
        calls += 1
        if calls == 1 {
            await withCheckedContinuation { continuation in
                blocked = continuation
                started?.resume(); started = nil
            }
        }
        values = alerts
    }
}
