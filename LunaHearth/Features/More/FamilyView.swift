import SwiftUI

struct FamilyView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(PersonalShopping.self) private var personal
    @Environment(HouseholdSharingController.self) private var sharing
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var openingSharing = false
    @State private var sharingError: String?
    @State private var addingProfile = false
    @State private var renamingMember: HouseholdMember?
    @State private var enablingSharing = false

    private var canEdit: Bool {
        repository.syncConfiguration?.readOnly != true && repository.syncConfiguration?.recovery != true
    }
    private var canInvite: Bool { canEdit && repository.syncConfiguration?.enabled == true && repository.syncConfiguration?.isOwner == true }
    private var selectedMember: UUID? {
        repository.linkedCloudMemberID ?? repository.household.flatMap { personal.memberID($0.id) }
    }
    var body: some View {
        @Bindable var sharing = sharing
        GeometryReader { geometry in
            let wide = geometry.size.width >= 820 && !typeSize.isAccessibilitySize
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    if wide {
                        HStack(alignment: .top, spacing: 24) {
                            roster.frame(maxWidth: .infinity)
                            actions.frame(maxWidth: .infinity)
                        }
                    } else {
                        actions
                        roster
                    }
                }.frame(maxWidth: 1000).padding(20).frame(maxWidth: .infinity)
            }.accessibilityIdentifier("family.content")
        }.background(AppTheme.canvas)
            .foregroundStyle(.primary).tint(.primary)
            .householdHelp(.family)
        .navigationTitle("Family").navigationBarTitleDisplayMode(.inline)
            .saveError($sharingError)
            .sheet(isPresented: $addingProfile) { FamilyProfileForm() }
            .sheet(item: $renamingMember) { member in FamilyMemberNameForm(member: member) }
            .confirmationDialog("Enable private family sharing?", isPresented: $enablingSharing, titleVisibility: .visible) {
                Button("Enable sharing") { Task { await sharing.enable(repository) } }
            } message: {
                Text("Uploads this home’s profiles, plans, lists and home details to your private iCloud storage. No one else gets access until you invite them.")
            }
            .sheet(item: $sharing.shareTicket, onDismiss: { Task { await sharing.sync(repository, force: true) } }) { ticket in
                if let service = sharing.service as? CloudKitHouseholdService {
                    CloudSharingSheet(ticket: ticket, service: service,
                        onError: { sharing.report($0, repository: repository) },
                        onChanged: { Task { await sharing.sync(repository, force: true) } })
                }
            }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !typeSize.isAccessibilitySize {
                HStack(spacing: -8) {
                    avatar(symbol: "person.fill", color: .teal, size: 46)
                    avatar(symbol: "person.fill", color: .indigo, size: 62)
                    avatar(symbol: "person.fill", color: .orange, size: 46)
                }.accessibilityHidden(true)
            }
            Text("Your people, together.").font(AppTheme.sectionTitle)
            Text(repository.household?.name ?? "Your home").font(.subheadline).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(22)
            .background(AppTheme.slate.opacity(colorScheme == .dark ? 0.12 : 0.055), in: RoundedRectangle(cornerRadius: 20))
    }
    private func avatar(symbol: String, color: Color, size: CGFloat) -> some View {
        Image(systemName: symbol).font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(color).frame(width: size, height: size)
            .background(color.opacity(0.12), in: Circle())
            .overlay(Circle().stroke(AppTheme.canvas, lineWidth: 3))
    }
    private var actions: some View {
        VStack(alignment: .leading, spacing: 12) {
            if repository.syncConfiguration?.recovery == true {
                actionMessage("Sharing needs attention", detail: "Your saved profiles are safe. Reconnect this home before making changes.", symbol: "icloud.slash")
            } else if repository.syncConfiguration?.enabled == false {
                actionMessage("Sharing is paused", detail: "Open sharing settings to review this home’s connection before inviting someone.", symbol: "icloud.slash")
            } else if repository.syncConfiguration == nil {
                actionMessage("Bring everyone into this home", detail: "Enable private iCloud sharing, then invite each person using the name you want to see here.", symbol: "person.badge.plus")
            } else if canInvite {
                Button { openAppleSharing() } label: {
                    actionMessage("Invite someone", detail: "Send with Mail or Messages using Apple’s sharing screen.", symbol: "person.badge.plus", chevron: true)
                }.buttonStyle(.plain).disabled(openingSharing).accessibilityIdentifier("family.invite")
            } else {
                actionMessage("One home, shared with you", detail: "The home owner sends invitations. You can view this home’s sharing details below.", symbol: "person.2")
            }
            if repository.syncConfiguration?.recovery == true || repository.syncConfiguration?.enabled == false {
                NavigationLink { HouseholdSharingView() } label: {
                    accessLabel("Review iCloud connection", symbol: "icloud.slash")
                }.buttonStyle(.plain).accessibilityIdentifier("family.sharing")
            } else {
                Button {
                    if repository.syncConfiguration == nil { enablingSharing = true }
                    else { openAppleSharing() }
                } label: {
                    accessLabel(repository.syncConfiguration == nil ? "Enable family sharing" : "Invitations & access", symbol: "person.2.badge.gearshape")
                }.buttonStyle(.plain).disabled(openingSharing).accessibilityIdentifier("family.sharing")
            }
            if openingSharing { ProgressView("Opening Apple sharing…") }
            if let message = sharing.message {
                Text(message).font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("family.sharingStatus")
            }

        }
    }
    private func openAppleSharing() {
        guard !openingSharing else { return }
        openingSharing = true
        Task {
            defer { openingSharing = false }
            await sharing.prepareInvitation(repository)
            if sharing.shareTicket == nil {
                sharingError = sharing.message ?? "Apple sharing could not open. Please try again."
            }
        }
    }
    private func accessLabel(_ title: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            if !typeSize.isAccessibilitySize { Image(systemName: symbol).accessibilityHidden(true) }
            Text(title).font(.subheadline.weight(.semibold))
            Spacer(minLength: 4)
            Image(systemName: "chevron.right").font(.caption).accessibilityHidden(true)
        }.padding(.vertical, 12).contentShape(Rectangle())
    }
    private func actionMessage(_ title: String, detail: String, symbol: String, chevron: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 14) {
            if !typeSize.isAccessibilitySize {
                Image(systemName: symbol).font(.title3).foregroundStyle(AppTheme.sage).frame(width: 30).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }.fixedSize(horizontal: false, vertical: true)
            if chevron { Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.secondary).accessibilityHidden(true) }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(18)
            .background(AppTheme.sage.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))
            .contentShape(RoundedRectangle(cornerRadius: 18)).accessibilityElement(children: .combine)
    }
    private var roster: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("People in this home").font(.headline).accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                if repository.members.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your family starts here").font(.headline)
                        Text("A profile appears automatically when each person joins. You can name it here.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
                        .accessibilityIdentifier("family.empty")
                }
                ForEach(Array(repository.members.enumerated()), id: \.element.id) { index, member in
                    if index > 0 { Divider().padding(.leading, 78).padding(.trailing, 18) }
                    HStack(spacing: 14) {
                        Text(String(member.displayName.prefix(1)).uppercased())
                            .font(.title3.weight(.semibold)).foregroundStyle(index.isMultiple(of: 2) ? Color.teal : Color.indigo)
                            .frame(width: 46, height: 46).background((index.isMultiple(of: 2) ? Color.teal : Color.indigo).opacity(0.1), in: Circle())
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(member.displayName).font(.headline)
                            Text(member.role == .owner ? "Home owner" : member.role == .child ? "Child profile" : member.role == .guest ? "Guest profile" : "Adult profile")
                                .font(.caption).foregroundStyle(.secondary)
                            if selectedMember == member.id { Label("You", systemImage: "checkmark.circle.fill").font(.caption.weight(.medium)).foregroundStyle(.secondary) }
                        }.fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        if canEdit && repository.syncConfiguration?.isOwner != false {
                            Button { renamingMember = member } label: {
                                Image(systemName: "pencil").frame(minWidth: 44, minHeight: 44)
                            }.buttonStyle(.plain).accessibilityLabel("Rename \(member.displayName)")
                                .accessibilityIdentifier("family.rename.\(member.id)")
                        }
                    }.padding(18).accessibilityElement(children: .contain)
                        .accessibilityIdentifier("family.member.\(member.id)")
                }
            }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            if repository.syncConfiguration != nil {
                Text("Names sync across this home. One iCloud account uses the same profile on all its devices. See invitation status in Invitations & access.").font(.caption).foregroundStyle(.secondary)
            }
            if canEdit {
                Button { addingProfile = true } label: {
                    Label("Add someone without a device", systemImage: "person.crop.circle.badge.plus")
                        .font(.subheadline.weight(.medium)).frame(minHeight: 44, alignment: .leading)
                }.buttonStyle(.plain).accessibilityIdentifier("family.addProfile")
                Text("For someone whose tasks you manage here, such as a child. This does not send an invitation.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct FamilyProfileForm: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @FocusState private var editingName: Bool
    @State private var name = ""
    @State private var role: MemberRole = .adult
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display name", text: $name).textContentType(.givenName).focused($editingName)
                        .accessibilityIdentifier("family.profileName")
                    Picker("Profile type", selection: $role) {
                        Text("Adult").tag(MemberRole.adult)
                        Text("Child").tag(MemberRole.child)
                    }
                } header: { Text("Who is this for?") } footer: {
                    Text("Use this profile to assign tasks and shopping. No Apple Account or invitation is needed. To connect a device, use Invite someone instead.")
                }
            }.navigationTitle("Add a profile").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Add Person") {
                            do { try repository.addMember(name: name, role: role); editingName = false; dismiss() }
                            catch { self.error = userFacingError(error) }
                        }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || repository.syncConfiguration?.readOnly == true || repository.syncConfiguration?.recovery == true)
                            .accessibilityIdentifier("family.saveProfile")
                    }
                }.saveError($error)
        }
    }
}

private struct FamilyMemberNameForm: View {
    let member: HouseholdMember
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section("Name in this home") {
                    TextField("Name", text: $name).textContentType(.givenName)
                        .accessibilityIdentifier("family.renameName")
                }
                Section {
                    Text("This name appears on everyone's devices. Tasks stay assigned to the same person.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }.navigationTitle("Name this person").navigationBarTitleDisplayMode(.inline)
                .onAppear { name = member.displayName }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            do { try repository.renameFamilyMember(member.id, name: name); dismiss() }
                            catch { self.error = error.localizedDescription }
                        }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .accessibilityIdentifier("family.renameSave")
                    }
                }.saveError($error)
        }
    }
}
