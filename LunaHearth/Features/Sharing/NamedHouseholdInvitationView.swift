import SwiftUI

struct NamedHouseholdInvitationView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(HouseholdSharingController.self) private var sharing
    @Environment(\.dismiss) private var dismiss
    @State private var ownerName = ""
    @State private var name = ""
    @State private var email = ""
    @State private var invitationURL: URL?
    @State private var sendMethod: InvitationSendMethod?
    @State private var delivery: InvitationDeliveryStatus = .ready
    @State private var error: String?
    @State private var preparing = false
    @State private var showError = false
    private enum Field: Hashable { case owner, name, email }
    @FocusState private var focusedField: Field?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label(invitationURL == nil ? "Invite someone" : "Invitation for \(name)", systemImage: "person.2.fill").font(AppTheme.sectionTitle)
                    if invitationURL == nil {
                        Text("Enter their iCloud email, then send the invitation through Mail or Messages. Their profile is selected automatically when they join.")
                            .foregroundStyle(.secondary)
                    }
                }.listRowBackground(Color.clear)
                if invitationURL != nil {
                    Section {
                        Text(delivery.title).font(.headline).accessibilityIdentifier("sharing.named.deliveryStatus")
                        LabeledContent("For", value: name)
                        LabeledContent("iCloud email", value: email)
                        Text(delivery.detail).font(.subheadline).foregroundStyle(.secondary)
                        Button { delivery = .ready; sendMethod = .preferred } label: {
                            Label(InvitationSendMethod.preferred == .mail ? "Email invitation" : "Send invitation link", systemImage: "paperplane")
                        }.accessibilityIdentifier("sharing.named.send")
                        if InvitationSendMethod.preferred == .mail {
                            Button("Use Messages or another app") { delivery = .ready; sendMethod = .share }
                        }
                        Text("Already joined? Their named profile appears after syncing; another invitation is not required.")
                            .font(.caption).foregroundStyle(.secondary)

                    }
                } else {
                    Section("Your name in this home") {
                        TextField("Your name", text: $ownerName).textContentType(.givenName)
                            .focused($focusedField, equals: .owner)
                            .accessibilityIdentifier("sharing.named.owner")
                    }
                    Section {
                        TextField("Name, e.g. Kira", text: $name).textContentType(.givenName)
                            .focused($focusedField, equals: .name)
                            .accessibilityIdentifier("sharing.named.name")
                        TextField("Their iCloud email", text: $email)
                            .textContentType(.emailAddress).keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never).autocorrectionDisabled()
                            .focused($focusedField, equals: .email).submitLabel(.done).onSubmit { focusedField = nil }
                            .accessibilityIdentifier("sharing.named.email")
                    } header: { Text("Who is joining?") } footer: {
                        Text("Use the Apple Account signed into iCloud on their device. They will be able to view and edit this shared home.")
                    }
                    Section {
                        Button {
                            focusedField = nil; error = nil; preparing = true
                            Task {
                                defer { preparing = false }
                                do {
                                    invitationURL = try await sharing.prepareNamedInvitation(ownerName: ownerName, name: name,
                                        email: email.trimmingCharacters(in: .whitespacesAndNewlines), repository: repository)
                                    delivery = .ready
                                    sendMethod = .preferred
                                } catch { self.error = error.localizedDescription; showError = true }
                            }
                        } label: {
                            HStack {
                                Label("Continue to send", systemImage: "person.badge.plus")
                                Spacer()
                                if preparing { ProgressView() } else { Image(systemName: "chevron.right").font(.footnote) }
                            }
                        }.accessibilityIdentifier("sharing.named.prepare")
                            .disabled(preparing || ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !email.contains("@"))
                    }
                }
                if let error { Section { Text(error).foregroundStyle(.secondary).accessibilityIdentifier("sharing.named.error") } }
            }.navigationTitle("Invite family").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.disabled(preparing) } }
                .onAppear {
                    ownerName = repository.members.first { $0.role == .owner }?.displayName ?? ""
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
                       ProcessInfo.processInfo.arguments.contains("--ui-testing-ready-invitation") {
                        name = "Kira"; email = "kira@example.com"
                        invitationURL = URL(string: "https://www.icloud.com/share/ui-test-invitation")
                    }
                    #endif
                }
                .sheet(item: $sendMethod, onDismiss: { if delivery == .ready { delivery = .cancelled } }) { method in
                    if let invitationURL {
                        InvitationSendSheet(method: method, recipient: email.trimmingCharacters(in: .whitespacesAndNewlines),
                            homeName: repository.household?.name ?? "Our Home", url: invitationURL) { result in
                                delivery = result
                                sendMethod = nil
                            }
                    }
                }
                .alert("Invitation could not be prepared", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: { Text(error ?? "Please try again.") }
                .interactiveDismissDisabled(preparing)
                .disabled(preparing)
        }
    }
}
