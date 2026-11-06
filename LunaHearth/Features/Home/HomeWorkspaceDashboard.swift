import SwiftUI

/// Two independent, scrollable areas keep household actions beside a household overview.
struct HomeWorkspaceDashboard: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Binding var showingSetup: Bool
    @Binding var scanning: Bool

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 24) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("AT A GLANCE").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                        NavigationLink { InventoryView() } label: {
                            card("Pantry", detail: "\(repository.inventory.filter { !$0.isUsedUp }.count) packs at home", symbol: "cabinet", color: InventoryTheme.accent)
                        }.accessibilityIdentifier("home.inventory")
                        NavigationLink { ShoppingListView() } label: {
                            card("Shopping", detail: "\(repository.groceries.filter { !$0.isCompleted }.count) items to buy", symbol: "basket", color: ShoppingTheme.accent)
                        }.accessibilityIdentifier("home.shopping")
                        NavigationLink { PlanningListView(kind: .task) } label: {
                            card("Reminders", detail: "\(repository.tasks.filter { !$0.isCompleted }.count) open tasks", symbol: "checklist", color: AppTheme.slate)
                        }.accessibilityIdentifier("home.tasks")
                        Button { scanning = true } label: {
                            card("Scan receipt", detail: "Review spending & pantry items", symbol: "receipt", color: AppTheme.plum)
                        }.accessibilityIdentifier("home.workspace.scan")
                        NavigationLink { MealIdeasView() } label: {
                            card("Meals", detail: "Plan from your pantry", symbol: "fork.knife", color: AppTheme.clay)
                        }.accessibilityIdentifier("home.meals")
                        NavigationLink { ExpensesView() } label: {
                            card("Expenses", detail: "Receipts & monthly spending", symbol: "chart.bar.xaxis", color: AppTheme.plum)
                        }.accessibilityIdentifier("home.expenses")
                        NavigationLink { PurchaseHistoryView() } label: {
                            card("Purchases", detail: "Your purchase history", symbol: "bag", color: AppTheme.slate)
                        }.accessibilityIdentifier("home.purchases")
                        if let homeID = repository.household?.id {
                            HomeSetupGuideCard(householdID: homeID) { showingSetup = true }
                        }
                        NavigationLink { ConnectedDemoView() } label: {
                            Label("Try the connected demo", systemImage: "play.rectangle").frame(minHeight: 44)
                        }.accessibilityIdentifier("home.connectedDemo")
                    }.padding(.bottom, 24)
                }.frame(width: max(270, min(380, geometry.size.width * 0.38)))
                    .accessibilityIdentifier("home.workspace.actions")
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("YOUR HOME").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(.secondary)
                            Text(repository.household?.name ?? "Your home").font(AppTheme.displayTitle)
                            Text("Your kitchen, plans and spending in one place.")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        TodayResidence().frame(maxHeight: 300)
                        Text("A little order. More room for living.")
                            .font(AppTheme.sectionTitle)
                        Text("Use the actions alongside to check your pantry, plan meals, scan receipts or review your household spending.")
                            .font(.body).foregroundStyle(.secondary)
                        if let homeID = repository.household?.id {
                            HomeSetupGuideCard(householdID: homeID) { showingSetup = true }
                        }
                    }.padding(.bottom, 24)
                }.frame(maxWidth: .infinity).accessibilityIdentifier("home.workspace.scene")
            }.padding(.horizontal, 24).padding(.top, 16)
        }.accessibilityIdentifier("home.workspace")
    }

    private func card(_ title: String, detail: String, symbol: String, color: Color) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: symbol).font(.title2).foregroundStyle(color).frame(width: 30).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(detail).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary).accessibilityHidden(true)
        }.padding(18).frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20)).contentShape(Rectangle())
    }
}
