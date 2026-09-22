import SwiftUI

struct CalendarDeliverySettingsView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(CalendarDeliveryCoordinator.self) private var delivery
    @State private var removing: UUID?
    @State private var forgetting: UUID?
    @State private var error: String?
    var body: some View {
        List {
            Section {
                Label("LunaHearth → Apple Calendar", systemImage: "calendar.badge.checkmark").font(.headline)
                Text("Enable ‘Also add to Apple Calendar’ on each appointment. Only this device manages these links. Use one exporting device per Apple calendar to avoid duplicate copies.").font(.subheadline).foregroundStyle(.secondary)
                Button("Retry pending updates", systemImage: "arrow.clockwise") { Task { await delivery.run(repository, force: true) } }
                    .disabled(delivery.working).accessibilityIdentifier("calendar.delivery.retry")
                if let message = delivery.syncMessage { Text(message).font(.caption).foregroundStyle(.secondary) }
            }
            if repository.calendarDeliveryLinks.isEmpty {
                ContentUnavailableView("No linked appointments", systemImage: "calendar", description: Text("Open an appointment, tap Edit, and enable Apple Calendar."))
            }
            ForEach(repository.calendarDeliveryLinks, id: \.eventID) { link in
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(repository.events.first { $0.id == link.eventID }?.title ?? link.title).font(.headline)
                        Text(link.calendarName).font(.subheadline).foregroundStyle(.secondary)
                        Label(status(link), systemImage: link.error == nil ? "calendar" : "exclamationmark.triangle")
                            .font(.caption).foregroundStyle(.secondary)
                        if let error = link.error { Text(error).font(.caption).foregroundStyle(.secondary) }
                    }
                    if link.enabled && !link.deleteRequested {
                        Button("Pause updates · keep Apple copy") { do { try repository.pauseCalendarDelivery(link.eventID) } catch { self.error = error.localizedDescription } }
                    }
                    Button("Remove Apple copy", role: .destructive) { removing = link.eventID }
                    Button("Forget link · keep Apple copy") { forgetting = link.eventID }
                }.disabled(delivery.working)
            }
        }.navigationTitle("Linked Apple events").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Remove the linked Apple event?", isPresented: Binding(get: { removing != nil }, set: { if !$0 { removing = nil } })) {
                Button("Remove Apple copy", role: .destructive) {
                    guard let id = removing else { return }
                    do { try repository.removeAppleCopy(id); Task { await delivery.run(repository, force: true) } } catch { self.error = error.localizedDescription }
                    removing = nil
                }
            } message: { Text("The LunaHearth appointment stays. Removal from Apple Calendar will be retried if it cannot finish now.") }
            .confirmationDialog("Forget this device's link?", isPresented: Binding(get: { forgetting != nil }, set: { if !$0 { forgetting = nil } })) {
                Button("Forget link", role: .destructive) {
                    guard let id = forgetting else { return }
                    do { try repository.forgetCalendarLink(id) } catch { self.error = error.localizedDescription }
                    forgetting = nil
                }
            } message: { Text("This does not delete the Apple event. Before exporting again, check Apple Calendar and remove any unwanted copy to avoid duplicates.") }
            .saveError($error)
    }
    private func status(_ link: CalendarDeliveryLink) -> String {
        if link.error != nil { return "Needs attention" }
        if link.deleteRequested { return "Apple removal pending" }
        guard let event = repository.events.first(where: { $0.id == link.eventID }) else { return "LunaHearth appointment removed · Apple copy kept" }
        if !link.enabled { return "Paused · Apple copy kept" }
        return link.sentRevision == event.modifiedAt ? "Last update sent" : "Update pending"
    }
}
