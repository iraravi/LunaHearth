import SwiftUI

/// Two independent, scrollable areas keep household actions beside the saved home.
struct HomeWorkspaceDashboard: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Binding var showingSetup: Bool
    @Binding var showingSpaces: Bool
    @Binding var floorID: UUID?
    @Binding var angle: Double
    @Binding var elevation: Double
    @Binding var editingRoom: Bool
    @Binding var scanning: Bool
    @Binding var initialized: Bool
    private var rooms: [Room] { repository.rooms.filter { $0.floorID == floorID } }
    private var planned: [LayoutRoom] { rooms.compactMap(\.layoutRoom) }

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
                        NavigationLink { HomeAlertsView() } label: {
                            card("Home care", detail: "Maintenance & warranties", symbol: "wrench.and.screwdriver", color: AppTheme.sage)
                        }.accessibilityIdentifier("home.care")
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
                            Text("\(repository.rooms.count) \(repository.rooms.count == 1 ? "room" : "rooms") · \(repository.assets.count) \(repository.assets.count == 1 ? "belonging" : "belongings")")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                        Picker("Floor", selection: $floorID) {
                            Text("Unassigned rooms").tag(nil as UUID?)
                            ForEach(repository.floors) { Text($0.name).tag(Optional($0.id)) }
                        }.accessibilityIdentifier("home.workspace.floor")
                        if planned.isEmpty {
                            VStack(spacing: 18) {
                                Image(systemName: "house.and.flag").font(.system(size: 64, weight: .ultraLight))
                                    .foregroundStyle(AppTheme.sage).accessibilityHidden(true)
                                Text("Make room for your home.").font(AppTheme.sectionTitle)
                                Text(rooms.isEmpty ? "Add your first room to start a layout." : "Set room dimensions in the floor plan to see them here.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }.multilineTextAlignment(.center).frame(maxWidth: .infinity, minHeight: 250)
                                .padding(20).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24))
                                .accessibilityIdentifier("home.workspace.empty")
                        } else {
                            OrbitingHomePreview(rooms: planned, angle: $angle, elevation: $elevation)
                                .frame(height: max(250, min(420, geometry.size.height * 0.48)))
                            HStack {
                                Text("Drag to rotate · \(planned.count) \(planned.count == 1 ? "room" : "rooms") in view").font(.caption).foregroundStyle(.secondary)
                                Spacer()
                                Button("Reset view", systemImage: "arrow.counterclockwise") { angle = 35; elevation = 35 }
                                    .font(.caption).frame(minHeight: 44)
                            }
                        }
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) { roomActions }
                            VStack(alignment: .leading, spacing: 12) { roomActions }
                        }
                        Button { showingSpaces = true } label: {
                            card("Rooms & belongings", detail: "Open your home workspace", symbol: "square.grid.2x2", color: AppTheme.sage)
                        }.accessibilityIdentifier("home.spaces")
                        ForEach(rooms) { room in
                            NavigationLink { RoomDetailView(room: room) } label: {
                                HStack {
                                    Image(systemName: "door.left.hand.open").foregroundStyle(AppTheme.sage)
                                    Text(room.name).font(.headline)
                                    Spacer()
                                    Image(systemName: "chevron.right").accessibilityHidden(true)
                                }.padding(16).frame(maxWidth: .infinity, minHeight: 52)
                                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                            }.accessibilityIdentifier("home.room.\(room.id)")
                        }
                        Text("Your saved room measurements. An approximate layout, not a construction or safety plan.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.padding(.bottom, 24)
                }.frame(maxWidth: .infinity).accessibilityIdentifier("home.workspace.scene")
            }.padding(.horizontal, 24).padding(.top, 16)
        }.accessibilityIdentifier("home.workspace")
            .onAppear {
                if !initialized { floorID = repository.floors.first?.id; initialized = true }
            }

    }

    @ViewBuilder private var roomActions: some View {
        Button("Add room", systemImage: "plus") { editingRoom = true }
            .buttonStyle(.borderedProminent).tint(AppTheme.ink).foregroundStyle(AppTheme.canvas)
            .controlSize(.large).accessibilityIdentifier("home.addRoom")
        NavigationLink { HomeLayoutView() } label: { Label("Floor plan", systemImage: "square.3.layers.3d") }
            .buttonStyle(.bordered).controlSize(.large).accessibilityIdentifier("home.layout")
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
