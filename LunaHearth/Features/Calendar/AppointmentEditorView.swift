import SwiftUI

struct AppointmentEditorView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(CalendarDeliveryCoordinator.self) private var delivery
    @State private var appleEnabled = false
    @State private var appleCalendarID = ""
    @State private var appleCalendarName = ""
    @State private var existingAppleLink = false
    @State private var connecting = false
    @State private var initialized = false
    @Environment(AppointmentAlertCoordinator.self) private var alerts
    @Environment(\.dismiss) private var dismiss
    @State private var draft: AppointmentDraft
    @State private var homeID: UUID?
    @State private var error: String?
    @State private var confirmingConflict = false
    @FocusState private var typing: Bool

    init(draft: AppointmentDraft = AppointmentDraft()) { _draft = State(initialValue: draft) }
    init(event: FamilyEvent) {
        _draft = State(initialValue: AppointmentDraft(title: event.title, start: event.startAt, end: event.endAt, memberID: event.assignedMemberID,
            kind: AppointmentKind(rawValue: event.appointmentKind ?? "") ?? .appointment, notes: event.notes ?? "", reminderMinutes: event.reminderMinutes,
            recordID: event.id, expectedModified: event.modifiedAt))
    }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 16) {
                        Image(systemName: draft.kind.symbol).symbolRenderingMode(.monochrome).foregroundStyle(AppTheme.slate).font(.largeTitle)
                            .frame(width: 64, height: 64).background(AppTheme.slate.opacity(0.1), in: RoundedRectangle(cornerRadius: 18)).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(draft.recordID == nil ? "Make time for what matters" : "Update this appointment").font(AppTheme.sectionTitle)
                            Text("One clear plan, shared with your household.").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    card {
                        Text("The plan").font(.headline)
                        TextField("Appointment name", text: $draft.title).font(.title3).focused($typing)
                            .padding(12).background(AppTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 12))
                            .accessibilityIdentifier("appointment.title")
                        Text("Type").font(.caption).foregroundStyle(.secondary)
                        Picker("Type", selection: $draft.kind) {
                            ForEach(AppointmentKind.allCases, id: \.self) { kind in Label(kind.rawValue, systemImage: kind.symbol).tag(kind) }
                        }.accessibilityIdentifier("appointment.kind")
                        Text("Who is it for?").font(.caption).foregroundStyle(.secondary)
                        Picker("For", selection: $draft.memberID) {
                            Text("Household").tag(nil as UUID?)
                            ForEach(repository.members) { Text($0.displayName).tag(Optional($0.id)) }
                        }.accessibilityIdentifier("appointment.member")
                    }
                    card {
                        Label("When", systemImage: "clock").font(.headline)
                        DatePicker("Starts", selection: $draft.start).accessibilityIdentifier("appointment.start")
                        DatePicker("Ends", selection: $draft.end).accessibilityIdentifier("appointment.end")
                        if draft.recordID == nil {
                            Text("Repeat").font(.caption).foregroundStyle(.secondary)
                        Picker("Repeat", selection: $draft.frequency) {
                                ForEach(AppointmentRepeat.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }.accessibilityIdentifier("appointment.repeat")
                            if draft.frequency != .never {
                                Stepper("Every \(draft.interval) \(draft.frequency.rawValue.lowercased())", value: $draft.interval, in: 1...30)
                                Stepper("\(draft.count) appointments", value: $draft.count, in: 2...52).accessibilityIdentifier("appointment.count")
                                if let last = try? AppointmentRules.slots(draft).last {
                                    Text("Last: \(last.start.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary)
                                }
                                Text("Creates separate appointments. Later edits and deletions affect only the appointment you open.").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    card {
                        Label("A gentle reminder", systemImage: "bell").font(.headline)
                        Text("Remind me").font(.caption).foregroundStyle(.secondary)
                        Picker("Remind", selection: $draft.reminderMinutes) {
                            Text("None").tag(nil as Int?)
                            Text("At start time").tag(Optional(0))
                            Text("15 minutes before").tag(Optional(15))
                            Text("1 hour before").tag(Optional(60))
                            Text("1 day before").tag(Optional(1440))
                        }.accessibilityIdentifier("appointment.reminder")
                        Text("Timing is shared. Each person enables their device alerts in Calendar settings.").font(.caption).foregroundStyle(.secondary)
                    }
                    card {
                        Toggle("Also add to Apple Calendar", isOn: Binding(get: { appleEnabled }, set: { enabled in
                            if !enabled { appleEnabled = false; return }
                            if existingAppleLink { appleEnabled = true; return }
                            connecting = true
                            Task {
                                appleEnabled = await delivery.connect()
                                connecting = false
                            }
                        })).disabled(connecting).accessibilityIdentifier("appointment.appleEnabled")
                        if connecting { ProgressView("Loading your calendars…") }
                        if appleEnabled {
                            if existingAppleLink {
                                Label(appleCalendarName, systemImage: "calendar").font(.subheadline)
                            } else {
                                Picker("Apple calendar", selection: $appleCalendarID) {
                                    Text("Choose a calendar").tag("")
                                    ForEach(delivery.calendars) { Text("\($0.title) · \($0.account)").tag($0.id) }
                                }.accessibilityIdentifier("appointment.appleCalendar")
                            }
                            Text("Title, time, and notes update from LunaHearth on this device. Changes made in Apple Calendar do not come back. Use one exporting device per Apple calendar.").font(.caption).foregroundStyle(.secondary)
                        } else if existingAppleLink {
                            Text("Saving will pause updates. The existing Apple copy stays.").font(.caption).foregroundStyle(.secondary)
                        }
                        if let message = delivery.message { Text(message).font(.caption).foregroundStyle(.secondary) }
                    }
                    card {
                        TextField("Notes · optional", text: $draft.notes, axis: .vertical).lineLimit(2...5).focused($typing)
                    }
                    if !repository.appointmentConflicts(draft).isEmpty {
                        Label("This plan overlaps another appointment. You’ll review the conflict before saving.", systemImage: "exclamationmark.triangle")
                            .font(.subheadline).foregroundStyle(.orange).accessibilityIdentifier("appointment.conflict")
                    }
                    if let error { Text(error).font(.subheadline).foregroundStyle(.red).accessibilityIdentifier("appointment.error") }
                }.padding(20).frame(maxWidth: 650).frame(maxWidth: .infinity)
            }.background(AppTheme.canvas)
                .navigationTitle(draft.recordID == nil ? "New appointment" : "Edit appointment").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.bold().disabled(connecting || draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty).accessibilityIdentifier("appointment.save") }
                    ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { typing = false } }
                }
                .onAppear {
                    guard !initialized else { return }; initialized = true; homeID = repository.household?.id
                    if let link = repository.calendarDeliveryLinks.first(where: { $0.eventID == draft.recordID }) {
                        existingAppleLink = true; appleEnabled = link.enabled; appleCalendarID = link.calendarID; appleCalendarName = link.calendarName
                    }
                }
                .alert("Overlapping appointments", isPresented: $confirmingConflict) {
                    Button("Keep editing", role: .cancel) {}
                    Button("Save anyway") { save(allowConflict: true) }
                } message: {
                    Text(repository.appointmentConflicts(draft).prefix(3).map { "\($0.title) · \($0.startAt.formatted(date: .abbreviated, time: .shortened))" }.joined(separator: "\n") + "\nRepeating appointments may also overlap one another.")
                }
        }
    }
    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16, content: content).frame(maxWidth: .infinity, alignment: .leading).padding(18)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
    private func save(allowConflict: Bool = false) {
        guard let homeID else { error = "Create or join a household first."; return }
        if appleEnabled && appleCalendarID.isEmpty { error = "Choose an Apple calendar, or turn off the checkbox to save only in LunaHearth."; return }
        do {
            try repository.saveAppointment(draft, householdID: homeID, allowConflict: allowConflict, appleCalendarID: appleEnabled ? appleCalendarID : nil, appleCalendarName: delivery.calendars.first { $0.id == appleCalendarID }.map { "\($0.title) · \($0.account)" } ?? appleCalendarName, updateAppleLink: true)
            Task { await alerts.refresh(repository); await delivery.run(repository, force: true) }
            dismiss()
        } catch AppointmentError.conflict { confirmingConflict = true }
        catch { self.error = error.localizedDescription }
    }
}
