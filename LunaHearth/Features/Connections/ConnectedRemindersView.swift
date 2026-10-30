import SwiftUI

struct ConnectedRemindersView: View {
    var purpose: ReminderPurpose = .reminders
    @State private var scope: ReminderScope = .all
    @State private var sharing = false
    @Environment(AppleConnections.self) private var connections
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var adding = false
    @State private var choosing = false
    @State private var loading = false
    @State private var showCompleted = false
    @State private var updating: Set<String> = []
    @State private var error: String?
    var body: some View {
        List {
            Section {
                if !connections.remindersEnabled {
                    ScreenIntro(eyebrow: "Connect your list", title: "Your Apple lists, connected.", subtitle: "Optionally browse and edit an Apple list here. These items stay in Apple Reminders, separate from your LunaHearth household and its private backup.")
                    Button("Connect Apple Reminders", systemImage: "checklist") { Task { await connections.connect(.reminders); choosing = connections.remindersEnabled } }
                        .disabled(connections.working).accessibilityIdentifier("connections.reminders.connect")
                } else {
                    Button { choosing = true } label: {
                        HStack { LabeledContent("List", value: connections.list(for: purpose)?.title ?? "Set up your list"); Image(systemName: "chevron.up.chevron.down").font(.caption) }
                    }.accessibilityIdentifier("reminders.chooseList")
                    if let list = connections.list(for: purpose) {
                        Text("\(list.account) · Saved in Apple Reminders").font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            if let message = connections.remindersError {
                Section { Text(message).accessibilityIdentifier("connections.reminders.error") }
            }
            if connections.remindersEnabled && connections.list(for: purpose) != nil {
                if purpose == .reminders {
                    Picker("Show", selection: $scope) { ForEach(ReminderScope.allCases, id: \.self) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
                    if !connections.items(for: purpose).isEmpty && !connections.items(for: purpose).contains(where: { scope.includes($0) }) {
                        Text("No reminders in this view. Choose All to include reminders without a due date.").foregroundStyle(.secondary)
                    }
                }
                Toggle("Show completed", isOn: $showCompleted)
                if loading { ProgressView("Loading reminders…") }
                if connections.items(for: purpose).isEmpty && connections.remindersError == nil && !loading {
                    ContentUnavailableView("A clear list", systemImage: "checkmark.circle", description: Text("Tap + to add your first item to this Apple list."))
                }
                ForEach(connections.items(for: purpose).filter { purpose == .shopping || scope.includes($0) }) { reminder in
                    Button {
                        guard !updating.contains(reminder.id) else { return }
                        updating.insert(reminder.id)
                        Task { @MainActor in
                            defer { updating.remove(reminder.id) }
                            do {
                                try await connections.setCompleted(reminder, completed: !reminder.completed)
                                await connections.refreshReminders(includeCompleted: showCompleted, for: purpose)
                            } catch {
                                self.error = (error as? ApplePlanningError)?.localizedDescription ?? "Couldn't update this reminder. Refresh and try again."
                                await connections.refreshReminders(includeCompleted: showCompleted, for: purpose)
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: reminder.completed ? "checkmark.circle.fill" : "circle").font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(reminder.title).strikethrough(reminder.completed)
                                Text(connections.reminderSources.first(where: { $0.id == reminder.listID })?.title ?? "Apple Reminders")
                                    .font(.caption).foregroundStyle(.secondary)
                                if let notes = reminder.notes, !notes.isEmpty { Text(notes).font(.caption).foregroundStyle(.secondary) }
                                if let due = reminder.due { Text(due.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(.secondary) }
                            }
                        }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .disabled(updating.contains(reminder.id) || connections.reminderSources.first(where: { $0.id == reminder.listID })?.writable != true)
                        .accessibilityLabel("\(reminder.title), \(reminder.completed ? "completed" : "not completed")")
                        .accessibilityHint("Changes completion in Apple Reminders")
                        .accessibilityIdentifier("appleReminder.\(reminder.id)")
                }
                if let error = connections.remindersError { Text(error).foregroundStyle(.secondary) }
            }
        }.hearthList().navigationTitle(purpose.title).navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("How to share this list", systemImage: "person.badge.plus") { sharing = true }.disabled(connections.list(for: purpose) == nil).accessibilityIdentifier("reminders.share")
                Button("Add item", systemImage: "plus") { adding = true }.disabled(connections.list(for: purpose)?.writable != true).accessibilityIdentifier("reminders.add")
            }
            .sheet(isPresented: $sharing) { ReminderSharingGuide(list: connections.list(for: purpose)) }
            .sheet(isPresented: $adding) { QuickAddView(kind: purpose == .shopping ? .grocery : .task, fixedKind: true, appleDestination: true) }
            .sheet(isPresented: $choosing) { ReminderListChooser(purpose: purpose) }
            .task(id: "\(connections.revision)-\(showCompleted)-\(purpose.rawValue)") { await refresh() }
            .refreshable { await refresh() }.saveError($error)
    }
    private func refresh() async {
        loading = true
        defer { loading = false }
        await connections.refreshSources(.reminders)
        await connections.refreshReminders(includeCompleted: showCompleted, for: purpose)
    }
}

struct ReminderListChooser: View {
    let purpose: ReminderPurpose
    @Environment(AppleConnections.self) private var connections
    @Environment(\.dismiss) private var dismiss
    @State private var mode: Mode?
    @State private var referenceID = ""
    @State private var selectedID = ""
    @State private var creating = false
    @State private var error: String?
    private enum Mode { case create, existing }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HearthIcon(symbol: purpose.symbol)
                    Text("Connect your \(purpose.title.lowercased()) list.").font(AppTheme.sectionTitle)
                    Text("This optional connection shows only the Apple list you select. Items edited here stay in Apple Reminders; they are not copied into your household or its backup.")
                        .font(.subheadline).foregroundStyle(.secondary).accessibilityIdentifier("reminders.setup.message")
                }
                Section {
                    Button { mode = .create } label: {
                        Label("Create a standard list", systemImage: "plus.circle.fill")
                    }.accessibilityIdentifier("reminders.setup.create")
                    Button { mode = .existing } label: {
                        Label("Browse existing lists", systemImage: "list.bullet.rectangle")
                    }.accessibilityIdentifier("reminders.setup.browse")
                }
                if mode == .existing {
                    Section("Choose a list") {
                        ForEach(connections.reminderSources) { list in
                            Button { selectedID = list.id } label: {
                                HStack {
                                    Image(systemName: "list.bullet.circle.fill").foregroundStyle(AppTheme.slate).font(.title2)
                                    VStack(alignment: .leading) {
                                        Text(list.title)
                                        Text(list.account + (list.writable ? "" : " · Read only")).font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedID == list.id { Image(systemName: "checkmark") }
                                }.frame(minHeight: 44).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                                .accessibilityIdentifier("reminders.setup.list.\(list.id)")
                                .accessibilityAddTraits(selectedID == list.id ? .isSelected : [])
                        }
                        if let selected = connections.reminderSources.first(where: { $0.id == selectedID }) {
                            Text("Only items in \(selected.title) will appear in \(purpose.title). Switching lists does not move existing items.").font(.footnote)
                            Button("Use this list") { connections.selectReminderList(selectedID, for: purpose); dismiss() }
                                .accessibilityIdentifier("reminders.setup.use")
                        }
                    }
                }
                if mode == .create {
                    Section {
                        LabeledContent("List name", value: purpose.standardTitle)
                        Picker("Use the account of", selection: $referenceID) {
                            Text("Choose an existing list").tag("")
                            ForEach(connections.reminderSources.filter(\.writable)) { Text("\($0.title) · \($0.account)").tag($0.id) }
                        }.accessibilityIdentifier("reminders.account")
                        Button("Create \(purpose.standardTitle)", systemImage: "plus.circle.fill") {
                            creating = true
                            Task { @MainActor in
                                defer { creating = false }
                                do { try await connections.createStandardList(usingListID: referenceID, for: purpose); dismiss() }
                                catch { self.error = "Could not create the list. Try another account, or create it in Apple Reminders and browse existing lists here." }
                            }
                        }.disabled(referenceID.isEmpty).accessibilityIdentifier("reminders.createList")
                        if creating { ProgressView("Creating list…") }
                    } header: { Text("Your dedicated Apple list") } footer: {
                        Text("Creates this list in the chosen account, or reuses a writable list with the same name in that account. Choose an iCloud list's account if you want to collaborate using Apple Reminders.")
                    }
                }
                if connections.reminderSources.isEmpty {
                    Text(connections.remindersError ?? "No lists available. Set up an account and list in Apple Reminders, then pull to refresh here.").foregroundStyle(.secondary)
                }
                Section {
                    Text("Shared lists follow their existing access rules. People you share with may see and change their items.").font(.footnote).foregroundStyle(.secondary)
                    Button("Disconnect Apple Reminders", role: .destructive) { connections.disconnect(.reminders); dismiss() }
                }
            }.hearthList().navigationTitle("Set up \(purpose.title)").navigationBarTitleDisplayMode(.inline)
                .disabled(creating)
                .toolbar { Button("Done") { dismiss() }.disabled(creating) }
                .refreshable { await connections.refreshSources(.reminders) }
                .saveError($error)
        }.interactiveDismissDisabled(creating)
    }
}

struct ReminderSharingGuide: View {
    let list: ApplePlanningSource?
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HearthIcon(symbol: "person.2.fill")
                    Text("Share this Apple list.").font(AppTheme.sectionTitle)
                    if let list {
                        LabeledContent("List", value: list.title)
                        LabeledContent("Account", value: list.account)
                    }
                }
                Section("In Apple Reminders") {
                    Label("1. Open Reminders and choose this list.", systemImage: "checklist")
                    Label("2. Tap Share and choose who to invite.", systemImage: "person.badge.plus")
                    Label("3. After they accept, everyone works on the same list.", systemImage: "checkmark.circle")
                }
                Section {
                    Text("Invitations are managed in Apple Reminders. LunaHearth cannot send or manage list invitations here. Collaborators need an Apple Account with iCloud Reminders enabled; not every account or list supports sharing.")
                        .font(.footnote).foregroundStyle(.secondary).accessibilityIdentifier("reminders.sharing.explanation")
                    if let url = URL(string: "https://support.apple.com/105124") { Link("Apple’s list-sharing instructions", destination: url) }
                }
            }.hearthList().navigationTitle("How to share").navigationBarTitleDisplayMode(.inline)
                .toolbar { Button("Done") { dismiss() } }
        }
    }
}
