import SwiftUI

private struct MemberDraft: Identifiable {
    let id = UUID()
    var name = ""
    var role: MemberRole = .adult
}

struct OnboardingView: View {
    var onCreated: () -> Void = {}
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var started = false
    @State private var name = "Our Home"
    @State private var owner = ""
    @State private var firstRoom = ""
    @State private var people: [MemberDraft] = []
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if started {
                    Form {
                        Section("Name your home") {
                            TextField("Household name", text: $name).accessibilityIdentifier("setup.householdName")
                            TextField("Your display name (optional)", text: $owner)
                        }
                        Section {
                            Picker("First room", selection: $firstRoom) {
                                Text("Add rooms later").tag("")
                                ForEach(["Kitchen", "Living room", "Bedroom", "Office"], id: \.self) { Text($0).tag($0) }
                            }.accessibilityIdentifier("setup.firstRoom")
                        } header: { Text("Start with a room") } footer: {
                            Text("You can add an item as soon as your home is ready.")
                        }
                        Section {
                            DisclosureGroup("Add household members") {
                            ForEach($people) { $person in
                                VStack(alignment: .leading) {
                                    TextField("Display name", text: $person.name)
                                    Picker("Profile", selection: $person.role) {
                                        Text("Adult").tag(MemberRole.adult)
                                        Text("Child").tag(MemberRole.child)
                                    }
                                    Button("Remove person", role: .destructive) { people.removeAll { $0.id == person.id } }
                                }
                            }
                            Button("Add a person", systemImage: "person.badge.plus") { people.append(MemberDraft()) }
                            }
                        } header: { Text("People · optional") } footer: {
                            Text("Profiles help assign events and chores. They are not accounts. You can add people later.")
                        }
                    }
                    .hearthList()
                    .safeAreaInset(edge: .bottom) {
                        VStack(spacing: 8) {
                            Button(action: create) {
                                HStack { Text("Create my home"); Spacer(); Image(systemName: "arrow.right") }
                                    .font(.headline).padding(.vertical, 6)
                            }.buttonStyle(.borderedProminent).controlSize(.large)
                                .accessibilityIdentifier("setup.create")
                                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            Text("Saved on this device. iCloud backup is optional.")
                                .font(.caption).foregroundStyle(AppTheme.muted)
                        }.padding().frame(maxWidth: 600).frame(maxWidth: .infinity).background(AppTheme.canvas)
                    }
                    .navigationTitle("Set up your home").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Back") { started = false } } }
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            HStack(spacing: 10) {
                                HearthIcon(symbol: "house.and.flag")
                                Text("LunaHearth").font(.system(.title3, design: .default, weight: .bold)).foregroundStyle(AppTheme.ink)
                            }
                            HearthArtwork(name: "HearthHome", height: 220)
                            Text("Home life.\nHandled.")
                                .font(.system(.largeTitle, design: .default, weight: .bold)).foregroundStyle(AppTheme.ink)
                            Text("One app for your family, your schedule, and your home.")
                                .font(.title3).foregroundStyle(AppTheme.muted)
                            VStack(alignment: .leading, spacing: 16) {
                                welcomePoint("Make plans together", detail: "Family events, tasks, and little reminders.", symbol: "calendar")
                                welcomePoint("Keep track of your home", detail: "Rooms, belongings, and the details that matter.", symbol: "house")
                                welcomePoint("Works offline", detail: "Works offline. No account needed.", symbol: "iphone")
                            }.padding(.vertical, 8)

                        }.padding(24).frame(maxWidth: 600, alignment: .leading).frame(maxWidth: .infinity)
                    }.background(AppTheme.canvas)
                        .safeAreaInset(edge: .bottom) {
                            VStack(spacing: 10) {
                                Button { started = true } label: {
                                    HStack { Text("Get Started"); Spacer(); Image(systemName: "arrow.right") }
                                        .font(.headline).padding(.vertical, 8)
                                }.buttonStyle(.borderedProminent).controlSize(.large)
                                    .accessibilityIdentifier("setup.start")
                                NavigationLink("Restore from iCloud") { BackupView(onRestore: onCreated) }
                                    .accessibilityIdentifier("setup.restore")
                                Text("Stored on this device · No account needed")
                                    .font(.caption).foregroundStyle(AppTheme.muted)
                            }.padding(.horizontal, 24).padding(.vertical, 12)
                                .frame(maxWidth: 600).frame(maxWidth: .infinity).background(AppTheme.canvas)
                        }
                }
            }
            .saveError($error)
        }
    }

    private func welcomePoint(_ title: String, detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            HearthIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(AppTheme.ink)
                Text(detail).font(.caption).foregroundStyle(AppTheme.muted)
            }.fixedSize(horizontal: false, vertical: true)
        }
    }

    private func create() {
        do { try repository.createHousehold(name: name, owner: owner, members: people.map { ($0.name, $0.role) }, firstRoom: firstRoom.isEmpty ? nil : firstRoom); onCreated() }
        catch { self.error = userFacingError(error) }
    }
}
