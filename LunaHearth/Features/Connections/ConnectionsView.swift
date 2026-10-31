import SwiftUI

struct ConnectionsView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var saveError: String?
    @Environment(AppleConnections.self) private var connections
    var body: some View {
        SettingsDetailPage(title: "Connections", subtitle: "Choose what connects to your day.", symbol: "app.connected.to.app.below.fill", accent: AppTheme.slate) {
            SettingsDetailCard(title: "Apple Calendar", symbol: "calendar", accent: AppTheme.slate) {
                if connections.calendarEnabled {
                    if connections.calendarSources.isEmpty { Text("No calendars available. Refresh or check access in Settings.").foregroundStyle(.secondary) }
                    ForEach(connections.calendarSources) { source in
                        Picker(selection: Binding(get: { connections.calendarChoices[source.id] ?? .hidden }, set: { connections.chooseCalendar(source.id, privacy: $0) })) {
                            Text("Hidden").tag(CalendarPrivacy.hidden)
                            Text("Busy only").tag(CalendarPrivacy.busyOnly)
                            Text("Event titles").tag(CalendarPrivacy.details)
                        } label: { sourceLabel(source) }
                        .accessibilityIdentifier("connections.calendar.\(source.id)")
                    }
                    Button("Disconnect Calendar", role: .destructive) { connections.disconnect(.calendar) }
                } else {
                    Button("Connect Apple Calendar", systemImage: "calendar") { Task { await connections.connect(.calendar) } }
                        .accessibilityIdentifier("connections.calendar.connect").disabled(connections.working).frame(minHeight: 44)
                }
                if let error = connections.calendarError { Text(error).foregroundStyle(.secondary).accessibilityIdentifier("connections.calendar.error") }

                Text("Selected events appear in Calendar on this device. Busy only hides event titles. These events are not copied into household storage or iCloud backups.").font(.footnote).foregroundStyle(.secondary)
            }
            SettingsDetailCard(title: "Apple Reminders", symbol: "checklist", accent: AppTheme.slate) {
                Text("Optional access to your existing Apple lists. Household reminders and shopping live in Nam Illam and work without this connection.").font(.subheadline).foregroundStyle(.secondary)
                NavigationLink { ConnectedRemindersView(purpose: .shopping) } label: { Label("Set up Shopping", systemImage: "basket") }.accessibilityIdentifier("connections.shopping.open").frame(minHeight: 44)
                NavigationLink { ConnectedRemindersView() } label: {
                    Label("Open Reminders", systemImage: "checklist")
                }.accessibilityIdentifier("connections.reminders.open").frame(minHeight: 44)
                Text("Changes made inside these connected lists stay in Apple Reminders. There is no automatic copying or two-way sync with your household.").font(.footnote).foregroundStyle(.secondary)
            }
            SettingsDetailCard(title: "Notes & sharing", symbol: "note.text", accent: AppTheme.clay) {
                NavigationLink { NotesSharingView() } label: { Label("Share to Notes", systemImage: "note.text") }
                    .accessibilityIdentifier("connections.notes").frame(minHeight: 44)

                Text("Review text, then choose Notes or another app in Apple's share sheet. This does not read or sync your Notes library.").font(.footnote).foregroundStyle(.secondary)
            }
            if connections.working { ProgressView("Waiting for Apple access…") }
            SettingsDetailCard(title: "Device permissions", symbol: "hand.raised", accent: AppTheme.sage) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) { Link("Open device settings", destination: settingsURL) }
                Text("Disconnect stops access inside Nam Illam. To revoke system permission, use device settings.").font(.footnote).foregroundStyle(.secondary)
            }
        }
            .task(id: connections.revision) { await refresh() }
            .refreshable { await refresh() }
            .saveError($saveError)
    }
    private func refresh() async {
        await connections.refreshSources(.calendar)
        await connections.refreshSources(.reminders)
    }
    private func sourceLabel(_ source: ApplePlanningSource) -> some View {
        VStack(alignment: .leading) {
            Text(source.title)
            Text("\(source.account)\(source.writable ? "" : " · Read only")").font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct NotesSharingView: View {
    @State private var text: String
    @FocusState private var isEditing: Bool
    init(text: String = "") { _text = State(initialValue: text) }
    var body: some View {
        Form {
            Section("Text to share") { TextEditor(text: $text).focused($isEditing).frame(minHeight: 180).accessibilityLabel("Note text").accessibilityIdentifier("notes.text") }
            Section {
                ShareLink(item: text) { Label("Choose Notes or another app", systemImage: "square.and.arrow.up") }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("notes.share")
            } footer: { Text("Nothing is sent until you choose an app and complete its sharing step. This draft is temporary; save it in Notes before leaving.") }
        }.hearthList().featureAvailability(.notesSharing).navigationTitle("Share a note").navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isEditing = false }.accessibilityIdentifier("notes.keyboardDone")
                }
            }
    }
}
