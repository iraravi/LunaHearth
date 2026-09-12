import SwiftUI

struct CalendarView: View {
    var body: some View { NavigationStack { CalendarAgendaView() } }
}

struct CalendarAgendaView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var selectedDate = Date.now
    @State private var adding = false
    @State private var memberID: UUID?

    var body: some View {
        List {
            Section {
                ScreenIntro(eyebrow: "Family calendar", title: "Your plans. Together.",
                            subtitle: "Choose a date to see your household schedule.")
                HearthArtwork(name: "HearthPlanning", height: 110)
            }.listRowBackground(Color.clear).listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 12, trailing: 12))
            Section {
                DatePicker("Day", selection: $selectedDate, displayedComponents: .date).datePickerStyle(.graphical)
                Picker("Show", selection: $memberID) {
                    Text("Everyone").tag(nil as UUID?)
                    ForEach(repository.members) { Text($0.displayName).tag(Optional($0.id)) }
                }
            }
            Section(selectedDate.formatted(date: .complete, time: .omitted)) {
                let events = repository.events(on: selectedDate).filter { memberID == nil || $0.assignedMemberID == memberID }
                if events.isEmpty {
                    ContentUnavailableView("An open day", systemImage: "calendar", description: Text("Tap + to add a family event. No Calendar permission needed."))
                }
                ForEach(events) { event in NavigationLink { EventDetailView(event: event) } label: { EventRow(event: event) }.entryActions(.editing(event)) }
            }
        }
        .hearthList()
        .navigationTitle("Calendar").navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Add Event", systemImage: "plus") { adding = true }.accessibilityIdentifier("calendar.add") }
        .sheet(isPresented: $adding) { QuickAddView(kind: .event, date: selectedDate) }
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
            LabeledContent("Starts", value: event.startAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Ends", value: event.endAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("For", value: repository.memberName(event.assignedMemberID))
            if let notes = event.notes, !notes.isEmpty { Section("Notes") { Text(notes) } }
            Section { Text("LunaHearth event · Stored on this device").foregroundStyle(.secondary) }
        }.hearthList().navigationTitle(event.title)
            .toolbar { Button("Edit") { editing = true } }
            .sheet(isPresented: $editing) { QuickAddView(draft: .editing(event)) }
    }
}
