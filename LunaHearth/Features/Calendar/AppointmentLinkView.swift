import SwiftUI

struct AppointmentLinkView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    let link: AppointmentLink
    var body: some View {
        if repository.household == nil {
            NavigationStack {
                ContentUnavailableView("Your household comes first", systemImage: "house", description: Text("Create or join a household, then ask Siri again."))
                    .toolbar { Button("Done") { dismiss() } }
            }
        } else if link.create {
            let matches = repository.members.filter { $0.displayName.localizedCaseInsensitiveCompare(link.member) == .orderedSame }
            AppointmentEditorView(draft: AppointmentDraft(title: link.title, start: link.date, end: link.date.addingTimeInterval(3600), memberID: matches.count == 1 ? matches.first?.id : nil,
                notes: !link.member.isEmpty && matches.count != 1 ? "Requested person: \(link.member). Choose the correct household member before saving." : ""))
        } else {
            NavigationStack { CalendarAgendaView(date: link.date).toolbar { Button("Done") { dismiss() } } }
        }
    }
}
