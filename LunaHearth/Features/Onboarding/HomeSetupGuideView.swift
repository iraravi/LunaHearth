import SwiftUI

/// Per-household, device-local learning progress. Completing setup never enables a service.
struct HomeSetupGuideView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var textSize
    @AppStorage private var completed: String
    @AppStorage private var skipped: String
    @State private var selected: HomeSetupStep = .pantry
    init(householdID: UUID) {
        _completed = AppStorage(wrappedValue: "", HomeSetupProgress.storageKey(householdID: householdID, field: "completed"))
        _skipped = AppStorage(wrappedValue: "", HomeSetupProgress.storageKey(householdID: householdID, field: "skipped"))
    }
    private var progress: HomeSetupProgress {
        HomeSetupProgress(savedCompleted: completed, savedSkipped: skipped, observed: repository.setupMilestones)
    }
    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(progress.isFinished ? "Make yourself at home." : "A few small steps. A calmer day.").font(.system(.title2, design: .serif, weight: .regular))
                    Text("Your home is ready to use. Try each step, or leave it for later.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    SetupProgressIndicator(progress: progress)
                }
                if progress.isFinished {
                    Label("Setup reviewed", systemImage: "checkmark.circle.fill").font(.headline).foregroundStyle(.green)
                        .accessibilityIdentifier("guide.finished")
                    Text("\(1 + progress.completed.count) completed · \(progress.skipped.count) left for later. Revisit any step below.").font(.subheadline).foregroundStyle(.secondary)
                    NavigationLink { MealIdeasView() } label: { Label("Explore meal ideas", systemImage: "fork.knife").frame(minHeight: 44) }
                    NavigationLink { HomeSpacesView() } label: { Label("Explore rooms & belongings", systemImage: "house").frame(minHeight: 44) }
                }
                VStack(alignment: .leading, spacing: 16) {
                    if !textSize.isAccessibilitySize { WelcomePhotograph(name: selected.art, height: 170).accessibilityHidden(true) }
                    Text("Step \(HomeSetupStep.allCases.firstIndex(of: selected).map { $0 + 2 } ?? 2) of \(progress.totalCount)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(selected.title).font(.system(.title2, design: .serif, weight: .regular))
                    Text(selected.explanation).font(.body).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    NavigationLink { destination(selected) } label: {
                        Label(selected.action, systemImage: selected.symbol).font(.headline).frame(minHeight: 44)
                    }.accessibilityIdentifier("guide.open.\(selected.rawValue)")
                    if progress.completed.contains(selected) {
                        Label("Completed", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        if let next = progress.next {
                            Button("Continue to \(next.title)") { selected = next }.frame(minHeight: 44).accessibilityIdentifier("guide.next")
                        }
                    } else {
                        Button(selected == .sharing ? "Keep it on this device for now" : "Do this later") {
                            skipped = HomeSetupProgress.encode(HomeSetupProgress.decode(skipped).union([selected]))
                            if let next = progress.next { selected = next }
                        }.frame(minHeight: 44).accessibilityIdentifier("guide.skip")
                        Text("Nothing is added or connected until you choose and save it.").font(.footnote).foregroundStyle(.secondary)
                    }
                }.padding(20).background(WelcomeStyle.surface, in: RoundedRectangle(cornerRadius: 16)).id("guide.detail")
                VStack(alignment: .leading, spacing: 0) {
                    Label("1. Name your home · Completed", systemImage: "checkmark.circle.fill").padding(16)
                    ForEach(Array(HomeSetupStep.allCases.enumerated()), id: \.element) { index, step in
                        Divider()
                        Button {
                            selected = step
                            proxy.scrollTo("guide.detail", anchor: .top)
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: progress.completed.contains(step) ? "checkmark.circle.fill" : "\(index + 2).circle")
                                    .foregroundStyle(WelcomeStyle.accent).accessibilityHidden(true)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(step.title).font(.headline)
                                    Text(progress.completed.contains(step) ? "Completed" : progress.skipped.contains(step) ? "Later · Tap to revisit" : "Ready when you are")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                                if step == selected { Image(systemName: "chevron.right").accessibilityHidden(true) }
                            }.frame(maxWidth: .infinity, minHeight: 44, alignment: .leading).padding(16).contentShape(Rectangle())
                        }.buttonStyle(.plain).accessibilityIdentifier("guide.step.\(step.rawValue)")
                            .accessibilityValue(step == selected ? "Selected" : "")
                    }
                }.background(WelcomeStyle.surface, in: RoundedRectangle(cornerRadius: 16))
                Text("Progress is saved on this device for this home. You can return from Home or More → Preferences.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }.background(WelcomeStyle.canvas).foregroundStyle(WelcomeStyle.ink).tint(WelcomeStyle.ink)
            .navigationTitle("Set up your home").navigationBarTitleDisplayMode(.inline)
            .onAppear { rememberCompleted(); selected = progress.next ?? .pantry }
            .onChange(of: repository.setupMilestones) { _, _ in rememberCompleted() }
        }
    }
    private func rememberCompleted() { completed = HomeSetupProgress.encode(progress.completed) }
    @ViewBuilder private func destination(_ step: HomeSetupStep) -> some View {
        switch step {
        case .pantry: InventoryView()
        case .shopping: ShoppingListView()
        case .receipts: ExpensesView()
        case .meals: MealIdeasView()
        case .planning: PlanningListView(kind: .task)
        case .sharing: FamilyView()
        }
    }
}

struct HomeSetupGuideCard: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @AppStorage private var completed: String
    @AppStorage private var skipped: String
    let open: () -> Void
    init(householdID: UUID, open: @escaping () -> Void) {
        self.open = open
        _completed = AppStorage(wrappedValue: "", HomeSetupProgress.storageKey(householdID: householdID, field: "completed"))
        _skipped = AppStorage(wrappedValue: "", HomeSetupProgress.storageKey(householdID: householdID, field: "skipped"))
    }
    var body: some View {
        let progress = HomeSetupProgress(savedCompleted: completed, savedSkipped: skipped, observed: repository.setupMilestones)
        if !progress.isFinished {
            Button(action: open) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("Set up your home", systemImage: "sparkles").font(.headline)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }
                    Text("Next: \(progress.next?.title ?? "Review your setup")").font(.subheadline).foregroundStyle(.secondary)
                    SetupProgressIndicator(progress: progress)
                }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                    .background(WelcomeStyle.surface, in: RoundedRectangle(cornerRadius: 16)).contentShape(Rectangle())
            }.buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Set up your home")
                .accessibilityValue("\(progress.reviewedCount) of \(progress.totalCount) steps reviewed")
                .accessibilityIdentifier("home.setupGuide")
        }
    }
}

private struct SetupProgressIndicator: View {
    let progress: HomeSetupProgress
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(progress.reviewedCount) of \(progress.totalCount) steps reviewed").font(.subheadline.weight(.medium))
            ProgressView(value: Double(progress.reviewedCount), total: Double(progress.totalCount)).tint(WelcomeStyle.accent)
                .accessibilityLabel("Setup progress").accessibilityValue("\(progress.reviewedCount) of \(progress.totalCount) steps reviewed")
                .accessibilityIdentifier("guide.progress")
                .allowsHitTesting(false)
        }
    }
}

private extension HomeSetupStep {
    var title: String {
        switch self { case .pantry: "Stock your pantry"; case .shopping: "Make a shopping list"; case .receipts: "Record an expense"; case .meals: "Plan a meal"; case .planning: "Plan your day"; case .sharing: "Choose how to share" }
    }
    var explanation: String {
        switch self {
        case .pantry: "Start with what you already have. In Pantry, choose Ideas to review a kitchen starter list, scan a receipt, or add one item. Only the item name is required."
        case .shopping: "Add something you need. Choose an amount and store if useful. When you buy it, choose whether it should also update your pantry."
        case .receipts: "In Expenses, add an expense or scan a receipt. Check the store, total and item names, then choose pantry updates and shopping matches before saving. Scanning and AI suggestions can be wrong."
        case .meals: "Choose a cooking style and review ideas based on recorded pantry items. Save a meal and add missing ingredients to shopping. Ideas are not recipes; the 5 PM planning reminder is optional."
        case .planning: "Add your first reminder. You can set a due date or assign it to a household member. For appointments, use the Calendar tab."
        case .sharing: "Use this home on your own, or invite someone through Family. iCloud sharing is optional and asks you before uploading."
        }
    }
    var action: String { switch self { case .pantry: "Open pantry"; case .shopping: "Open shopping"; case .receipts: "Open expenses"; case .meals: "Open meal ideas"; case .planning: "Open reminders"; case .sharing: "Open family sharing" } }
    var symbol: String { switch self { case .pantry: "cabinet"; case .shopping: "basket"; case .receipts: "receipt"; case .meals: "fork.knife"; case .planning: "checklist"; case .sharing: "person.2" } }
    var art: String { switch self { case .pantry: "WelcomeTable"; case .shopping: "WelcomeTable"; case .receipts: "WelcomeResidence"; case .meals: "WelcomeTable"; case .planning: "WelcomeResidence"; case .sharing: "WelcomeResidence" } }
}

extension LocalHouseholdRepository {
    var setupMilestones: Set<HomeSetupStep> {
        var result = Set<HomeSetupStep>()
        if !inventory.isEmpty { result.insert(.pantry) }
        if !groceries.isEmpty || !purchases.isEmpty { result.insert(.shopping) }
        if !expenses.isEmpty { result.insert(.receipts) }
        if !meals.isEmpty { result.insert(.meals) }
        if !tasks.isEmpty || !events.isEmpty || !meals.isEmpty { result.insert(.planning) }
        if syncConfiguration != nil { result.insert(.sharing) }
        return result
    }
}
