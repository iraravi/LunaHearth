import SwiftUI
import AppIntents

struct CalendarSettingsView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(AppointmentAlertCoordinator.self) private var alerts
    @Environment(\.dismiss) private var dismiss
    @AppStorage("calendar.alertsEnabled") private var enabled = false
    @AppStorage("calendar.alertMember") private var member = ""
    @State private var busy = false
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Your plans, at the right time", systemImage: "bell.badge").font(.headline)
                    Picker("This device receives alerts for", selection: $member) {
                        Text("Choose a person").tag("")
                        ForEach(repository.members) { Text($0.displayName).tag($0.id.uuidString) }
                    }.accessibilityIdentifier("calendar.alertMember")
                    Toggle("Appointment alerts", isOn: Binding(get: { enabled }, set: { value in
                        if !value { enabled = false; Task { await alerts.refresh(repository) }; return }
                        busy = true
                        Task { enabled = await alerts.enable(); busy = false; if enabled { await alerts.refresh(repository) } }
                    })).disabled(member.isEmpty || busy).accessibilityIdentifier("calendar.alerts")
                    Text("Includes this person’s appointments and Household appointments. Other people enable alerts on their own devices. Open the app after sharing changes to refresh alerts. Up to 24 upcoming alerts are queued, subject to available device capacity.")
                        .font(.caption).foregroundStyle(.secondary)
                    if let message = alerts.message { Text(message).font(.caption).foregroundStyle(.secondary) }
                } header: { Text("On this device") }
                Section("Apple Calendar") {
                    NavigationLink("Linked events & sync status") { CalendarDeliverySettingsView() }
                        .accessibilityIdentifier("calendar.delivery.settings")
                    Text("Connections are private to this device. Shared appointments are not automatically exported by other household devices.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Siri & Shortcuts") {
                    Label("A little help, hands-free", systemImage: "waveform").font(.headline)
                    Text("Try ‘Plan an appointment in Nam Illam’ or ‘Show my family calendar in Nam Illam’.")
                    Text("Siri opens a draft for you to review and save. Choose the person in the app if their name is ambiguous. Siri availability and voice processing follow your Apple device settings.").font(.caption).foregroundStyle(.secondary)
                    ShortcutsLink()
                }
            }.navigationTitle("Calendar settings").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Done") { dismiss() } }
                .onChange(of: member) { _, _ in Task { await alerts.refresh(repository) } }
        }
    }
}
