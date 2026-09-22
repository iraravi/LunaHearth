import SwiftUI

struct PersonalShoppingCard: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(PersonalShopping.self) private var personal
    var body: some View {
        if let home = repository.household?.id {
            let selected = personal.memberID(home)
            let member = repository.members.first { $0.id == selected }
            let items = personal.items(repository)
            NavigationLink { PersonalShoppingView() } label: {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label(member.map { "FOR \($0.displayName.uppercased())" } ?? "FOR YOU", systemImage: "person.crop.circle")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right").accessibilityHidden(true)
                    }
                    HStack(spacing: 16) {
                        Image(systemName: "checklist").font(.largeTitle).foregroundStyle(ShoppingTheme.accent)
                            .padding(16).background(ShoppingTheme.canvas, in: RoundedRectangle(cornerRadius: 18)).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(member == nil ? "Your shopping, together." : items.isEmpty ? "You’re all caught up." : "\(items.count) \(items.count == 1 ? "item" : "items") for you")
                                .font(AppTheme.sectionTitle)
                            Text(member == nil ? "Choose your name to see what’s assigned to you." : AssignedShoppingRules.summary(items, today: HouseholdDay(.now).key))
                                .font(.subheadline).foregroundStyle(ShoppingTheme.muted)
                        }
                    }
                    Text(member == nil ? "Set up your view" : "Open your shopping").font(.subheadline.weight(.semibold))
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundStyle(ShoppingTheme.ink).background(ShoppingTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            }.buttonStyle(.plain).accessibilityIdentifier("today.personalShopping")
        }
    }
}

struct PersonalShoppingView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(PersonalShopping.self) private var personal
    @Environment(HouseholdSharingController.self) private var sharing
    @State private var purchase: GroceryItem?
    @State private var brief: ShoppingBrief?
    @State private var summarizing = false
    @State private var summaryRequested = false
    @State private var error: String?
    private let service: any ShoppingBriefService = OnDeviceShoppingBriefService()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { timeline in
            content(today: HouseholdDay(timeline.date).key)
        }
    }

    private func content(today: String) -> some View {
        let items = personal.items(repository)
        return List {
            if let home = repository.household?.id {
                Section {
                    if let linked = repository.linkedCloudMemberID {
                        LabeledContent("Your profile", value: repository.memberName(linked))
                            .accessibilityIdentifier("shopping.linkedMember")
                    } else {
                    Picker("This device is used by", selection: Binding(get: { personal.memberID(home) }, set: { personal.select($0, repository: repository) })) {
                        Text("Choose your name").tag(nil as UUID?)
                        ForEach(repository.members) { Text($0.displayName).tag(Optional($0.id)) }
                    }.accessibilityIdentifier("shopping.personalMember")
                    }
                    if repository.members.isEmpty {
                        NavigationLink("Add a household member") { FamilyView() }
                    }
                } footer: { Text("Your view on this device. Shared members can see the full household list.") }
                if personal.memberID(home) != nil {
                    Section("Your tasks & chores") {
                        let tasks = personal.tasks(repository)
                        if tasks.isEmpty { Text("No tasks assigned to you.").foregroundStyle(ShoppingTheme.muted) }
                        ForEach(tasks) { task in
                            NavigationLink { TaskDetailView(task: task) } label: {
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(task.title).font(.headline)
                                    if let due = task.dueAt { Text(due, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(ShoppingTheme.muted) }
                                }
                            }.accessibilityIdentifier("personal.task.\(task.title)")
                        }
                        if personal.taskAlertsEnabled(home) {
                            Label("Task assignment alerts enabled", systemImage: "bell.badge")
                            Button("Turn off task alerts") { personal.disableTasks(repository) }
                        } else {
                            Button("Notify me about task assignments", systemImage: "bell") {
                                Task { await personal.enableTasks(repository, service: sharing.service) }
                            }.accessibilityIdentifier("personal.taskAlerts")
                        }
                    }

                    Section {
                        Text(AssignedShoppingRules.summary(items, today: today)).font(.headline)
                            .accessibilityIdentifier("shopping.personalCount")
                        if let brief {
                            if brief.usedModel { Text(brief.text) }
                            Text(brief.usedModel ? "Summarized on this device. Check the list for exact details. Up to 40 items included." : "List summary · On-device AI isn’t available right now.")
                                .font(.caption).foregroundStyle(ShoppingTheme.muted)
                        }
                        Button { summaryRequested = true } label: {
                            Label(summarizing ? "Summarizing…" : "Summarize my shopping", systemImage: "sparkles")
                        }.disabled(summarizing || items.isEmpty).accessibilityIdentifier("shopping.personalSummary")
                    } header: { Text("Your shopping brief") }
                    if items.isEmpty {
                        ContentUnavailableView("All caught up", systemImage: "checkmark.circle", description: Text("Items assigned to you will appear here."))
                    }
                    shoppingSection("Needed now", items: items.filter { $0.neededNow(today: today) })
                    shoppingSection("Later", items: items.filter { !$0.neededNow(today: today) })
                    Section {
                        if personal.alertsEnabled(home) {
                            Label("Shopping assignment alerts enabled", systemImage: "bell.badge")
                            Button("Turn off alerts", role: .destructive) { personal.disable(repository) }
                        } else {
                            Button("Notify me about shopping assignments", systemImage: "bell") {
                                Task { await personal.enable(repository, service: sharing.service) }
                            }
                        }
                        if let message = personal.message { Text(message).font(.caption) }
                    } footer: { Text("Alerts arrive when changes sync. Background delivery may be delayed. Connect and accept the shared home in More to receive another person’s changes.") }
                }
                Section { NavigationLink("All household shopping") { ShoppingListView() } }
            }
        }
        .navigationTitle("For you").navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden).background(ShoppingTheme.canvas).tint(ShoppingTheme.accent)
        .task(id: summaryRequested) {
            guard summaryRequested else { return }
            summarizing = true
            defer { summarizing = false; summaryRequested = false }
            do { brief = try await service.summarize(items, today: today) }
            catch { if !Task.isCancelled { self.error = "Couldn’t summarize. Your shopping list is still available." } }
        }
        .onChange(of: today) { _, _ in brief = nil; summaryRequested = false }
        .onChange(of: items) { _, _ in brief = nil; summaryRequested = false }
        .sheet(item: $purchase) { ShoppingPurchaseSheet(item: $0) }
        .saveError($error)
    }

    @ViewBuilder private func shoppingSection(_ title: String, items: [AssignedShoppingItem]) -> some View {
        if !items.isEmpty {
            Section(title) {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Button {
                            guard let grocery = repository.groceries.first(where: { $0.id == item.id }) else { return }
                            purchase = grocery
                        } label: { Image(systemName: "circle").font(.title2).frame(minWidth: 44, minHeight: 44) }
                            .buttonStyle(.borderless).accessibilityLabel("Complete \(item.name)")
                            .accessibilityIdentifier("shopping.personalComplete.\(item.name)")
                            .disabled(repository.syncConfiguration?.readOnly == true || repository.syncConfiguration?.recovery == true)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.name).font(.headline)
                            Text([item.quantity, item.store.isEmpty ? "Any store" : item.store].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.subheadline).foregroundStyle(ShoppingTheme.muted)
                            if item.later { Text(item.day.flatMap { ShoppingEntryRules.date(for: $0) }.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "Later · No date").font(.caption) }
                        }
                    }
                }
            }.listRowBackground(ShoppingTheme.surface)
        }
    }
}
