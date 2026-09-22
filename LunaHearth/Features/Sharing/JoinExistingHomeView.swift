import SwiftUI

struct JoinExistingHomeView: View {
    @Environment(HouseholdSharingController.self) private var sharing
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var link = ""
    var body: some View {
        Form {
            Section {
                Label("One home, together", systemImage: "person.2.fill").font(AppTheme.sectionTitle)
                Text("Open the household invitation in Mail or Messages. You can also paste its iCloud link here. You don’t need to create another home.")
            }
            Section("Invitation link") {
                TextField("https://www.icloud.com/share/…", text: $link)
                    .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL)
                    .accessibilityIdentifier("sharing.invitationLink")
                Button("Open invitation") { Task { await sharing.lookupInvitation(link) } }
                    .disabled(HouseholdInvitationLink.url(from: link) == nil || sharing.lookingUpInvitation)
                    .accessibilityIdentifier("sharing.openLink")
            }
            Section {
                Button("Find homes I’ve already joined", systemImage: "icloud.and.arrow.down") {
                    Task { await sharing.findHomes(repository) }
                }.accessibilityIdentifier("sharing.findJoined")
                if sharing.working { ProgressView("Checking iCloud…") }
                ForEach(sharing.availableHomes) { home in
                    Button("Open \(home.name)") { Task { await sharing.open(home.destination, repository: repository) } }
                }
                if let message = sharing.message { Text(message).foregroundStyle(.secondary) }
                if sharing.searched && sharing.availableHomes.isEmpty && sharing.message == nil {
                    Text("No joined homes found. Open the invitation link first.").foregroundStyle(.secondary)
                }
            } footer: { Text("This finds homes already available to your iCloud account. Pending invitations must be opened using their link.") }
        }.hearthList().navigationTitle("Join a home").navigationBarTitleDisplayMode(.inline)
    }
}
