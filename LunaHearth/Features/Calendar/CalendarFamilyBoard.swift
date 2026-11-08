import SwiftUI

/// A person-first view of the existing household schedule. It never creates sample events.
struct CalendarFamilyBoard: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    let date: Date
    let memberID: UUID?
    let wide: Bool
    let add: (UUID?) -> Void

    private var members: [HouseholdMember] {
        repository.members.filter { memberID == nil || $0.id == memberID }
    }
    private var unassigned: [FamilyEvent] {
        repository.events(on: date).filter { event in
            event.assignedMemberID == nil || !repository.members.contains { $0.id == event.assignedMemberID }
        }
    }

    private func tasks(for id: UUID?) -> [HouseholdTask] {
        repository.tasks.filter { task in
            let owner = repository.members.contains { $0.id == task.assignedMemberID } ? task.assignedMemberID : nil
            return owner == id && CalendarTaskVisibility.includes(due: task.dueAt, completed: task.isCompleted, day: date)
        }.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            return ($0.dueAt ?? .distantFuture, $0.id.uuidString) < ($1.dueAt ?? .distantFuture, $1.id.uuidString)
        }
    }

    var body: some View {
        LazyVGrid(columns: wide ? [GridItem(.adaptive(minimum: 320), spacing: 16, alignment: .top)] : [GridItem(.flexible(), alignment: .top)], alignment: .leading, spacing: 16) {
            ForEach(members) { member in
                personColumn(name: member.displayName, id: member.id,
                             events: repository.events(on: date).filter { $0.assignedMemberID == member.id })
            }
            if memberID == nil && (!unassigned.isEmpty || !tasks(for: nil).isEmpty || members.isEmpty) {
                personColumn(name: "Household", id: nil, events: unassigned)
            }
        }
    }

    private func personColumn(name: String, id: UUID?, events: [FamilyEvent]) -> some View {
        let tint = CalendarPersonStyle.color(id)
        let assignedTasks = tasks(for: id)
        return VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                CalendarPersonAvatar(name: name, id: id)
                VStack(alignment: .leading, spacing: 4) {
                    Text(name).font(.title2.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                    Text("\(events.count) plans · \(assignedTasks.filter { !$0.isCompleted }.count) open tasks")
                        .font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
                Button { add(id) } label: {
                    Image(systemName: "plus").font(.body.weight(.semibold)).frame(width: 44, height: 44)
                        .background(AppTheme.surface, in: Circle())
                }.buttonStyle(.plain).accessibilityLabel("Add appointment for \(name)")
                    .accessibilityIdentifier("calendar.addMember.\(name)")
            }
            if events.isEmpty && assignedTasks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("An open day", systemImage: "sun.horizon").font(.headline)
                    Text("Appointments and assigned tasks for \(name) appear here.").font(.subheadline).foregroundStyle(.secondary)
                }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppTheme.surface.opacity(0.75), in: RoundedRectangle(cornerRadius: 20))
            }
            if !assignedTasks.isEmpty {
                Label("Tasks & reminders", systemImage: "checklist").font(.subheadline.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                ForEach(assignedTasks) { task in
                    TaskRow(task: task).padding(14).frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            ForEach(CalendarDayPeriod.allCases, id: \.self) { period in
                let appointments = events.filter { CalendarDayPeriod.period(start: $0.startAt, on: date) == period }
                    .sorted { $0.startAt == $1.startAt ? $0.id.uuidString < $1.id.uuidString : $0.startAt < $1.startAt }
                if !appointments.isEmpty {
                    Label(period.rawValue, systemImage: period.symbol).font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary).accessibilityAddTraits(.isHeader)
                    ForEach(appointments) { event in
                        NavigationLink { EventDetailView(event: event) } label: {
                            VStack(alignment: .leading, spacing: 0) {
                                if !typeSize.isAccessibilitySize {
                                    HStack {
                                        Image(systemName: AppointmentKind(rawValue: event.appointmentKind ?? "")?.symbol ?? period.symbol).symbolRenderingMode(.monochrome).foregroundStyle(AppTheme.slate)
                                            .font(.system(size: 34)).accessibilityHidden(true)
                                        Spacer()
                                        Text(event.startAt, format: .dateTime.hour().minute())
                                            .font(.subheadline.weight(.semibold))
                                    }.padding(16).frame(maxWidth: .infinity)
                                        .background(tint.opacity(0.12))
                                }
                                VStack(alignment: .leading, spacing: 9) {
                                    Text(event.title).font(.headline).fixedSize(horizontal: false, vertical: true)
                                    Label(event.startAt.formatted(date: Calendar.current.isDate(event.startAt, inSameDayAs: event.endAt) ? .omitted : .abbreviated, time: .shortened)
                                          + " – " + event.endAt.formatted(date: Calendar.current.isDate(event.startAt, inSameDayAs: event.endAt) ? .omitted : .abbreviated, time: .shortened), systemImage: "clock")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                    Label(name, systemImage: "person.crop.circle").font(.caption.weight(.medium))
                                }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            }.background(AppTheme.surface).clipShape(RoundedRectangle(cornerRadius: 20))
                                .contentShape(Rectangle())
                        }.buttonStyle(.plain).entryActions(.editing(event))
                            .accessibilityIdentifier("calendar.event.\(event.id)")
                    }
                }
            }
        }.padding(18).frame(maxWidth: .infinity, alignment: .topLeading)
            .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(tint.opacity(0.1)) }
    }
}

enum CalendarPersonStyle {
    static func color(_ id: UUID?) -> Color {
        guard let id else { return AppTheme.sage }
        let palette: [Color] = [AppTheme.slate, AppTheme.sage, AppTheme.clay, AppTheme.rose, AppTheme.ochre, AppTheme.plum]
        let index = id.uuidString.utf8.reduce(0) { ($0 + Int($1)) % palette.count }
        return palette[index]
    }
}

struct CalendarPersonAvatar: View {
    let name: String
    let id: UUID?
    var body: some View {
        Text(name.split(whereSeparator: \.isWhitespace).prefix(2).compactMap(\.first).map(String.init).joined().uppercased())
            .font(.headline).frame(width: 46, height: 46)
            .background(CalendarPersonStyle.color(id).opacity(0.16), in: Circle())
            .overlay { Circle().strokeBorder(CalendarPersonStyle.color(id).opacity(0.35), lineWidth: 1.5) }
            .accessibilityHidden(true)
    }
}
