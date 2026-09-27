import SwiftUI

/// Home creation stays separate from profiles, room setup and iCloud sharing.
struct OnboardingView: View {
    var onCreated: () -> Void = {}
    var isTour = false
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var started = false
    @State private var privacyExpanded = false
    @State private var name = ""
    @State private var error: String?
    @FocusState private var focusedSetupField: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if started { setup } else { welcome }
                }
                .padding(24).frame(maxWidth: 700, alignment: .leading).frame(maxWidth: .infinity)
            }
            .background(WelcomeStyle.canvas).foregroundStyle(WelcomeStyle.ink).tint(WelcomeStyle.ink)
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom) { bottomBar }
            .navigationTitle(isTour ? (started ? "Setup preview" : "Welcome") : (started ? "Create a home" : ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedSetupField = nil }.accessibilityIdentifier("setup.keyboardDone")
                }
                if started { ToolbarItem(placement: .cancellationAction) { Button("Back") { started = false } } }
                if isTour { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            }
            .saveError($error)
        }.tint(WelcomeStyle.ink)
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("LUNAHEARTH").font(.caption.weight(.medium)).tracking(3).foregroundStyle(WelcomeStyle.muted)
            if !typeSize.isAccessibilitySize { WelcomePhotograph(name: "WelcomeResidence", height: 220) }
            Text("Make yourself at home.").font(WelcomeStyle.heading).fixedSize(horizontal: false, vertical: true)
            Text("Keep shopping, pantry items, meals and plans together in one home. Use it on your own or share it with family.")
                .font(.body).foregroundStyle(WelcomeStyle.muted).lineSpacing(3)
            Divider()
            VStack(alignment: .leading, spacing: 18) {
                Text("Choose how to start").font(.headline)
                privacyRow("New to LunaHearth?", detail: "Choose Create a new home. Give it a name, then start adding your own items.", symbol: "house")
                privacyRow("Someone invited you?", detail: "Choose Join an existing home. Open the invitation from Mail or Messages to use the same home as your family.", symbol: "person.2")
                privacyRow("Used the app before?", detail: "Choose Restore from iCloud if you saved a backup of your home.", symbol: "icloud.and.arrow.down")
            }.accessibilityIdentifier("setup.startInstructions")
            privacy
        }
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !typeSize.isAccessibilitySize { WelcomePhotograph(name: "WelcomeResidence", height: 150) }
            Label("One required step · Name your home", systemImage: "house")
                .font(.subheadline.weight(.medium)).foregroundStyle(WelcomeStyle.muted)
                .accessibilityIdentifier("setup.progress")
            Text("What would you like to call your home?").font(WelcomeStyle.heading).fixedSize(horizontal: false, vertical: true)
            Text("This name labels your shared space in the app. It isn’t your address or an account name.")
                .foregroundStyle(WelcomeStyle.muted)
            VStack(alignment: .leading, spacing: 10) {
                Text("Home name").font(.subheadline.weight(.medium))
                setupField("e.g. Our Home", text: $name, identifier: "setup.householdName")
                Text("For example, Our Home or Kira Home. Choose a name everyone will recognize.")
                    .font(.footnote).foregroundStyle(WelcomeStyle.muted)
            }
            privacyRow("What happens next?", detail: "Tap Create my home to open the app. Your home starts empty. Adding pantry items, shopping, rooms and family members is optional; the getting-started guide can help when you’re ready.", symbol: "arrow.right.circle")
            privacy
        }
    }

    private var privacy: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
            Text("Saved on this device. iCloud is optional.").font(.subheadline).foregroundStyle(WelcomeStyle.muted)
            DisclosureGroup("Your privacy", isExpanded: $privacyExpanded) {
                VStack(alignment: .leading, spacing: 16) {
                    privacyRow("No app account", detail: "Your home works offline. Plans, lists and details save on this device.", symbol: "iphone")
                    privacyRow("Sharing is your choice", detail: "Enable iCloud sync or join a shared home only when you choose.", symbol: "icloud")
                    privacyRow("Optional on-device AI", detail: "Apple’s AI can help when available. You review suggestions before saving; no cloud AI service is used.", symbol: "sparkles")
                }.padding(.top, 14)
            }.font(.subheadline).padding(.vertical, 4)
        }.accessibilityIdentifier("setup.privacy")
    }

    private func privacyRow(_ title: String, detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).foregroundStyle(WelcomeStyle.accent).frame(width: 24).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.subheadline.weight(.medium))
                Text(detail).font(.footnote).foregroundStyle(WelcomeStyle.muted)
            }.fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if isTour {
                Button(started ? "Back to introduction" : "Preview setup") { started.toggle() }
                    .buttonStyle(.borderedProminent).controlSize(.regular).accessibilityIdentifier("setup.preview")
                Button("Back to my home") { dismiss() }
                Text("Preview only · Your existing home is unchanged").font(.caption).foregroundStyle(WelcomeStyle.muted)
            } else {
                Button { if started { create() } else { started = true } } label: {
                    Text(started ? "Create my home" : "Create a new home").font(.subheadline.weight(.medium)).padding(.horizontal, 24).padding(.vertical, 3).frame(minHeight: 28)
                }.buttonStyle(.borderedProminent).controlSize(.regular).buttonBorderShape(.capsule)
                    .accessibilityIdentifier(started ? "setup.create" : "setup.start")
                    .disabled(started && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if !started {
                    NavigationLink("Join an existing home") { JoinExistingHomeView() }.frame(minHeight: 44).accessibilityIdentifier("setup.join")
                    NavigationLink("Restore from iCloud") { BackupView(onRestore: onCreated) }.frame(minHeight: 44).accessibilityIdentifier("setup.restore")
                }
                Text("Private by default · No account needed").font(.caption).foregroundStyle(WelcomeStyle.muted)
            }
        }.padding(.horizontal, 24).padding(.vertical, 12).frame(maxWidth: 700).frame(maxWidth: .infinity).background(WelcomeStyle.canvas)
    }

    private func setupField(_ placeholder: String, text: Binding<String>, identifier: String) -> some View {
        TextField(placeholder, text: text)
            .font(.body).textInputAutocapitalization(.words)
            .focused($focusedSetupField, equals: identifier).submitLabel(.done)
            .onSubmit { focusedSetupField = nil }
            .padding(14).frame(minHeight: 52)
            .background(WelcomeStyle.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay { RoundedRectangle(cornerRadius: 12).strokeBorder(WelcomeStyle.muted.opacity(0.5), lineWidth: 1) }
            .accessibilityLabel("Home name")
            .accessibilityHint("Enter a name such as Our Home. Required to create your home.")
            .accessibilityIdentifier(identifier)
    }

    private func create() {
        do {
            try repository.createHousehold(name: name, owner: "", members: [], firstRoom: nil)
            onCreated()
        } catch { self.error = userFacingError(error) }
    }
}
