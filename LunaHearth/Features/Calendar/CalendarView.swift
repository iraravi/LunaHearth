import SwiftUI

struct CalendarView: View {
    var body: some View { NavigationStack { CalendarAgendaView() } }
}

struct CalendarAgendaView: View {
    @Environment(AppleConnections.self) private var connections
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedDate = Date.now
    @State private var appointmentDraft: AppointmentDraft?
    @State private var memberID: UUID?
    @State private var showingMonth = false
    @State private var settings = false

    init(date: Date = .now) { _selectedDate = State(initialValue: date) }

    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 700 && !typeSize.isAccessibilitySize
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Our family calendar").font(AppTheme.sectionTitle)
                                Text(selectedDate, format: .dateTime.weekday(.wide).month(.wide).day())
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            Button { withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { showingMonth.toggle() } } label: {
                                Image(systemName: "calendar").frame(width: 44, height: 44)

                            }.hearthGlassButton().accessibilityLabel("Choose date").accessibilityIdentifier("calendar.month")
                        }
                        HearthGlassControls { HStack(spacing: 12) {
                            Button { shiftDay(-1) } label: { Label("Previous", systemImage: "chevron.left").labelStyle(.iconOnly).frame(width: 44, height: 44) }
                                .accessibilityIdentifier("calendar.previous")
                            Button("Today") { selectedDate = .now }.frame(minHeight: 44).accessibilityIdentifier("calendar.today")
                            Button { shiftDay(1) } label: { Label("Next", systemImage: "chevron.right").labelStyle(.iconOnly).frame(width: 44, height: 44) }
                                .accessibilityIdentifier("calendar.next")
                            Spacer()
                        }.hearthGlassButton() }
                        if showingMonth { monthPicker.frame(maxWidth: 420) }
                        memberFilters
                    }
                    NavigationLink { FamilyWeekView(start: selectedDate) } label: {
                        HStack { Label("Family week", systemImage: "calendar.badge.clock"); Spacer(); Image(systemName: "chevron.right") }
                            .font(.subheadline.weight(.semibold)).padding(16).frame(minHeight: 52)
                            .background(AppTheme.slate.opacity(0.07), in: RoundedRectangle(cornerRadius: 18)).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityIdentifier("calendar.week")
                    CalendarFamilyBoard(date: selectedDate, memberID: memberID, wide: wide) { id in
                        appointmentDraft = AppointmentDraft(start: selectedDate, end: selectedDate.addingTimeInterval(3600), memberID: id)
                    }
                    appleCalendars

                }.padding(20).frame(maxWidth: 1200).frame(maxWidth: .infinity)
            }.background(AppTheme.canvas)
        }
        .tint(AppTheme.slate)
        .householdHelp(.calendar)
        .navigationTitle("Calendar").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button("Calendar settings", systemImage: "slider.horizontal.3") { settings = true }.accessibilityIdentifier("calendar.settings")
            Button("Add appointment", systemImage: "plus") { appointmentDraft = AppointmentDraft(start: selectedDate, end: selectedDate.addingTimeInterval(3600), memberID: memberID) }.accessibilityIdentifier("calendar.add") }
        .sheet(item: $appointmentDraft) { AppointmentEditorView(draft: $0) }
        .sheet(isPresented: $settings) { CalendarSettingsView() }
        .task(id: "\(selectedDate.timeIntervalSince1970)-\(connections.revision)") { await connections.refreshEvents(on: selectedDate) }
        .refreshable { await connections.refreshEvents(on: selectedDate) }
    }

    private var monthPicker: some View {
        DatePicker("Choose a day", selection: $selectedDate, displayedComponents: .date)
            .datePickerStyle(.graphical).padding(8)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private func shiftDay(_ value: Int) {
        selectedDate = Calendar.current.date(byAdding: .day, value: value, to: selectedDate) ?? selectedDate
    }

    private var memberFilters: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                memberButton("Everyone", id: nil)
                ForEach(repository.members) { member in memberButton(member.displayName, id: member.id) }
            }
        }.scrollIndicators(.hidden)
    }

    private func memberButton(_ name: String, id: UUID?) -> some View {
        Button { memberID = id } label: {
            VStack(spacing: 6) {
                if id == nil {
                    Image(systemName: "person.2.fill").font(.headline).frame(width: 46, height: 46)
                        .background(AppTheme.sage.opacity(0.12), in: Circle()).accessibilityHidden(true)
                } else { CalendarPersonAvatar(name: name, id: id) }
                Text(name).font(.caption.weight(.semibold)).foregroundStyle(.primary)
            }.padding(8)
                .background(memberID == id ? Color.primary.opacity(0.06) : Color.clear, in: RoundedRectangle(cornerRadius: 18))
                .overlay { RoundedRectangle(cornerRadius: 18).strokeBorder(memberID == id ? Color.primary.opacity(0.35) : Color.clear) }

        }.buttonStyle(.plain).accessibilityAddTraits(memberID == id ? .isSelected : [])
            .accessibilityIdentifier("calendar.member.\(name)")
    }

    private var appleCalendars: some View {
        VStack(alignment: .leading, spacing: 16) {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 14) {
                    NavigationLink("Choose connected calendars") { ConnectionsView() }
                        .accessibilityIdentifier("calendar.connections").frame(minHeight: 44)
                    Text("Apple events are shown from calendars connected on this device, separately from household member filters.")
                        .font(.caption).foregroundStyle(.secondary)
                    if connections.calendarEnabled {
                        ForEach(connections.events) { event in
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.title).font(.headline)
                                    Text(event.allDay ? "All day" : "\(event.start.formatted(date: .omitted, time: .shortened)) – \(event.end.formatted(date: .omitted, time: .shortened))")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                }
                            } icon: { Image(systemName: "calendar") }
                                .accessibilityIdentifier("calendar.external.\(event.id)")
                        }
                        if let error = connections.calendarError { Text(error).font(.footnote).foregroundStyle(.secondary) }
                        else if connections.events.isEmpty { Text("No selected Apple events on this day.").foregroundStyle(.secondary) }
                    }
                }.padding(.top, 12)
            } label: { Label("Apple Calendar", systemImage: "calendar") }
                .padding(18).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        }
    }
}

struct EventRow: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    let event: FamilyEvent
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 2).fill(AppTheme.accent).frame(width: 3, height: 48).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(event.title).font(.headline).foregroundStyle(AppTheme.ink)
                Text("\(event.startAt.formatted(date: .omitted, time: .shortened)) – \(event.endAt.formatted(date: .omitted, time: .shortened))")
                    .font(.subheadline).foregroundStyle(AppTheme.muted)
                Label(repository.memberName(event.assignedMemberID), systemImage: "person.crop.circle")
                    .font(.caption.weight(.medium)).foregroundStyle(AppTheme.accent)
            }.frame(maxWidth: .infinity, alignment: .leading)
        }.padding(.vertical, 6)
    }
}

struct EventDetailView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    let event: FamilyEvent
    @State private var editing = false
    var body: some View {
        Form {
            Label(AppointmentKind(rawValue: event.appointmentKind ?? "")?.rawValue ?? "Appointment", systemImage: AppointmentKind(rawValue: event.appointmentKind ?? "")?.symbol ?? "calendar")
            if let minutes = event.reminderMinutes { LabeledContent("Reminder", value: minutes == 0 ? "At start time" : "\(minutes) minutes before") }
            LabeledContent("Starts", value: event.startAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Ends", value: event.endAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("For", value: repository.memberName(event.assignedMemberID))
            if let notes = event.notes, !notes.isEmpty { Section("Notes") { Text(notes) } }
            Section("Apple apps") {
                if let link = repository.calendarDeliveryLinks.first(where: { $0.eventID == event.id }) {
                    Label(link.calendarName, systemImage: "calendar")
                    Text(link.error ?? (link.deleteRequested ? "Apple removal pending" : !link.enabled ? "Paused · Apple copy kept" : link.sentRevision == event.modifiedAt ? "Last update sent" : "Apple update pending"))
                        .font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("event.appleStatus")
                    NavigationLink("Review sync status") { CalendarDeliverySettingsView() }
                }

                Button("Manage Apple Calendar link", systemImage: "calendar.badge.plus") { editing = true }
                    .accessibilityIdentifier("event.export")
                NavigationLink("Share as a note") {
                    NotesSharingView(text: "\(event.title)\n\(event.startAt.formatted()) – \(event.endAt.formatted())\n\n\(event.notes ?? "")")
                }
                Text("Enable Apple Calendar in the editor to keep its title, time, and notes updated from Nam Illam. The link is managed on this device.").font(.footnote).foregroundStyle(.secondary)
            }
            Section { Text("Nam Illam event · Stored on this device").foregroundStyle(.secondary) }
        }.hearthList().navigationTitle(event.title)
            .toolbar { Button("Edit") { editing = true } }
            .sheet(isPresented: $editing) { AppointmentEditorView(event: event) }

    }
}
