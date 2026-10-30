import SwiftUI

struct HomeView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var addingRoom = false
    @State private var quickAdding = false
    @State private var showingSetup = false
    @State private var showingSpaces = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    HearthEditorialHeader(eyebrow: "YOUR HOME", title: repository.household?.name ?? "Your home",
                                          subtitle: "A little order. More room for living.", artwork: "WelcomeResidence")
                    if let homeID = repository.household?.id { HomeSetupGuideCard(householdID: homeID) { showingSetup = true } }
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Your kitchen").font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                        TodayAlignedCards(columns: textSize.isAccessibilitySize ? 1 : 2) {
                            NavigationLink { InventoryView() } label: {
                                HomeFoodTile(title: "Pantry", purpose: "What you have", count: "\(repository.inventory.filter { !$0.isUsedUp }.count) packs at home", art: "EditorialPantry", accent: InventoryTheme.accent, surface: AppTheme.surface)
                            }.accessibilityIdentifier("home.inventory")
                            NavigationLink { ShoppingListView() } label: {
                                HomeFoodTile(title: "Shopping", purpose: "What to buy", count: "\(repository.groceries.filter { !$0.isCompleted }.count) items to buy", art: "WelcomeTable", accent: ShoppingTheme.accent, surface: AppTheme.surface)
                            }.accessibilityIdentifier("home.shopping")
                        }
                        NavigationLink { MealIdeasView() } label: {
                            HStack(spacing: 18) {
                                Image(systemName: "fork.knife").font(.system(size: 26, weight: .light)).foregroundStyle(AppTheme.clay).accessibilityHidden(true)
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
                            Image(systemName: "checklist").font(.title).foregroundStyle(AppTheme.slate).accessibilityHidden(true)
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
                        Text("Your spaces").font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                        spacesLink.accessibilityIdentifier("home.spaces")
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 24) { roomActions }
                            VStack(alignment: .leading, spacing: 8) { roomActions }
                        }
                        if !repository.rooms.isEmpty {
                            ScrollView(.horizontal) {
                                HStack(spacing: 12) {
                                    ForEach(repository.rooms) { room in
                                        NavigationLink { RoomDetailView(room: room) } label: { Label(room.name, systemImage: "door.left.hand.open").padding(14).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16)) }.accessibilityIdentifier("home.room.\(room.id)")
                                    }
                                }
                            }.scrollIndicators(.hidden)
                        }
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Spending & home care").font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                        TodayAlignedCards(columns: textSize.isAccessibilitySize || sizeClass != .regular ? 1 : 3) {
                            NavigationLink { ExpensesView() } label: { HomeUtilityTile(title: "Expenses", detail: "Receipts & monthly spending", symbol: "chart.bar.xaxis", accent: AppTheme.plum) }.accessibilityIdentifier("home.expenses")
                            NavigationLink { PurchaseHistoryView() } label: { HomeUtilityTile(title: "Purchases", detail: "Your purchase history", symbol: "bag", accent: AppTheme.slate) }.accessibilityIdentifier("home.purchases")
                            NavigationLink { HomeAlertsView() } label: { HomeUtilityTile(title: "Home care", detail: "Maintenance & warranties", symbol: "wrench.and.screwdriver", accent: AppTheme.sage) }.accessibilityIdentifier("home.care")
                        }
                    }
                    NavigationLink { ConnectedDemoView() } label: {
                        Label("Try the connected demo", systemImage: "play.rectangle").font(.subheadline).frame(minHeight: 44)
                    }.accessibilityIdentifier("home.connectedDemo")
                }.padding(20).frame(maxWidth: 1000).frame(maxWidth: .infinity)
            }.background(AppTheme.canvas).buttonStyle(.plain).foregroundStyle(.primary)
                .householdHelp(.home)
        .navigationTitle("Home").navigationBarTitleDisplayMode(.inline)
                .navigationDestination(isPresented: $showingSetup) {
                    if let homeID = repository.household?.id { HomeSetupGuideView(householdID: homeID) }
                }
                .toolbar { Button("Quick Add", systemImage: "plus") { quickAdding = true } }
                .fullScreenCover(isPresented: $showingSpaces) { HomeSpacesView(isWorkspace: true) }
                .sheet(isPresented: $quickAdding) { QuickAddView() }
                .sheet(isPresented: $addingRoom) { QuickAddView(kind: .room, parentID: repository.floors.count == 1 ? repository.floors.first?.id : nil, fixedKind: true) }
        }
    }
    @ViewBuilder private var spacesLink: some View {
        if sizeClass == .regular {
            Button { showingSpaces = true } label: { spacesCard }
        } else {
            NavigationLink { HomeSpacesView() } label: { spacesCard }
        }
    }

    private var spacesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image("WelcomeResidence").resizable().scaledToFill().frame(height: 145).clipped().clipShape(RoundedRectangle(cornerRadius: 18)).accessibilityHidden(true)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rooms & belongings").font(.title3.bold())
                    Text("\(repository.rooms.count) rooms · \(repository.assets.count) items").font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(); Image(systemName: "chevron.right").accessibilityHidden(true)
            }
        }.padding(16).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18)).contentShape(Rectangle())
    }

    @ViewBuilder private var roomActions: some View {
        Button { addingRoom = true } label: { Label("Add a room", systemImage: "plus").frame(minHeight: 44) }.accessibilityIdentifier("home.addRoom")
        NavigationLink { HomeLayoutView() } label: { Label("2D / 3D floor plan", systemImage: "square.3.layers.3d").frame(minHeight: 44) }.accessibilityIdentifier("home.layout")
    }
}
private struct HomeFoodTile: View {
    @Environment(\.dynamicTypeSize) private var textSize
    let title: String
    let purpose: String
    let count: String
    let art: String
    let accent: Color
    let surface: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if !textSize.isAccessibilitySize {
            GeometryReader { geometry in
                Image(art).resizable().scaledToFill().frame(width: geometry.size.width, height: 110).clipped().clipShape(RoundedRectangle(cornerRadius: 16))
            }.frame(height: 110).accessibilityHidden(true)
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
            Image(systemName: symbol).font(.title2).foregroundStyle(accent).accessibilityHidden(true)
            Text(title).font(.headline)
            Text(detail).font(.subheadline).foregroundStyle(.secondary)
        }.padding(20).frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18)).hearthCardOutline(accent)
    }
}
