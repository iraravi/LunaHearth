import SwiftUI

struct MoreView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @AppStorage("warranty.horizon") private var horizon = 30
    @State private var confirmReset = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(alignment: .top, spacing: 16) {
                        HearthIcon(symbol: "house.fill")
                        ScreenIntro(eyebrow: "Your household", title: repository.household?.name ?? "Your household",
                                    subtitle: "Household members: \(repository.members.count)")
                    }.padding(.vertical, 12)
                }.listRowBackground(Color.clear)
                Section("Household") {
                    NavigationLink { FamilyView() } label: { Label("Family", systemImage: "person.3") }
                    NavigationLink {
                        ContentUnavailableView("Your household documents", systemImage: "doc.text", description: Text("Document import and preview are planned for a future release. No files are being read or uploaded."))
                            .navigationTitle("Documents")
                    } label: { Label("Documents", systemImage: "doc.text") }
                }
                Section {
                    LabeledContent("Storage", value: "This Device")
                    NavigationLink { BackupView() } label: { Label("iCloud backup", systemImage: "icloud") }
                        .accessibilityIdentifier("more.backup")
                    Text("Your household is saved locally. No account, tracking, or network connection is required. You can optionally save a private iCloud backup. Live family sharing and Apple Calendar connections are not available in this build.")
                        .font(.footnote).foregroundStyle(.secondary)
                } header: { Text("Privacy & Sync") }
                Section("Settings") {
                    Picker("Warranty alerts", selection: $horizon) {
                        ForEach([7, 30, 60], id: \.self) { Text("\($0) days ahead").tag($0) }
                    }
                }
                Section { Text("LunaHearth · NeuralLuna").foregroundStyle(.secondary) }
                #if DEBUG
                Section("Developer tools") {
                    Button("Reset Local Household", role: .destructive) { confirmReset = true }
                }
                #endif
            }.hearthList().navigationTitle("More").navigationBarTitleDisplayMode(.inline)
                .saveError($error)
                .confirmationDialog("Delete all household records on this device? This cannot be undone.", isPresented: $confirmReset, titleVisibility: .visible) {
                    #if DEBUG
                    Button("Delete Local Household", role: .destructive) {
                        do { try repository.resetLocalData() } catch { self.error = userFacingError(error) }
                    }
                    #endif
                }
        }
    }
}

struct FamilyView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var name = ""
    @State private var role: MemberRole = .adult
    @State private var error: String?
    var body: some View {
        Form {
            Section(repository.household?.name ?? "Household") {
                if repository.members.isEmpty { Text("Add people to assign household events and tasks.").foregroundStyle(.secondary) }
                ForEach(repository.members) { member in LabeledContent(member.displayName, value: member.role.rawValue.capitalized) }
            }
            Section {
                TextField("Display name", text: $name)
                Picker("Profile", selection: $role) {
                    Text("Adult").tag(MemberRole.adult)
                    Text("Child").tag(MemberRole.child)
                }
                Button("Add Person") {
                    do { try repository.addMember(name: name, role: role); name = "" }
                    catch { self.error = userFacingError(error) }
                }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } header: { Text("Add to household") } footer: { Text("These are local profiles managed by adults, not accounts or sharing invitations.") }
        }.hearthList().navigationTitle("Family").saveError($error)
    }
}
