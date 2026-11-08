import SwiftUI

struct HomeView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var quickAdding = false
    @State private var showingSetup = false
    @State private var scanningReceipt = false
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                if HomeWorkspaceLayout.isExpanded(width: geometry.size.width, accessibilityText: textSize.isAccessibilitySize) {
                    HomeWorkspaceDashboard(showingSetup: $showingSetup, scanning: $scanningReceipt)
                } else {
                    compactDashboard
                }
            }.background(AppTheme.canvas).buttonStyle(.plain).foregroundStyle(.primary)
                .householdHelp(.home)
                .navigationTitle("Home").navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $showingSetup) {
                    if let homeID = repository.household?.id { HomeSetupGuideView(householdID: homeID) }
                }
                .toolbar { Button("Quick add", systemImage: "plus") { quickAdding = true } }
                .sheet(isPresented: $scanningReceipt) {
                    if let homeID = repository.household?.id { ReceiptImportView(householdID: homeID) }
                }
                .sheet(isPresented: $quickAdding) { QuickAddView() }
        }
    }
    private var compactDashboard: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HearthEditorialHeader(eyebrow: "YOUR HOME", title: repository.household?.name ?? "Your home",
                                          subtitle: "A little order. More room for living.", artwork: "WelcomeResidence")
                    if let homeID = repository.household?.id { HomeSetupGuideCard(householdID: homeID) { showingSetup = true } }
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Your kitchen").font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                        TodayAlignedCards(columns: textSize.isAccessibilitySize ? 1 : 2) {
                            NavigationLink { InventoryView() } label: {
                                HomeFoodTile(title: "Pantry", purpose: "What you have", count: "\(repository.inventory.filter { !$0.isUsedUp }.count) packs at home", accent: InventoryTheme.accent, surface: AppTheme.surface)
                            }.accessibilityIdentifier("home.inventory")
                            NavigationLink { ShoppingListView() } label: {
                                HomeFoodTile(title: "Shopping", purpose: "What to buy", count: "\(repository.groceries.filter { !$0.isCompleted }.count) items to buy", accent: ShoppingTheme.accent, surface: AppTheme.surface)
                            }.accessibilityIdentifier("home.shopping")
                        }
                        NavigationLink { MealIdeasView() } label: {
                            HStack(spacing: 18) {
                                FeatureIllustration(symbol: "fork.knife", size: 64)
                                VStack(alignment: .leading, spacing: 5) {
                                    Text("Meals").font(.title3.bold())
                                    Text("Meal ideas & plans from your pantry").font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0); Image(systemName: "chevron.right").accessibilityHidden(true)
                            }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                                .contentShape(Rectangle())
                        }.accessibilityIdentifier("home.meals")
                    }
                    NavigationLink { PlanningListView(kind: .task) } label: {
                        HStack(spacing: 16) {
                            FeatureIllustration(symbol: "checklist", size: 64)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Reminders").font(.title3.bold())
                                Text("\(repository.tasks.filter { !$0.isCompleted }.count) open \(repository.tasks.filter { !$0.isCompleted }.count == 1 ? "task" : "tasks") · Your household to-dos")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right").accessibilityHidden(true)
                        }.padding(20).frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                            .contentShape(Rectangle())
                    }.accessibilityIdentifier("home.tasks")
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Spending").font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                        TodayAlignedCards(columns: textSize.isAccessibilitySize || sizeClass != .regular ? 1 : 3) {
                            NavigationLink { ExpensesView() } label: { HomeUtilityTile(title: "Expenses", detail: "Receipts & monthly spending", symbol: "chart.bar.xaxis", accent: AppTheme.plum) }.accessibilityIdentifier("home.expenses")
                            NavigationLink { PurchaseHistoryView() } label: { HomeUtilityTile(title: "Purchases", detail: "Your purchase history", symbol: "bag", accent: AppTheme.slate) }.accessibilityIdentifier("home.purchases")
                        }
                    }
                    NavigationLink { ConnectedDemoView() } label: {
                        Label("Try the connected demo", systemImage: "play.rectangle").font(.subheadline).frame(minHeight: 44)
                    }.accessibilityIdentifier("home.connectedDemo")
                }.padding(20).frame(maxWidth: 1000).frame(maxWidth: .infinity)
            }
    }
}

private struct HomeFoodTile: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let title: String
    let purpose: String
    let count: String
    let accent: Color
    let surface: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !textSize.isAccessibilitySize {
            FeatureIllustration(symbol: title == "Pantry" ? "cabinet" : "basket", size: 104)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            Text(title).font(AppTheme.sectionTitle).foregroundStyle(accent)
            Text(purpose).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
            Text(count).font(.caption).foregroundStyle(.secondary)
        }.padding(16).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).background(surface, in: RoundedRectangle(cornerRadius: 18))
            .hearthCardOutline(accent, radius: 18).contentShape(Rectangle())
    }
}
private struct HomeUtilityTile: View {
    let title: String
    let detail: String
    let symbol: String
    let accent: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureIllustration(symbol: symbol, size: 72)
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
        }.padding(20).frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18)).hearthCardOutline(accent)
    }
}
