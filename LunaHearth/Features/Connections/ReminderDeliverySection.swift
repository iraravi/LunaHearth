import SwiftUI

struct ReminderDeliverySection: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(AppleConnections.self) private var connections
    @Environment(ReminderDeliveryCoordinator.self) private var delivery
    @State private var selectedList = ""
    @State private var error: String?
    private var enabled: Bool { repository.reminderDeliverySettings?.enabled == true }
    private var writable: [ApplePlanningSource] { connections.reminderSources.filter(\.writable) }
    private var pending: Int { repository.pendingReminderJobs(force: true).count }

    var body: some View {
        Section {
            Picker("Send new tasks to", selection: $selectedList) {
                Text("Choose a list").tag("")
                ForEach(writable) { source in
                    Text("\(source.title) · \(source.account)").tag(source.id)
                }
                if !selectedList.isEmpty, !writable.contains(where: { $0.id == selectedList }) {
                    Text("Selected list unavailable").tag(selectedList)
                }
            }.disabled(enabled).accessibilityIdentifier("connections.reminders.destination")
            Toggle("Sync new tasks", isOn: Binding(get: { enabled }, set: configure))
                .disabled(!enabled && !writable.contains(where: { $0.id == selectedList }))
                .accessibilityIdentifier("connections.reminders.autoSync")
            if enabled {
                Label(pending == 0 ? "Tasks are up to date" : "\(pending) task(s) waiting to sync",
                      systemImage: pending == 0 ? "checkmark.circle" : "arrow.triangle.2.circlepath")
                Button("Sync now") { Task { await delivery.run(repository: repository, connections: connections, force: true) } }
                    .disabled(delivery.working).accessibilityIdentifier("connections.reminders.retry")
                if delivery.working { ProgressView("Sending to Apple Reminders…") }
                if let issue = delivery.error ?? repository.reminderDeliveryLinks.compactMap(\.error).first {
                    Text(issue).font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let error { Text(error).foregroundStyle(.secondary) }
        } header: { Text("LunaHearth → Apple Reminders") } footer: {
            Text("When enabled, new household tasks send their title, due day and completion to this list and its account or sharing participants. Later edits in LunaHearth update those reminders while the app is open. Changes in Apple Reminders do not update LunaHearth. Existing tasks are not added automatically. Turning this off pauses updates; reminders already sent stay in Apple. Linked tasks keep their original list if you choose a new destination.")
        }
        .onAppear { selectedList = repository.reminderDeliverySettings?.listID ?? "" }
    }
    private func configure(_ value: Bool) {
        do {
            guard !value || writable.contains(where: { $0.id == selectedList }) else { return }
            try repository.configureReminderDelivery(enabled: value, listID: selectedList)
            if value { connections.chooseReminderList(selectedList, enabled: true) }
            error = nil
        } catch { self.error = userFacingError(error) }
    }
}
