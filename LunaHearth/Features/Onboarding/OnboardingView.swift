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
            .navigationTitle(isTour ? (started ? "Setup preview" : "Welcome") : (started ? "Make yourself at home" : ""))
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
            Text("One private place for your day, your people and everything at home.")
                .font(.body).foregroundStyle(WelcomeStyle.muted).lineSpacing(3)
            Divider()
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "house").font(.title3.weight(.light)).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Start with a name").font(.headline)
                    Text("No rooms, lists or accounts to set up first. Add the details whenever you’re ready.")
                        .font(.subheadline).foregroundStyle(WelcomeStyle.muted)
                }
            }
            privacy
        }
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 24) {
            if !typeSize.isAccessibilitySize { WelcomePhotograph(name: "WelcomeResidence", height: 150) }
            VStack(alignment: .leading, spacing: 10) {
                Text("Step 1 of \(1 + HomeSetupStep.allCases.count) · Your home").font(.caption.weight(.medium)).foregroundStyle(WelcomeStyle.muted)
                ProgressView(value: 1, total: Double(1 + HomeSetupStep.allCases.count))
                    .tint(WelcomeStyle.accent).accessibilityLabel("Setup, step 1 of \(1 + HomeSetupStep.allCases.count)")
            }.accessibilityIdentifier("setup.progress")
            Text("A name that feels like home.").font(WelcomeStyle.heading).fixedSize(horizontal: false, vertical: true)
            Text("Everything else can come later.").foregroundStyle(WelcomeStyle.muted)
            VStack(alignment: .leading, spacing: 10) {
                Text("Home name").font(.subheadline.weight(.medium))
                setupField("e.g. Our Home", text: $name, identifier: "setup.householdName")
                Text("You can add rooms and invite people after setup.")
                    .font(.footnote).foregroundStyle(WelcomeStyle.muted)
            }
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
                    Text(started ? "Create my home" : "Get Started").font(.subheadline.weight(.medium)).padding(.horizontal, 24).padding(.vertical, 3).frame(minHeight: 28)
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
            .accessibilityIdentifier(identifier)
    }

    private func create() {
        do {
            try repository.createHousehold(name: name, owner: "", members: [], firstRoom: nil)
            onCreated()
        } catch { self.error = userFacingError(error) }
    }
}
