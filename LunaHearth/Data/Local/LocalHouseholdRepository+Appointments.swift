import Foundation

extension LocalHouseholdRepository {
    func appointmentConflicts(_ draft: AppointmentDraft) -> [FamilyEvent] {
        guard let slots = try? AppointmentRules.slots(draft) else { return [] }
        return events.filter { event in
            event.id != draft.recordID && (event.assignedMemberID == draft.memberID || event.assignedMemberID == nil || draft.memberID == nil)
            && slots.contains { AppointmentRules.overlaps($0, .init(start: event.startAt, end: event.endAt)) }
        }.sorted { $0.startAt < $1.startAt }
    }
    @discardableResult func saveAppointment(_ draft: AppointmentDraft, householdID: UUID, allowConflict: Bool = false, appleCalendarID: String? = nil, appleCalendarName: String? = nil, updateAppleLink: Bool = false) throws -> [UUID] {
        guard household?.id == householdID, draft.memberID == nil || members.contains(where: { $0.id == draft.memberID }) else { throw AppointmentError.stale }
        let slots = try AppointmentRules.slots(draft)
        let selfOverlap = zip(slots, slots.dropFirst()).contains { AppointmentRules.overlaps($0, $1) }
        guard allowConflict || (appointmentConflicts(draft).isEmpty && !selfOverlap) else { throw AppointmentError.conflict }
        let existing = events.first { $0.id == draft.recordID }
        if draft.recordID != nil { guard let existing, existing.modifiedAt == draft.expectedModified else { throw AppointmentError.stale } }
        var ids: [UUID] = []
        try commit {
            for slot in slots {
                let event = existing ?? FamilyEvent(householdID: householdID, title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines), startAt: slot.start, endAt: slot.end)
                event.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
                event.startAt = slot.start; event.endAt = slot.end; event.assignedMemberID = draft.memberID
                event.notes = draft.notes; event.appointmentKind = draft.kind.rawValue; event.reminderMinutes = draft.reminderMinutes; event.modifiedAt = .now
                if existing == nil { context.insert(event) }
                if updateAppleLink || appleCalendarID != nil { try configureCalendarDelivery(event, calendarID: appleCalendarID, calendarName: appleCalendarName) }
                ids.append(event.id)
            }
        }
        return ids
    }
}
